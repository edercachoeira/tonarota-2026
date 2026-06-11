import 'package:postgres/postgres.dart';
import '../database/database_connection.dart';

class AuditoriaService {
  final DatabaseConnection _db = DatabaseConnection();

  static final AuditoriaService _instance = AuditoriaService._internal();
  factory AuditoriaService() => _instance;
  AuditoriaService._internal();

  Future<void> registrarLog({
    required String usuarioId,
    required String acao,
    required String detalhes,
    required String ip,
  }) async {
    try {
      // Busca o nome do usuário para denormalizar
      final userResult = await _db.execute(
        Sql.named('SELECT nome FROM usuario WHERE id = @id'),
        parameters: {'id': usuarioId},
      );
      
      String nome = 'Desconhecido';
      if (userResult.isNotEmpty) {
        nome = userResult.first[0] as String;
      }

      // Insere o log
      await _db.execute(
        Sql.named(
          'INSERT INTO log_auditoria (usuario_id, usuario_nome, acao, detalhes, ip, created_at) '
          'VALUES (@usuarioId, @nome, @acao, @detalhes, @ip, CURRENT_TIMESTAMP)'
        ),
        parameters: {
          'usuarioId': usuarioId,
          'nome': nome,
          'acao': acao,
          'detalhes': detalhes,
          'ip': ip,
        },
      );
    } catch (e) {
      print('Erro ao registrar log de auditoria: $e');
    }
  }

  Future<List<Map<String, dynamic>>> obterLogs({
    String? search,
    String? acao,
    String? dataInicio,
    String? dataFim,
  }) async {
    String queryStr = 'SELECT id, usuario_id, usuario_nome, acao, detalhes, ip, created_at FROM log_auditoria WHERE 1=1';
    final Map<String, dynamic> params = {};

    if (search != null && search.trim().isNotEmpty) {
      queryStr += ' AND (usuario_nome ILIKE @search OR detalhes ILIKE @search)';
      params['search'] = '%${search.trim()}%';
    }

    if (acao != null && acao != 'Todos' && acao.trim().isNotEmpty) {
      queryStr += ' AND acao = @acao';
      params['acao'] = acao.trim();
    }

    if (dataInicio != null && dataInicio.trim().isNotEmpty) {
      queryStr += ' AND created_at >= @dataInicio::timestamp';
      params['dataInicio'] = dataInicio.trim();
    }

    if (dataFim != null && dataFim.trim().isNotEmpty) {
      queryStr += ' AND created_at <= @dataFim::timestamp';
      params['dataFim'] = '${dataFim.trim()} 23:59:59';
    }

    queryStr += ' ORDER BY created_at DESC LIMIT 500';

    final result = await _db.execute(Sql.named(queryStr), parameters: params);

    return result.map((row) => {
      'id': row[0] as String,
      'usuario_id': row[1] as String,
      'usuario_nome': row[2] as String,
      'acao': row[3] as String,
      'detalhes': row[4] as String?,
      'ip': row[5] as String,
      'created_at': (row[6] as DateTime).toIso8601String(),
    }).toList();
  }
}
