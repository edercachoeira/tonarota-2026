import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/auditoria_service.dart';

class AuditoriaRoutes {
  final AuditoriaService _auditoriaService = AuditoriaService();

  Router get router {
    final router = Router();

    // GET /api/v1/auditoria - Obter todos os logs com filtros (Apenas para Gestores)
    router.get('/', (Request request) async {
      try {
        final userRole = request.context['user_role'] as String?;
        if (userRole != 'gestor') {
          return Response(HttpStatus.forbidden, body: '{"error": "Acesso negado: Apenas gestores podem auditar o sistema"}', headers: {'content-type': 'application/json'});
        }

        final queryParams = request.url.queryParameters;
        final search = queryParams['search'];
        final acao = queryParams['acao'];
        final dataInicio = queryParams['data_inicio'];
        final dataFim = queryParams['data_fim'];

        final logs = await _auditoriaService.obterLogs(
          search: search,
          acao: acao,
          dataInicio: dataInicio,
          dataFim: dataFim,
        );

        return Response.ok(jsonEncode(logs), headers: {'content-type': 'application/json'});
      } catch (e) {
        return Response(HttpStatus.internalServerError, body: jsonEncode({'error': e.toString()}), headers: {'content-type': 'application/json'});
      }
    });

    return router;
  }
}
