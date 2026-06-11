import 'package:bcrypt/bcrypt.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:postgres/postgres.dart';
import 'package:tonarota_shared/tonarota_shared.dart';
import '../database/database_connection.dart';
import '../middleware/auth_middleware.dart' show jwtSecret;

class AuthService {
  final DatabaseConnection _db = DatabaseConnection();

  Future<Usuario> register({
    required String email,
    required String password,
    required String nome,
    required String role,
  }) async {
    if (!['turista', 'estabelecimento', 'gestor'].contains(role)) {
      throw ArgumentError('Perfil (role) inválido.');
    }

    final emailTrimmed = email.trim().toLowerCase();
    if (emailTrimmed.isEmpty || password.isEmpty || nome.trim().isEmpty) {
      throw ArgumentError('Todos os campos obrigatórios devem ser preenchidos.');
    }

    // Verificar se e-mail já existe
    final checkResult = await _db.execute(
      Sql.named('SELECT id FROM usuario WHERE email = @email'),
      parameters: {'email': emailTrimmed},
    );

    if (checkResult.isNotEmpty) {
      throw StateError('Este e-mail já está cadastrado.');
    }

    // Criar hash da senha
    final passwordHash = BCrypt.hashpw(password, BCrypt.gensalt());

    // Inserir usuário
    final insertResult = await _db.execute(
      Sql.named(
        'INSERT INTO usuario (email, senha_hash, nome, role, ativo, created_at) '
        'VALUES (@email, @senhaHash, @nome, @role, TRUE, CURRENT_TIMESTAMP) '
        'RETURNING id, email, nome, role, ativo, created_at',
      ),
      parameters: {
        'email': emailTrimmed,
        'senhaHash': passwordHash,
        'nome': nome.trim(),
        'role': role,
      },
    );

    final row = insertResult.first;
    return Usuario(
      id: row[0] as String,
      email: row[1] as String,
      nome: row[2] as String,
      role: row[3] as String,
      ativo: row[4] as bool,
      createdAt: row[5] as DateTime,
    );
  }

  Future<Map<String, dynamic>?> login(String email, String password) async {
    final emailTrimmed = email.trim().toLowerCase();

    final result = await _db.execute(
      Sql.named('SELECT id, email, senha_hash, nome, role, ativo, created_at FROM usuario WHERE email = @email'),
      parameters: {'email': emailTrimmed},
    );

    if (result.isEmpty) return null;

    final row = result.first;
    final id = row[0] as String;
    final dbEmail = row[1] as String;
    final hash = row[2] as String;
    final nome = row[3] as String;
    final role = row[4] as String;
    final ativo = row[5] as bool;
    final createdAt = row[6] as DateTime;

    if (!ativo) {
      throw StateError('Esta conta de usuário está desativada.');
    }

    // Verificar senha
    if (!BCrypt.checkpw(password, hash)) {
      return null;
    }

    final user = Usuario(
      id: id,
      email: dbEmail,
      nome: nome,
      role: role,
      ativo: ativo,
      createdAt: createdAt,
    );

    // Gerar token JWT (expira em 24h para estabelecimento/turista, 8h para gestor)
    final expirationHours = (role == 'gestor') ? 8 : 24;
    final jwt = JWT(
      {
        'id': user.id,
        'email': user.email,
        'role': user.role,
      },
      issuer: 'tonarota-backend',
    );

    final token = jwt.sign(
      SecretKey(jwtSecret),
      expiresIn: Duration(hours: expirationHours),
    );

    return {
      'token': token,
      'user': user.toJson(),
    };
  }

  Future<Usuario?> getUserById(String id) async {
    final result = await _db.execute(
      Sql.named('SELECT id, email, nome, role, ativo, created_at FROM usuario WHERE id = @id'),
      parameters: {'id': id},
    );

    if (result.isEmpty) return null;

    final row = result.first;
    return Usuario(
      id: row[0] as String,
      email: row[1] as String,
      nome: row[2] as String,
      role: row[3] as String,
      ativo: row[4] as bool,
      createdAt: row[5] as DateTime,
    );
  }
}
