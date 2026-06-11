import 'package:postgres/postgres.dart';
import 'package:tonarota_shared/tonarota_shared.dart';
import '../database/database_connection.dart';

class CategoriaService {
  final DatabaseConnection _db = DatabaseConnection();

  Future<Categoria> create({
    required String nome,
    String icone = '',
    String descricao = '',
    int ordem = 0,
    String? parentId,
  }) async {
    final result = await _db.execute(
      Sql.named(
        'INSERT INTO categoria (nome, icone, descricao, ordem, parent_id, ativo) '
        'VALUES (@nome, @icone, @descricao, @ordem, @parentId, TRUE) '
        'RETURNING id, nome, icone, descricao, ordem, parent_id, ativo',
      ),
      parameters: {
        'nome': nome.trim(),
        'icone': icone.trim(),
        'descricao': descricao.trim(),
        'ordem': ordem,
        'parentId': parentId,
      },
    );

    final row = result.first;
    return Categoria(
      id: row[0] as String,
      nome: row[1] as String,
      icone: row[2] as String,
      descricao: row[3] as String,
      ordem: row[4] as int,
      parentId: row[5] as String?,
      ativo: row[6] as bool,
    );
  }

  Future<List<Categoria>> getAll({bool apenasAtivos = false}) async {
    final query = apenasAtivos 
        ? 'SELECT id, nome, icone, descricao, ordem, parent_id, ativo FROM categoria WHERE ativo = TRUE ORDER BY ordem ASC, nome ASC'
        : 'SELECT id, nome, icone, descricao, ordem, parent_id, ativo FROM categoria ORDER BY ordem ASC, nome ASC';

    final result = await _db.execute(Sql(query));
    
    return result.map((row) => Categoria(
      id: row[0] as String,
      nome: row[1] as String,
      icone: row[2] as String,
      descricao: row[3] as String,
      ordem: row[4] as int,
      parentId: row[5] as String?,
      ativo: row[6] as bool,
    )).toList();
  }

  Future<Categoria?> getById(String id) async {
    final result = await _db.execute(
      Sql.named(
        'SELECT id, nome, icone, descricao, ordem, parent_id, ativo '
        'FROM categoria WHERE id = @id',
      ),
      parameters: {'id': id},
    );

    if (result.isEmpty) return null;

    final row = result.first;
    return Categoria(
      id: row[0] as String,
      nome: row[1] as String,
      icone: row[2] as String,
      descricao: row[3] as String,
      ordem: row[4] as int,
      parentId: row[5] as String?,
      ativo: row[6] as bool,
    );
  }

  Future<Categoria?> update(
    String id, {
    required String nome,
    required String icone,
    required String descricao,
    required int ordem,
    String? parentId,
    required bool ativo,
  }) async {
    final result = await _db.execute(
      Sql.named(
        'UPDATE categoria '
        'SET nome = @nome, icone = @icone, descricao = @descricao, ordem = @ordem, '
        '    parent_id = @parentId, ativo = @ativo '
        'WHERE id = @id '
        'RETURNING id, nome, icone, descricao, ordem, parent_id, ativo',
      ),
      parameters: {
        'id': id,
        'nome': nome.trim(),
        'icone': icone.trim(),
        'descricao': descricao.trim(),
        'ordem': ordem,
        'parentId': parentId,
        'ativo': ativo,
      },
    );

    if (result.isEmpty) return null;

    final row = result.first;
    return Categoria(
      id: row[0] as String,
      nome: row[1] as String,
      icone: row[2] as String,
      descricao: row[3] as String,
      ordem: row[4] as int,
      parentId: row[5] as String?,
      ativo: row[6] as bool,
    );
  }

  Future<bool> delete(String id) async {
    final result = await _db.execute(
      Sql.named('DELETE FROM categoria WHERE id = @id'),
      parameters: {'id': id},
    );
    return result.affectedRows > 0;
  }
}
