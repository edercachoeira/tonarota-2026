import 'package:bcrypt/bcrypt.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:postgres/postgres.dart';
import 'package:tonarota_shared/tonarota_shared.dart';
import '../database/database_connection.dart';
import '../middleware/auth_middleware.dart' show jwtSecret;
import 'email_service.dart';

class AuthService {
  final DatabaseConnection _db = DatabaseConnection();
  final EmailService _emailService = EmailService();

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

    // Se for gestor, já inicia ativo. Se for turista/estabelecimento, precisa de ativação por e-mail
    final initiallyActive = role == 'gestor';

    // Inserir usuário
    final insertResult = await _db.execute(
      Sql.named(
        'INSERT INTO usuario (email, senha_hash, nome, role, ativo, created_at) '
        'VALUES (@email, @senhaHash, @nome, @role, @ativo, CURRENT_TIMESTAMP) '
        'RETURNING id, email, nome, role, ativo, created_at',
      ),
      parameters: {
        'email': emailTrimmed,
        'senhaHash': passwordHash,
        'nome': nome.trim(),
        'role': role,
        'ativo': initiallyActive,
      },
    );

    final row = insertResult.first;
    final user = Usuario(
      id: row[0] as String,
      email: row[1] as String,
      nome: row[2] as String,
      role: row[3] as String,
      ativo: row[4] as bool,
      createdAt: row[5] as DateTime,
    );

    // Se necessita ativação, gera token e envia e-mail
    if (!initiallyActive) {
      final tokenResult = await _db.execute(
        Sql.named(
          'INSERT INTO token_confirmacao (usuario_id, token, expira_em) '
          'VALUES (@usuarioId, uuid_generate_v4()::text, CURRENT_TIMESTAMP + INTERVAL \'24 hours\') '
          'RETURNING token',
        ),
        parameters: {'usuarioId': user.id},
      );
      final token = tokenResult.first[0] as String;
      await _emailService.sendConfirmationEmail(user.email, user.nome, token);
    }

    return user;
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

  Future<bool> confirmarEmail(String token) async {
    final tokenResult = await _db.execute(
      Sql.named(
        'SELECT usuario_id FROM token_confirmacao '
        'WHERE token = @token AND expira_em > CURRENT_TIMESTAMP',
      ),
      parameters: {'token': token},
    );

    if (tokenResult.isEmpty) return false;

    final userId = tokenResult.first[0] as String;

    // Ativa o usuário
    await _db.execute(
      Sql.named('UPDATE usuario SET ativo = TRUE WHERE id = @id'),
      parameters: {'id': userId},
    );

    // Remove os tokens de confirmação deste usuário
    await _db.execute(
      Sql.named('DELETE FROM token_confirmacao WHERE usuario_id = @userId'),
      parameters: {'userId': userId},
    );

    return true;
  }

  Future<bool> solicitarRecuperacao(String email) async {
    final emailTrimmed = email.trim().toLowerCase();
    final userResult = await _db.execute(
      Sql.named('SELECT id, nome, email FROM usuario WHERE email = @email'),
      parameters: {'email': emailTrimmed},
    );

    if (userResult.isEmpty) return false;

    final row = userResult.first;
    final userId = row[0] as String;
    final nome = row[1] as String;

    // Remove tokens de recuperação antigos
    await _db.execute(
      Sql.named('DELETE FROM token_recuperacao WHERE usuario_id = @userId'),
      parameters: {'userId': userId},
    );

    // Gera um novo token seguro via PostgreSQL
    final tokenResult = await _db.execute(
      Sql.named(
        'INSERT INTO token_recuperacao (usuario_id, token, expira_em) '
        'VALUES (@userId, uuid_generate_v4()::text, CURRENT_TIMESTAMP + INTERVAL \'1 hour\') '
        'RETURNING token',
      ),
      parameters: {'userId': userId},
    );

    final token = tokenResult.first[0] as String;
    await _emailService.sendPasswordRecoveryEmail(emailTrimmed, nome, token);

    return true;
  }

  Future<bool> redefinirSenha(String token, String novaSenha) async {
    final tokenResult = await _db.execute(
      Sql.named(
        'SELECT usuario_id FROM token_recuperacao '
        'WHERE token = @token AND expira_em > CURRENT_TIMESTAMP',
      ),
      parameters: {'token': token},
    );

    if (tokenResult.isEmpty) return false;

    final userId = tokenResult.first[0] as String;
    final newHash = BCrypt.hashpw(novaSenha, BCrypt.gensalt());

    // Atualiza a senha
    await _db.execute(
      Sql.named('UPDATE usuario SET senha_hash = @hash WHERE id = @id'),
      parameters: {'id': userId, 'hash': newHash},
    );

    // Limpa tokens
    await _db.execute(
      Sql.named('DELETE FROM token_recuperacao WHERE usuario_id = @userId'),
      parameters: {'userId': userId},
    );

    return true;
  }

  Future<List<Usuario>> getGestores() async {
    final result = await _db.execute(
      Sql.named("SELECT id, email, nome, role, ativo, created_at FROM usuario WHERE role = 'gestor' ORDER BY nome ASC"),
    );

    return result.map((row) {
      return Usuario(
        id: row[0] as String,
        email: row[1] as String,
        nome: row[2] as String,
        role: row[3] as String,
        ativo: row[4] as bool,
        createdAt: row[5] as DateTime,
      );
    }).toList();
  }

  Future<bool> deleteUser(String id) async {
    final result = await _db.execute(
      Sql.named('DELETE FROM usuario WHERE id = @id'),
      parameters: {'id': id},
    );
    return result.affectedRows > 0;
  }

  Future<Usuario?> updateProfile(
    String id,
    String nome,
    String email, {
    String? oldPassword,
    String? newPassword,
  }) async {
    final userResult = await _db.execute(
      Sql.named('SELECT id, email, senha_hash, nome, role, ativo, created_at FROM usuario WHERE id = @id'),
      parameters: {'id': id},
    );

    if (userResult.isEmpty) return null;
    final row = userResult.first;
    final hash = row[2] as String;

    String? updatedHash;

    // Se deseja alterar senha, valida a senha atual primeiro
    if (newPassword != null && newPassword.isNotEmpty) {
      if (oldPassword == null || oldPassword.isEmpty || !BCrypt.checkpw(oldPassword, hash)) {
        throw StateError('A senha atual fornecida está incorreta.');
      }
      updatedHash = BCrypt.hashpw(newPassword, BCrypt.gensalt());
    }

    if (updatedHash != null) {
      final updateResult = await _db.execute(
        Sql.named(
          'UPDATE usuario SET nome = @nome, email = @email, senha_hash = @senhaHash '
          'WHERE id = @id '
          'RETURNING id, email, nome, role, ativo, created_at',
        ),
        parameters: {
          'id': id,
          'nome': nome.trim(),
          'email': email.trim().toLowerCase(),
          'senhaHash': updatedHash,
        },
      );
      final r = updateResult.first;
      return Usuario(
        id: r[0] as String,
        email: r[1] as String,
        nome: r[2] as String,
        role: r[3] as String,
        ativo: r[4] as bool,
        createdAt: r[5] as DateTime,
      );
    } else {
      final updateResult = await _db.execute(
        Sql.named(
          'UPDATE usuario SET nome = @nome, email = @email '
          'WHERE id = @id '
          'RETURNING id, email, nome, role, ativo, created_at',
        ),
        parameters: {
          'id': id,
          'nome': nome.trim(),
          'email': email.trim().toLowerCase(),
        },
      );
      final r = updateResult.first;
      return Usuario(
        id: r[0] as String,
        email: r[1] as String,
        nome: r[2] as String,
        role: r[3] as String,
        ativo: r[4] as bool,
        createdAt: r[5] as DateTime,
      );
    }
  }
}
