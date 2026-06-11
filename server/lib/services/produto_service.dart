import 'package:postgres/postgres.dart';
import 'package:tonarota_shared/tonarota_shared.dart';
import '../database/database_connection.dart';

class ProdutoService {
  final DatabaseConnection _db = DatabaseConnection();

  Future<Produto> create({
    required String estabelecimentoId,
    required String titulo,
    required String descricao,
    required double preco,
    required String fotoUrl,
    int ordem = 0,
    bool ativo = true,
  }) async {
    // Validar limite de 30 itens se necessário (verificado no route, mas aqui garante)
    final count = await getProductCount(estabelecimentoId);
    if (count >= 30) {
      throw Exception('Limite de 30 produtos por estabelecimento atingido.');
    }

    final result = await _db.execute(
      Sql.named(
        'INSERT INTO produto (estabelecimento_id, titulo, descricao, preco, foto_url, ordem, ativo) '
        'VALUES (@estabelecimentoId, @titulo, @descricao, @preco, @fotoUrl, @ordem, @ativo) '
        'RETURNING id, estabelecimento_id, titulo, descricao, preco, foto_url, ordem, ativo',
      ),
      parameters: {
        'estabelecimentoId': estabelecimentoId,
        'titulo': titulo.trim(),
        'descricao': descricao.trim(),
        'preco': preco,
        'fotoUrl': fotoUrl.trim(),
        'ordem': ordem,
        'ativo': ativo,
      },
    );

    final row = result.first;
    return _mapRowToProduto(row);
  }

  Future<int> getProductCount(String estabelecimentoId) async {
    final result = await _db.execute(
      Sql.named('SELECT COUNT(*) FROM produto WHERE estabelecimento_id = @estabelecimentoId'),
      parameters: {'estabelecimentoId': estabelecimentoId},
    );
    if (result.isEmpty) return 0;
    return result.first[0] as int;
  }

  Future<List<Produto>> getAllByEstabelecimentoId(String estabelecimentoId) async {
    final result = await _db.execute(
      Sql.named(
        'SELECT id, estabelecimento_id, titulo, descricao, preco, foto_url, ordem, ativo '
        'FROM produto WHERE estabelecimento_id = @estabelecimentoId ORDER BY ordem ASC, titulo ASC',
      ),
      parameters: {'estabelecimentoId': estabelecimentoId},
    );
    return result.map((row) => _mapRowToProduto(row)).toList();
  }

  Future<Produto?> getById(String id) async {
    final result = await _db.execute(
      Sql.named(
        'SELECT id, estabelecimento_id, titulo, descricao, preco, foto_url, ordem, ativo '
        'FROM produto WHERE id = @id',
      ),
      parameters: {'id': id},
    );

    if (result.isEmpty) return null;
    return _mapRowToProduto(result.first);
  }

  Future<Produto?> update(
    String id, {
    required String titulo,
    required String descricao,
    required double preco,
    required String fotoUrl,
    required int ordem,
    required bool ativo,
  }) async {
    final result = await _db.execute(
      Sql.named(
        'UPDATE produto '
        'SET titulo = @titulo, descricao = @descricao, preco = @preco, '
        '    foto_url = @fotoUrl, ordem = @ordem, ativo = @ativo '
        'WHERE id = @id '
        'RETURNING id, estabelecimento_id, titulo, descricao, preco, foto_url, ordem, ativo',
      ),
      parameters: {
        'id': id,
        'titulo': titulo.trim(),
        'descricao': descricao.trim(),
        'preco': preco,
        'fotoUrl': fotoUrl.trim(),
        'ordem': ordem,
        'ativo': ativo,
      },
    );

    if (result.isEmpty) return null;
    return _mapRowToProduto(result.first);
  }

  Future<bool> delete(String id) async {
    final result = await _db.execute(
      Sql.named('DELETE FROM produto WHERE id = @id'),
      parameters: {'id': id},
    );
    return result.affectedRows > 0;
  }

  Produto _mapRowToProduto(ResultRow row) {
    return Produto(
      id: row[0] as String,
      estabelecimentoId: row[1] as String,
      titulo: row[2] as String,
      descricao: row[3] as String? ?? '',
      preco: (row[4] as num?)?.toDouble() ?? 0.0,
      fotoUrl: row[5] as String? ?? '',
      ordem: row[6] as int? ?? 0,
      ativo: row[7] as bool? ?? true,
    );
  }
}
