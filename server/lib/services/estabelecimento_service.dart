import 'dart:convert';
import 'package:postgres/postgres.dart';
import 'package:tonarota_shared/tonarota_shared.dart';
import '../database/database_connection.dart';

class EstabelecimentoService {
  final DatabaseConnection _db = DatabaseConnection();

  Future<Estabelecimento> create({
    required String usuarioId,
    required String balnearioId,
    required String categoriaId,
    required String nomeFantasia,
    required String documento,
    String endereco = '',
    String telefone = '',
    String whatsapp = '',
    String instagram = '',
    String descricao = '',
    String logomarcaUrl = '',
    String plano = 'gratuito',
    String status = 'pendente',
    Map<String, dynamic> horarios = const {},
  }) async {
    final result = await _db.execute(
      Sql.named(
        'INSERT INTO estabelecimento (usuario_id, balneario_id, categoria_id, nome_fantasia, documento, '
        'endereco, telefone, whatsapp, instagram, descricao, logomarca_url, plano, status, horarios, '
        'nota_media, total_avaliacoes, total_visualizacoes, created_at, updated_at) '
        'VALUES (@usuarioId, @balnearioId, @categoriaId, @nomeFantasia, @documento, '
        '@endereco, @telefone, @whatsapp, @instagram, @descricao, @logomarcaUrl, @plano, @status, '
        'CAST(@horarios AS JSONB), 0.0, 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP) '
        'RETURNING id, usuario_id, balneario_id, categoria_id, nome_fantasia, documento, '
        'endereco, telefone, whatsapp, instagram, descricao, logomarca_url, plano, status, horarios, '
        'nota_media, total_avaliacoes, total_visualizacoes, created_at, updated_at',
      ),
      parameters: {
        'usuarioId': usuarioId,
        'balnearioId': balnearioId,
        'categoriaId': categoriaId,
        'nomeFantasia': nomeFantasia.trim(),
        'documento': documento.trim(),
        'endereco': endereco.trim(),
        'telefone': telefone.trim(),
        'whatsapp': whatsapp.trim(),
        'instagram': instagram.trim(),
        'descricao': descricao.trim(),
        'logomarcaUrl': logomarcaUrl.trim(),
        'plano': plano,
        'status': status,
        'horarios': jsonEncode(horarios),
      },
    );

    final row = result.first;
    return _mapRowToEstabelecimento(row);
  }

  Future<List<Estabelecimento>> getAll({
    String? balnearioId,
    String? categoriaId,
    String? plano,
    String? status,
  }) async {
    var query = 'SELECT id, usuario_id, balneario_id, categoria_id, nome_fantasia, documento, '
        'endereco, telefone, whatsapp, instagram, descricao, logomarca_url, plano, status, horarios, '
        'nota_media, total_avaliacoes, total_visualizacoes, created_at, updated_at FROM estabelecimento WHERE 1=1';
    
    final Map<String, dynamic> params = {};

    if (balnearioId != null) {
      query += ' AND balneario_id = @balnearioId';
      params['balnearioId'] = balnearioId;
    }
    if (categoriaId != null) {
      query += ' AND categoria_id = @categoriaId';
      params['categoriaId'] = categoriaId;
    }
    if (plano != null) {
      query += ' AND plano = @plano';
      params['plano'] = plano;
    }
    if (status != null) {
      query += ' AND status = @status';
      params['status'] = status;
    }

    query += ' ORDER BY nome_fantasia ASC';

    final result = await _db.execute(Sql.named(query), parameters: params);
    return result.map((row) => _mapRowToEstabelecimento(row)).toList();
  }

  Future<Estabelecimento?> getById(String id) async {
    final result = await _db.execute(
      Sql.named(
        'SELECT id, usuario_id, balneario_id, categoria_id, nome_fantasia, documento, '
        'endereco, telefone, whatsapp, instagram, descricao, logomarca_url, plano, status, horarios, '
        'nota_media, total_avaliacoes, total_visualizacoes, created_at, updated_at '
        'FROM estabelecimento WHERE id = @id',
      ),
      parameters: {'id': id},
    );

    if (result.isEmpty) return null;
    return _mapRowToEstabelecimento(result.first);
  }

  Future<Estabelecimento?> getByUsuarioId(String usuarioId) async {
    final result = await _db.execute(
      Sql.named(
        'SELECT id, usuario_id, balneario_id, categoria_id, nome_fantasia, documento, '
        'endereco, telefone, whatsapp, instagram, descricao, logomarca_url, plano, status, horarios, '
        'nota_media, total_avaliacoes, total_visualizacoes, created_at, updated_at '
        'FROM estabelecimento WHERE usuario_id = @usuarioId',
      ),
      parameters: {'usuarioId': usuarioId},
    );

    if (result.isEmpty) return null;
    return _mapRowToEstabelecimento(result.first);
  }

  Future<Estabelecimento?> update(
    String id, {
    required String balnearioId,
    required String categoriaId,
    required String nomeFantasia,
    required String documento,
    required String endereco,
    required String telefone,
    required String whatsapp,
    required String instagram,
    required String descricao,
    required String logomarcaUrl,
    required String plano,
    required String status,
    required Map<String, dynamic> horarios,
  }) async {
    final result = await _db.execute(
      Sql.named(
        'UPDATE estabelecimento '
        'SET balneario_id = @balnearioId, categoria_id = @categoriaId, nome_fantasia = @nomeFantasia, '
        '    documento = @documento, endereco = @endereco, telefone = @telefone, whatsapp = @whatsapp, '
        '    instagram = @instagram, descricao = @descricao, logomarca_url = @logomarcaUrl, '
        '    plano = @plano, status = @status, horarios = CAST(@horarios AS JSONB), updated_at = CURRENT_TIMESTAMP '
        'WHERE id = @id '
        'RETURNING id, usuario_id, balneario_id, categoria_id, nome_fantasia, documento, '
        'endereco, telefone, whatsapp, instagram, descricao, logomarca_url, plano, status, horarios, '
        'nota_media, total_avaliacoes, total_visualizacoes, created_at, updated_at',
      ),
      parameters: {
        'id': id,
        'balnearioId': balnearioId,
        'categoriaId': categoriaId,
        'nomeFantasia': nomeFantasia.trim(),
        'documento': documento.trim(),
        'endereco': endereco.trim(),
        'telefone': telefone.trim(),
        'whatsapp': whatsapp.trim(),
        'instagram': instagram.trim(),
        'descricao': descricao.trim(),
        'logomarcaUrl': logomarcaUrl.trim(),
        'plano': plano,
        'status': status,
        'horarios': jsonEncode(horarios),
      },
    );

    if (result.isEmpty) return null;
    return _mapRowToEstabelecimento(result.first);
  }

  Future<bool> delete(String id) async {
    final result = await _db.execute(
      Sql.named('DELETE FROM estabelecimento WHERE id = @id'),
      parameters: {'id': id},
    );
    return result.affectedRows > 0;
  }

  Estabelecimento _mapRowToEstabelecimento(ResultRow row) {
    // horarios no postgres 3.x pode vir como String ou como Map direto dependendo do encoder.
    // Vamos garantir a conversão segura de horarios.
    Map<String, dynamic> parsedHorarios = {};
    final rawHorarios = row[14];
    if (rawHorarios is String) {
      parsedHorarios = jsonDecode(rawHorarios) as Map<String, dynamic>;
    } else if (rawHorarios is Map) {
      parsedHorarios = Map<String, dynamic>.from(rawHorarios);
    }

    return Estabelecimento(
      id: row[0] as String,
      usuarioId: row[1] as String,
      balnearioId: row[2] as String,
      categoriaId: row[3] as String,
      nomeFantasia: row[4] as String,
      documento: row[5] as String,
      endereco: row[6] as String,
      telefone: row[7] as String,
      whatsapp: row[8] as String,
      instagram: row[9] as String,
      descricao: row[10] as String,
      logomarcaUrl: row[11] as String,
      plano: row[12] as String,
      status: row[13] as String,
      horarios: parsedHorarios,
      notaMedia: (row[15] as num?)?.toDouble() ?? 0.0,
      totalAvaliacoes: row[16] as int? ?? 0,
      totalVisualizacoes: row[17] as int? ?? 0,
      createdAt: row[18] as DateTime,
      updatedAt: row[19] as DateTime,
    );
  }
}
