import 'package:postgres/postgres.dart';
import 'package:tonarota_shared/tonarota_shared.dart';
import '../database/database_connection.dart';

class AvaliacaoService {
  final DatabaseConnection _db = DatabaseConnection();

  Future<Avaliacao> create({
    required String estabelecimentoId,
    required int nota,
    required String comentario,
    String status = 'aprovada',
  }) async {
    final result = await _db.execute(
      Sql.named(
        'INSERT INTO avaliacao (estabelecimento_id, nota, comentario, status, created_at) '
        'VALUES (@estabelecimentoId, @nota, @comentario, @status, CURRENT_TIMESTAMP) '
        'RETURNING id, estabelecimento_id, nota, comentario, status, created_at',
      ),
      parameters: {
        'estabelecimentoId': estabelecimentoId,
        'nota': nota,
        'comentario': comentario.trim(),
        'status': status,
      },
    );

    final row = result.first;
    return _mapRowToAvaliacao(row);
  }

  Future<List<Avaliacao>> getByEstabelecimento(String estabelecimentoId) async {
    final result = await _db.execute(
      Sql.named(
        'SELECT id, estabelecimento_id, nota, comentario, status, created_at '
        'FROM avaliacao WHERE estabelecimento_id = @estabelecimentoId AND status = \'aprovada\' '
        'ORDER BY created_at DESC',
      ),
      parameters: {
        'estabelecimentoId': estabelecimentoId,
      },
    );

    return result.map((row) => _mapRowToAvaliacao(row)).toList();
  }

  Future<List<Map<String, dynamic>>> getAllForAdmin() async {
    final result = await _db.execute(
      Sql.named(
        'SELECT a.id, a.estabelecimento_id, a.nota, a.comentario, a.status, a.created_at, e.nome_fantasia '
        'FROM avaliacao a '
        'JOIN estabelecimento e ON a.estabelecimento_id = e.id '
        'ORDER BY a.created_at DESC',
      ),
    );

    return result.map((row) {
      final av = _mapRowToAvaliacao(row);
      final json = av.toJson();
      json['estabelecimento_nome'] = row[6] as String;
      return json;
    }).toList();
  }

  Future<Avaliacao?> updateStatus(String id, String status) async {
    final result = await _db.execute(
      Sql.named(
        'UPDATE avaliacao SET status = @status WHERE id = @id '
        'RETURNING id, estabelecimento_id, nota, comentario, status, created_at',
      ),
      parameters: {
        'id': id,
        'status': status,
      },
    );

    if (result.isEmpty) return null;
    return _mapRowToAvaliacao(result.first);
  }

  Avaliacao _mapRowToAvaliacao(ResultRow row) {
    return Avaliacao(
      id: row[0] as String,
      estabelecimentoId: row[1] as String,
      nota: row[2] as int,
      comentario: row[3] as String? ?? '',
      status: row[4] as String,
      createdAt: row[5] as DateTime,
    );
  }
}
