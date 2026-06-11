import 'dart:io';
import 'package:postgres/postgres.dart';

class DatabaseConnection {
  static final DatabaseConnection _instance = DatabaseConnection._internal();
  Connection? _connection;

  factory DatabaseConnection() {
    return _instance;
  }

  DatabaseConnection._internal();

  Connection get connection {
    if (_connection == null) {
      throw StateError('Banco de dados não foi inicializado. Chame initialize() primeiro.');
    }
    return _connection!;
  }

  Future<void> initialize() async {
    if (_connection != null) return;

    final dbHost = Platform.environment['DB_HOST'] ?? 'localhost';
    final dbPortStr = Platform.environment['DB_PORT'] ?? '5432';
    final dbPort = int.tryParse(dbPortStr) ?? 5432;
    final dbName = Platform.environment['DB_NAME'] ?? 'tonarota_dev';
    final dbUser = Platform.environment['DB_USER'] ?? 'tonarota_app';
    final dbPassword = Platform.environment['DB_PASSWORD'] ?? 'tonarota_app';

    try {
      _connection = await Connection.open(
        Endpoint(
          host: dbHost,
          port: dbPort,
          database: dbName,
          username: dbUser,
          password: dbPassword,
        ),
        settings: const ConnectionSettings(
          sslMode: SslMode.disable, // Local dev sem SSL. Em prod pode ser alterado conforme env.
        ),
      );
      print('Conectado ao PostgreSQL com sucesso!');
    } catch (e) {
      print('Erro ao conectar ao PostgreSQL: $e');
      rethrow;
    }
  }

  Future<Result> execute(Sql sql, {Map<String, dynamic>? parameters}) async {
    try {
      return await connection.execute(sql, parameters: parameters);
    } catch (e) {
      print('Erro na query: $e');
      rethrow;
    }
  }

  Future<void> close() async {
    await _connection?.close();
    _connection = null;
  }
}
