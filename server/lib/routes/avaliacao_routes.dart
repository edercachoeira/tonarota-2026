import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/avaliacao_service.dart';

class AvaliacaoRoutes {
  final AvaliacaoService _avService = AvaliacaoService();

  Router get router {
    final router = Router();

    // Criar avaliação (Público)
    router.post('/', (Request request) async {
      try {
        final payload = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
        final estId = payload['estabelecimento_id'] as String?;
        final notaVal = payload['nota'] as int?;
        final comentario = payload['comentario'] as String? ?? '';

        if (estId == null || notaVal == null) {
          return Response(HttpStatus.badRequest, 
            body: '{"error": "Campos obrigatórios: estabelecimento_id, nota"}',
            headers: {'content-type': 'application/json'});
        }

        if (notaVal < 1 || notaVal > 5) {
          return Response(HttpStatus.badRequest, 
            body: '{"error": "Nota deve estar entre 1 e 5"}',
            headers: {'content-type': 'application/json'});
        }

        final av = await _avService.create(
          estabelecimentoId: estId,
          nota: notaVal,
          comentario: comentario,
        );

        return Response(HttpStatus.created, body: jsonEncode(av.toJson()), headers: {'content-type': 'application/json'});
      } catch (e) {
        return Response(HttpStatus.internalServerError, 
          body: jsonEncode({'error': e.toString()}), 
          headers: {'content-type': 'application/json'});
      }
    });

    // Listar avaliações de um estabelecimento específico (Público)
    router.get('/estabelecimento/<id>', (Request request, String id) async {
      try {
        final list = await _avService.getByEstabelecimento(id);
        final listJson = list.map((e) => e.toJson()).toList();
        return Response.ok(jsonEncode(listJson), headers: {'content-type': 'application/json'});
      } catch (e) {
        return Response(HttpStatus.internalServerError, 
          body: jsonEncode({'error': e.toString()}), 
          headers: {'content-type': 'application/json'});
      }
    });

    // Listar todas para moderação (Restrito a Gestores no Admin)
    router.get('/admin', (Request request) async {
      try {
        final userRole = request.context['user_role'] as String?;
        if (userRole != 'gestor') {
          return Response(HttpStatus.forbidden, body: '{"error": "Acesso negado: apenas gestores"}', headers: {'content-type': 'application/json'});
        }

        final list = await _avService.getAllForAdmin();
        return Response.ok(jsonEncode(list), headers: {'content-type': 'application/json'});
      } catch (e) {
        return Response(HttpStatus.internalServerError, 
          body: jsonEncode({'error': e.toString()}), 
          headers: {'content-type': 'application/json'});
      }
    });

    // Alterar status de moderação (Restrito a Gestores no Admin)
    router.put('/admin/<id>/status', (Request request, String id) async {
      try {
        final userRole = request.context['user_role'] as String?;
        if (userRole != 'gestor') {
          return Response(HttpStatus.forbidden, body: '{"error": "Acesso negado: apenas gestores"}', headers: {'content-type': 'application/json'});
        }

        final payload = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
        final status = payload['status'] as String?;

        if (status == null || (status != 'aprovada' && status != 'oculta')) {
          return Response(HttpStatus.badRequest, 
            body: '{"error": "Status inválido. Permitidos: aprovada, oculta"}', 
            headers: {'content-type': 'application/json'});
        }

        final updated = await _avService.updateStatus(id, status);
        if (updated == null) {
          return Response(HttpStatus.notFound, body: '{"error": "Avaliação não encontrada"}', headers: {'content-type': 'application/json'});
        }

        return Response.ok(jsonEncode(updated.toJson()), headers: {'content-type': 'application/json'});
      } catch (e) {
        return Response(HttpStatus.internalServerError, 
          body: jsonEncode({'error': e.toString()}), 
          headers: {'content-type': 'application/json'});
      }
    });

    return router;
  }
}
