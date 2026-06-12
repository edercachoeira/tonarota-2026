import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:dotenv/dotenv.dart';

import '../lib/database/database_connection.dart';
import '../lib/middleware/auth_middleware.dart';
import '../lib/middleware/rate_limit_middleware.dart';
import '../lib/routes/auth_routes.dart';
import '../lib/routes/balneario_routes.dart';
import '../lib/routes/categoria_routes.dart';
import '../lib/routes/estabelecimento_routes.dart';
import '../lib/routes/auditoria_routes.dart';
import '../lib/routes/produto_routes.dart';
import '../lib/routes/metrica_routes.dart';
import '../lib/routes/avaliacao_routes.dart';

void main(List<String> args) async {
  // Carrega variáveis de ambiente se o arquivo .env existir
  final env = DotEnv()..load();

  // Porta do servidor
  final portStr = Platform.environment['PORT'] ?? env['PORT'] ?? '8080';
  final port = int.tryParse(portStr) ?? 8080;

  print('Iniciando servidor Tô Na Rota...');

  // Inicializa a conexão com o Banco de Dados PostgreSQL
  final dbConnection = DatabaseConnection();
  bool dbConnected = false;
  try {
    await dbConnection.initialize();
    dbConnected = true;
  } catch (e) {
    print('AVISO: Não foi possível conectar ao banco de dados: $e');
    print('O servidor continuará rodando em modo degradado.');
  }

  final router = Router();

  // Endpoint de saúde
  router.get('/api/health', (Request request) {
    return Response.ok(
      '{"status": "ok", "database": "${dbConnected ? "connected" : "disconnected"}"}',
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  });

  // Endpoint de Upload de Imagens (envio de bytes brutos em POST)
  router.post('/api/v1/upload', (Request request) async {
    try {
      final contentType = request.headers['content-type'] ?? 'image/jpeg';
      String ext = '.jpg';
      if (contentType.contains('png')) ext = '.png';
      if (contentType.contains('webp')) ext = '.webp';

      final List<int> bytes = [];
      await for (final chunk in request.read()) {
        bytes.addAll(chunk);
      }

      if (bytes.isEmpty) {
        return Response(HttpStatus.badRequest, body: '{"error": "Nenhum dado enviado"}', headers: {'content-type': 'application/json'});
      }

      // Garante que o diretório de uploads existe
      final uploadDir = Directory('uploads');
      if (!uploadDir.existsSync()) {
        uploadDir.createSync(recursive: true);
      }

      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${bytes.hashCode}$ext';
      final file = File('uploads/$fileName');
      await file.writeAsBytes(bytes);

      print('Upload realizado com sucesso: uploads/$fileName (${bytes.length} bytes)');

      // Retorna a URL de acesso público
      return Response.ok(
        '{"url": "http://localhost:8080/uploads/$fileName"}',
        headers: {
          'content-type': 'application/json; charset=utf-8',
          'Access-Control-Allow-Origin': '*',
        },
      );
    } catch (e) {
      return Response(HttpStatus.internalServerError, body: '{"error": "${e.toString()}"}', headers: {'content-type': 'application/json'});
    }
  });

  // Servir arquivos estáticos de uploads
  router.get('/uploads/<filename>', (Request request, String filename) async {
    try {
      final file = File('uploads/$filename');
      if (!file.existsSync()) {
        return Response.notFound('Arquivo não encontrado');
      }

      String contentType = 'application/octet-stream';
      if (filename.endsWith('.png')) contentType = 'image/png';
      if (filename.endsWith('.jpg') || filename.endsWith('.jpeg')) contentType = 'image/jpeg';
      if (filename.endsWith('.webp')) contentType = 'image/webp';

      return Response.ok(
        file.openRead(),
        headers: {
          'content-type': contentType,
          'cache-control': 'public, max-age=31536000',
          'Access-Control-Allow-Origin': '*',
        },
      );
    } catch (e) {
      return Response.internalServerError(body: e.toString());
    }
  });

  // Montagem das rotas da API
  router.mount('/api/v1/auth', AuthRoutes().router.call);
  router.mount('/api/v1/balnearios', BalnearioRoutes().router.call);
  router.mount('/api/v1/categorias', CategoriaRoutes().router.call);
  router.mount('/api/v1/estabelecimentos', EstabelecimentoRoutes().router.call);
  router.mount('/api/v1/auditoria', AuditoriaRoutes().router.call);
  router.mount('/api/v1/produtos', ProdutoRoutes().router.call);
  router.mount('/api/v1/metricas', MetricaRoutes().router.call);
  router.mount('/api/v1/avaliacoes', AvaliacaoRoutes().router.call);

  // ─── STATIC FILE SERVING ───────────────────────────────────────
  // Obtém o diretório do executável ou script em execução
  final serverBinDir = File(Platform.script.toFilePath()).parent.path;
  
  // Vamos resolver o projectRoot a partir do diretório onde o executável ou script está.
  // Se estivermos rodando no script (server/bin/server.dart) ou no executável (server/bin/server.exe),
  // a raiz do projeto é a pasta pai de 'server' (duas pastas acima de serverBinDir).
  // Se por acaso o executável for movido para a raiz no futuro, fazemos um fallback seguro.
  String resolvedProjectRoot = Directory(serverBinDir).parent.parent.path;
  
  // Caso de fallback: se a raiz resolvida não contiver a pasta 'server', 
  // pode ser que estejamos rodando de outro lugar. Garantimos a consistência:
  if (!Directory('$resolvedProjectRoot/server').existsSync()) {
    resolvedProjectRoot = Directory(serverBinDir).parent.path;
  }
  if (!Directory('$resolvedProjectRoot/server').existsSync()) {
    resolvedProjectRoot = Directory.current.path; // último fallback
  }

  print('Diretório do executável/script: $serverBinDir');
  print('Diretório raiz do projeto resolvido: $resolvedProjectRoot');

  // Serve o favicon na raiz
  router.get('/favicon.png', (Request request) async {
    return _serveStaticFile('$resolvedProjectRoot/server/public/favicon.png', request);
  });

  // Serve arquivos estáticos da Landing Page (public/)
  router.get('/style.css', (Request request) => _serveStaticFile('$resolvedProjectRoot/server/public/style.css', request));
  router.get('/app.js', (Request request) => _serveStaticFile('$resolvedProjectRoot/server/public/app.js', request));

  // Serve o Flutter Web build em /app/
  router.get('/app/<path|.*>', (Request request, String path) async {
    // Se a rota for vazia ou for uma sub-rota do Flutter (SPA), servimos o index.html.
    // Para identificar se é um arquivo real (com extensão) ou uma rota de tela do Flutter:
    final cleanPath = path.isEmpty ? 'index.html' : path;
    
    // Caminho físico no build do Flutter Web
    final filePath = '$resolvedProjectRoot/build/web/$cleanPath';
    final file = File(filePath);

    if (file.existsSync()) {
      return _serveStaticFile(filePath, request);
    }

    // SPA fallback: se for uma rota virtual do Flutter (sem arquivo correspondente), serve o index.html
    return _serveStaticFile('$resolvedProjectRoot/build/web/index.html', request);
  });

  // Landing page: serve a rota raiz
  router.get('/', (Request request) => _serveStaticFile('$resolvedProjectRoot/server/public/index.html', request));

  // Pipeline de Handlers com Middlewares globais
  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(_corsMiddleware())
      .addMiddleware(rateLimitMiddleware()) // Limita acessos por IP
      .addMiddleware(authMiddleware())       // Processa e valida JWT se presente
      .addHandler(router.call);

  final server = await io.serve(handler, InternetAddress.anyIPv4, port);
  print('Servidor rodando em http://${server.address.host}:${server.port}');
  print('  Landing Page: http://localhost:$port/');
  print('  Flutter App:  http://localhost:$port/app/');
  print('  API:          http://localhost:$port/api/v1/');
}

/// Serve um arquivo estático com Content-Type correto e cache headers
Future<Response> _serveStaticFile(String filePath, Request request) async {
  final file = File(filePath);
  if (!file.existsSync()) {
    print('Aviso: Arquivo estático não encontrado: $filePath');
    return Response.notFound('Arquivo não encontrado');
  }

  final ext = filePath.split('.').last.toLowerCase();
  final contentType = _mimeType(ext);

  // Cache longo para assets imutáveis, curto para HTML
  final cacheControl = (ext == 'html')
      ? 'no-cache'
      : 'public, max-age=31536000, immutable';

  return Response.ok(
    file.openRead(),
    headers: {
      'content-type': contentType,
      'cache-control': cacheControl,
      'Access-Control-Allow-Origin': '*',
    },
  );
}

/// Retorna o MIME type correto para extensões de arquivos web
String _mimeType(String ext) {
  switch (ext) {
    case 'html': return 'text/html; charset=utf-8';
    case 'css': return 'text/css; charset=utf-8';
    case 'js': return 'application/javascript; charset=utf-8';
    case 'mjs': return 'application/javascript; charset=utf-8';
    case 'json': return 'application/json; charset=utf-8';
    case 'png': return 'image/png';
    case 'jpg': case 'jpeg': return 'image/jpeg';
    case 'gif': return 'image/gif';
    case 'svg': return 'image/svg+xml';
    case 'webp': return 'image/webp';
    case 'ico': return 'image/x-icon';
    case 'wasm': return 'application/wasm';
    case 'woff': return 'font/woff';
    case 'woff2': return 'font/woff2';
    case 'ttf': return 'font/ttf';
    case 'otf': return 'font/otf';
    case 'map': return 'application/json';
    default: return 'application/octet-stream';
  }
}

/// Middleware CORS flexível para desenvolvimento e produção
Middleware _corsMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers': 'Origin, Content-Type, Authorization',
        });
      }

      final response = await innerHandler(request);

      return response.change(headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Origin, Content-Type, Authorization',
      });
    };
  };
}
