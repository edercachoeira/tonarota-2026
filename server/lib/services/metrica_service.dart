import 'package:postgres/postgres.dart';
import '../database/database_connection.dart';

class MetricaService {
  final DatabaseConnection _db = DatabaseConnection();

  Future<void> registrarEvento({
    required String estabelecimentoId,
    required String tipo,
  }) async {
    // 1. Upsert na tabela de métricas diárias
    await _db.execute(
      Sql.named(
        'INSERT INTO estabelecimento_metrica (estabelecimento_id, tipo, data, quantidade) '
        'VALUES (@estabelecimentoId, @tipo, CURRENT_DATE, 1) '
        'ON CONFLICT (estabelecimento_id, tipo, data) '
        'DO UPDATE SET quantidade = estabelecimento_metrica.quantidade + 1',
      ),
      parameters: {
        'estabelecimentoId': estabelecimentoId,
        'tipo': tipo,
      },
    );

    // 2. Se for visualização, atualiza o acumulador histórico na tabela estabelecimento
    if (tipo == 'visualizacao') {
      await _db.execute(
        Sql.named(
          'UPDATE estabelecimento SET total_visualizacoes = total_visualizacoes + 1 '
          'WHERE id = @estabelecimentoId',
        ),
        parameters: {
          'estabelecimentoId': estabelecimentoId,
        },
      );
    }
  }

  Future<Map<String, int>> getTotaisAcumulados(String estabelecimentoId) async {
    final result = await _db.execute(
      Sql.named(
        'SELECT tipo, SUM(quantidade) FROM estabelecimento_metrica '
        'WHERE estabelecimento_id = @estabelecimentoId '
        'GROUP BY tipo',
      ),
      parameters: {
        'estabelecimentoId': estabelecimentoId,
      },
    );

    final Map<String, int> totais = {
      'visualizacao': 0,
      'whatsapp': 0,
      'instagram': 0,
    };

    for (final row in result) {
      final tipo = row[0] as String;
      final total = (row[1] as num?)?.toInt() ?? 0;
      if (totais.containsKey(tipo)) {
        totais[tipo] = total;
      }
    }

    // Se o total de visualizações der 0, mas na tabela estabelecimento houver valor legado, usamos o maior
    final estResult = await _db.execute(
      Sql.named('SELECT total_visualizacoes FROM estabelecimento WHERE id = @id'),
      parameters: {'id': estabelecimentoId},
    );
    if (estResult.isNotEmpty) {
      final legVisualizacoes = estResult.first[0] as int? ?? 0;
      if (legVisualizacoes > (totais['visualizacao'] ?? 0)) {
        totais['visualizacao'] = legVisualizacoes;
      }
    }

    return totais;
  }

  Future<List<Map<String, dynamic>>> getHistoricoSemanal(String estabelecimentoId) async {
    final result = await _db.execute(
      Sql.named(
        'SELECT data, quantidade FROM estabelecimento_metrica '
        'WHERE estabelecimento_id = @estabelecimentoId '
        'AND tipo = \'visualizacao\' '
        'AND data >= CURRENT_DATE - INTERVAL \'6 days\' '
        'ORDER BY data ASC',
      ),
      parameters: {
        'estabelecimentoId': estabelecimentoId,
      },
    );

    // Gerar os últimos 7 dias para garantir que dias com 0 acessos apareçam no gráfico
    final List<DateTime> last7Days = List.generate(7, (i) {
      return DateTime.now().subtract(Duration(days: 6 - i));
    });

    final Map<String, int> dataMap = {};
    for (final row in result) {
      final dateVal = row[0] as DateTime;
      final count = row[1] as int;
      final dateKey = '${dateVal.year}-${dateVal.month.toString().padLeft(2, '0')}-${dateVal.day.toString().padLeft(2, '0')}';
      dataMap[dateKey] = count;
    }

    final List<Map<String, dynamic>> historico = [];
    final weekdayNames = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];

    for (final day in last7Days) {
      final dateKey = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      historico.add({
        'dia': weekdayNames[day.weekday % 7], // Ajusta para Domingo ser o índice 0 na lista
        'quantidade': dataMap[dateKey] ?? 0,
        'data': dateKey,
      });
    }

    return historico;
  }
}
