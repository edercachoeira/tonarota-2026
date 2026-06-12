import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/metrica_service.dart';

class MetricaRoutes {
  final MetricaService _metricaService = MetricaService();

  Router get router {
    final router = Router();

    // Registrar clique ou visualização (público)
    router.post('/registrar', (Request request) async {
      try {
        final payload = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
        final estId = payload['estabelecimento_id'] as String?;
        final tipo = payload['tipo'] as String?;

        if (estId == null || tipo == null) {
          return Response(HttpStatus.badRequest, 
            body: '{"error": "Campos obrigatórios: estabelecimento_id, tipo"}',
            headers: {'content-type': 'application/json'});
        }

        if (tipo != 'visualizacao' && tipo != 'whatsapp' && tipo != 'instagram') {
          return Response(HttpStatus.badRequest, 
            body: '{"error": "Tipo inválido. Permitidos: visualizacao, whatsapp, instagram"}',
            headers: {'content-type': 'application/json'});
        }

        await _metricaService.registrarEvento(estabelecimentoId: estId, tipo: tipo);
        return Response.ok('{"success": true}', headers: {'content-type': 'application/json'});
      } catch (e) {
        return Response(HttpStatus.internalServerError, 
          body: jsonEncode({'error': e.toString()}), 
          headers: {'content-type': 'application/json'});
      }
    });

    // Obter dados consolidados para o dashboard do lojista / admin
    router.get('/estabelecimento/<id>', (Request request, String id) async {
      try {
        final acumulado = await _metricaService.getTotaisAcumulados(id);
        final semanal = await _metricaService.getHistoricoSemanal(id);

        return Response.ok(
          jsonEncode({
            'acumulado': acumulado,
            'semanal': semanal,
          }),
          headers: {'content-type': 'application/json'},
        );
      } catch (e) {
        return Response(HttpStatus.internalServerError, 
          body: jsonEncode({'error': e.toString()}), 
          headers: {'content-type': 'application/json'});
      }
    });

    return router;
  }
}
