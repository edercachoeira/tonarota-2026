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

  // Pipeline de Handlers com Middlewares globais
  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(_corsMiddleware())
      .addMiddleware(rateLimitMiddleware()) // Limita acessos por IP
      .addMiddleware(authMiddleware())       // Processa e valida JWT se presente
      .addHandler(router.call);

  final server = await io.serve(handler, InternetAddress.anyIPv4, port);
  print('Servidor rodando em http://${server.address.host}:${server.port}');
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
