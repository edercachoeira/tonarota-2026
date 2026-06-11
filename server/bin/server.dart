import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:postgres/postgres.dart';
import 'package:tonarota_shared/tonarota_shared.dart';

void main(List<String> args) async {
  // Use a porta definida na variável de ambiente PORT ou 8080 como padrão
  final portStr = Platform.environment['PORT'] ?? '8080';
  final port = int.tryParse(portStr) ?? 8080;

  // Obter as variáveis de conexão com o banco
  final dbHost = Platform.environment['DB_HOST'] ?? 'localhost';
  final dbPortStr = Platform.environment['DB_PORT'] ?? '5432';
  final dbPort = int.tryParse(dbPortStr) ?? 5432;
  final dbName = Platform.environment['DB_NAME'] ?? 'tonarota_dev';
  final dbUser = Platform.environment['DB_USER'] ?? 'tonarota_app';
  final dbPassword = Platform.environment['DB_PASSWORD'] ?? 'tonarota_app';

  print('Iniciando servidor Tô Na Rota...');
  print('Configuração do Banco de Dados: Host: $dbHost, Banco: $dbName, Usuário: $dbUser');

  // Inicializar o pool ou conexão com o PostgreSQL
  late final Connection conn;
  bool dbConnected = false;
  try {
    conn = await Connection.open(
      Endpoint(
        host: dbHost,
        port: dbPort,
        database: dbName,
        username: dbUser,
        password: dbPassword,
      ),
      settings: const ConnectionSettings(
        sslMode: SslMode.disable, // Local dev sem SSL
      ),
    );
    dbConnected = true;
    print('Conectado ao PostgreSQL com sucesso!');
  } catch (e) {
    print('AVISO: Não foi possível conectar ao banco de dados: $e');
    print('O servidor continuará rodando, mas chamadas de banco podem falhar.');
  }

  final router = Router();

  // Endpoint de Saúde do Servidor
  router.get('/api/health', (Request request) {
    return Response.ok(
      '{"status": "ok", "database": "${dbConnected ? "connected" : "disconnected"}"}',
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  });

  // Exemplo de endpoint mock usando o modelo Usuario compartilhado
  router.get('/api/v1/user-profile', (Request request) {
    final mockUser = Usuario(
      id: '00000000-0000-0000-0000-000000000000',
      email: 'gestor@tonarota.com.br',
      nome: 'Administrador Local',
      role: 'gestor',
      ativo: true,
      createdAt: DateTime.now(),
    );

    return Response.ok(
      '{"status": "success", "data": ${mockUser.toJson()}}',
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  });

  // Pipeline com Logger e CORS Headers
  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(_corsMiddleware())
      .addHandler(router.call);

  final server = await io.serve(handler, InternetAddress.anyIPv4, port);
  print('Servidor rodando em http://${server.address.host}:${server.port}');
}

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
