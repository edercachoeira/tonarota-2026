import 'dart:io';
import 'package:postgres/postgres.dart';

void main() async {
  final dbHost = Platform.environment['DB_HOST'] ?? 'localhost';
  final dbPortStr = Platform.environment['DB_PORT'] ?? '5432';
  final dbPort = int.tryParse(dbPortStr) ?? 5432;
  final dbName = Platform.environment['DB_NAME'] ?? 'tonarota_dev';
  final dbUser = Platform.environment['DB_USER'] ?? 'tonarota_app';
  final dbPassword = Platform.environment['DB_PASSWORD'] ?? 'tonarota_app';

  print('Lendo arquivo schema.sql...');
  final schemaFile = File('lib/database/schema.sql');
  if (!schemaFile.existsSync()) {
    print('Erro: Arquivo lib/database/schema.sql não encontrado.');
    return;
  }
  final sqlContent = await schemaFile.readAsString();

  print('Conectando ao banco de dados $dbName em $dbHost:$dbPort...');
  try {
    final conn = await Connection.open(
      Endpoint(
        host: dbHost,
        port: dbPort,
        database: dbName,
        username: dbUser,
        password: dbPassword,
      ),
      settings: const ConnectionSettings(
        sslMode: SslMode.disable,
      ),
    );

    print('Executando DDL de migração statement por statement...');
    
    // Divide os comandos por ponto e vírgula e remove blocos vazios
    final statements = sqlContent
        .split(';')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    for (var i = 0; i < statements.length; i++) {
      final stmt = statements[i];
      // Ignora comentários no início do statement se houver
      if (stmt.startsWith('--') && !stmt.contains('\n')) continue;
      
      try {
        await conn.execute(Sql(stmt));
      } catch (e) {
        print('Erro no statement ${i + 1}: "$stmt"');
        print('Mensagem de erro: $e');
        rethrow;
      }
    }
    
    print('Sucesso! Todas as tabelas e índices foram criados com sucesso.');
    await conn.close();
  } catch (e) {
    print('Falha geral na migração.');
  }
}
