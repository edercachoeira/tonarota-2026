import 'package:postgres/postgres.dart';
import 'package:tonarota_shared/tonarota_shared.dart';
import '../database/database_connection.dart';

class BalnearioService {
  final DatabaseConnection _db = DatabaseConnection();

  Future<Balneario> create({
    required String nome,
    required String municipio,
    required String estado,
    String descricao = '',
    String imagemCapaUrl = '',
  }) async {
    final result = await _db.execute(
      Sql.named(
        'INSERT INTO balneario (nome, municipio, estado, descricao, imagem_capa_url, ativo, created_at, updated_at) '
        'VALUES (@nome, @municipio, @estado, @descricao, @imagemCapaUrl, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP) '
        'RETURNING id, nome, municipio, estado, descricao, imagem_capa_url, ativo, created_at, updated_at',
      ),
      parameters: {
        'nome': nome.trim(),
        'municipio': municipio.trim(),
        'estado': estado.trim().toUpperCase(),
        'descricao': descricao.trim(),
        'imagemCapaUrl': imagemCapaUrl.trim(),
      },
    );

    final row = result.first;
    return Balneario(
      id: row[0] as String,
      nome: row[1] as String,
      municipio: row[2] as String,
      estado: row[3] as String,
      descricao: row[4] as String,
      imagemCapaUrl: row[5] as String,
      ativo: row[6] as bool,
      createdAt: row[7] as DateTime,
      updatedAt: row[8] as DateTime,
    );
  }

  Future<List<Balneario>> getAll({bool apenasAtivos = false}) async {
    final query = apenasAtivos 
        ? 'SELECT id, nome, municipio, estado, descricao, imagem_capa_url, ativo, created_at, updated_at FROM balneario WHERE ativo = TRUE ORDER BY nome ASC'
        : 'SELECT id, nome, municipio, estado, descricao, imagem_capa_url, ativo, created_at, updated_at FROM balneario ORDER BY nome ASC';

    final result = await _db.execute(Sql.raw(query));
    
    return result.map((row) => Balneario(
      id: row[0] as String,
      nome: row[1] as String,
      municipio: row[2] as String,
      estado: row[3] as String,
      descricao: row[4] as String,
      imagemCapaUrl: row[5] as String,
      ativo: row[6] as bool,
      createdAt: row[7] as DateTime,
      updatedAt: row[8] as DateTime,
    )).toList();
  }

  Future<Balneario?> getById(String id) async {
    final result = await _db.execute(
      Sql.named(
        'SELECT id, nome, municipio, estado, descricao, imagem_capa_url, ativo, created_at, updated_at '
        'FROM balneario WHERE id = @id',
      ),
      parameters: {'id': id},
    );

    if (result.isEmpty) return null;

    final row = result.first;
    return Balneario(
      id: row[0] as String,
      nome: row[1] as String,
      municipio: row[2] as String,
      estado: row[3] as String,
      descricao: row[4] as String,
      imagemCapaUrl: row[5] as String,
      ativo: row[6] as bool,
      createdAt: row[7] as DateTime,
      updatedAt: row[8] as DateTime,
    );
  }

  Future<Balneario?> update(
    String id, {
    required String nome,
    required String municipio,
    required String estado,
    required String descricao,
    required String imagemCapaUrl,
    required bool ativo,
  }) async {
    final result = await _db.execute(
      Sql.named(
        'UPDATE balneario '
        'SET nome = @nome, municipio = @municipio, estado = @estado, descricao = @descricao, '
        '    imagem_capa_url = @imagemCapaUrl, ativo = @ativo, updated_at = CURRENT_TIMESTAMP '
        'WHERE id = @id '
        'RETURNING id, nome, municipio, estado, descricao, imagem_capa_url, ativo, created_at, updated_at',
      ),
      parameters: {
        'id': id,
        'nome': nome.trim(),
        'municipio': municipio.trim(),
        'estado': estado.trim().toUpperCase(),
        'descricao': descricao.trim(),
        'imagemCapaUrl': imagemCapaUrl.trim(),
        'ativo': ativo,
      },
    );

    if (result.isEmpty) return null;

    final row = result.first;
    return Balneario(
      id: row[0] as String,
      nome: row[1] as String,
      municipio: row[2] as String,
      estado: row[3] as String,
      descricao: row[4] as String,
      imagemCapaUrl: row[5] as String,
      ativo: row[6] as bool,
      createdAt: row[7] as DateTime,
      updatedAt: row[8] as DateTime,
    );
  }

  Future<bool> delete(String id) async {
    final result = await _db.execute(
      Sql.named('DELETE FROM balneario WHERE id = @id'),
      parameters: {'id': id},
    );
    return result.affectedRows > 0;
  }
}
