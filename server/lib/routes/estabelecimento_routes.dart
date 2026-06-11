import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/estabelecimento_service.dart';

class EstabelecimentoRoutes {
  final EstabelecimentoService _estService = EstabelecimentoService();

  Router get router {
    final router = Router();

    // Listar todos os estabelecimentos com filtros opcionais
    router.get('/', (Request request) async {
      try {
        final balnearioId = request.url.queryParameters['balneario_id'];
        final categoriaId = request.url.queryParameters['categoria_id'];
        final plano = request.url.queryParameters['plano'];
        final status = request.url.queryParameters['status'];

        final list = await _estService.getAll(
          balnearioId: balnearioId,
          categoriaId: categoriaId,
          plano: plano,
          status: status,
        );

        final listJson = list.map((e) => e.toJson()).toList();
        return Response.ok(jsonEncode(listJson), headers: {'content-type': 'application/json'});
      } catch (e) {
        return Response(HttpStatus.internalServerError, body: jsonEncode({'error': e.toString()}), headers: {'content-type': 'application/json'});
      }
    });

    // Obter um estabelecimento específico
    router.get('/<id>', (Request request, String id) async {
      try {
        final est = await _estService.getById(id);
        if (est == null) {
          return Response(HttpStatus.notFound, body: '{"error": "Estabelecimento não encontrado"}', headers: {'content-type': 'application/json'});
        }
        return Response.ok(jsonEncode(est.toJson()), headers: {'content-type': 'application/json'});
      } catch (e) {
        return Response(HttpStatus.internalServerError, body: jsonEncode({'error': e.toString()}), headers: {'content-type': 'application/json'});
      }
    });

    // Criar um estabelecimento (Lojista ou Gestor)
    router.post('/', (Request request) async {
      try {
        final userId = request.context['user_id'] as String?;
        final userRole = request.context['user_role'] as String?;

        if (userId == null) {
          return Response(HttpStatus.unauthorized, body: '{"error": "Não autenticado"}', headers: {'content-type': 'application/json'});
        }

        // Apenas lojistas ou gestores podem cadastrar estabelecimento
        if (userRole != 'estabelecimento' && userRole != 'gestor') {
          return Response(HttpStatus.forbidden, body: '{"error": "Permissão insuficiente"}', headers: {'content-type': 'application/json'});
        }

        final payload = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
        
        final balnearioId = payload['balneario_id'] as String?;
        final categoriaId = payload['categoria_id'] as String?;
        final nomeFantasia = payload['nome_fantasia'] as String?;
        final documento = payload['documento'] as String?;
        
        if (balnearioId == null || categoriaId == null || nomeFantasia == null || documento == null) {
          return Response(HttpStatus.badRequest, 
            body: '{"error": "Campos obrigatórios: balneario_id, categoria_id, nome_fantasia, documento"}', 
            headers: {'content-type': 'application/json'});
        }

        // Lojistas só podem cadastrar estabelecimento associado ao seu próprio usuário
        // Gestor pode cadastrar com outro usuario_id especificado no payload
        String targetUsuarioId = userId;
        if (userRole == 'gestor' && payload['usuario_id'] != null) {
          targetUsuarioId = payload['usuario_id'] as String;
        }

        final est = await _estService.create(
          usuarioId: targetUsuarioId,
          balnearioId: balnearioId,
          categoriaId: categoriaId,
          nomeFantasia: nomeFantasia,
          documento: documento,
          endereco: payload['endereco'] as String? ?? '',
          telefone: payload['telefone'] as String? ?? '',
          whatsapp: payload['whatsapp'] as String? ?? '',
          instagram: payload['instagram'] as String? ?? '',
          descricao: payload['descricao'] as String? ?? '',
          logomarcaUrl: payload['logomarca_url'] as String? ?? '',
          plano: payload['plano'] as String? ?? 'gratuito',
          status: payload['status'] as String? ?? 'pendente',
          horarios: payload['horarios'] as Map<String, dynamic>? ?? {},
        );

        return Response(HttpStatus.created, body: jsonEncode(est.toJson()), headers: {'content-type': 'application/json'});
      } catch (e) {
        return Response(HttpStatus.badRequest, body: jsonEncode({'error': e.toString()}), headers: {'content-type': 'application/json'});
      }
    });

    // Atualizar um estabelecimento (Apenas dono ou gestor)
    router.put('/<id>', (Request request, String id) async {
      try {
        final userId = request.context['user_id'] as String?;
        final userRole = request.context['user_role'] as String?;

        if (userId == null) {
          return Response(HttpStatus.unauthorized, body: '{"error": "Não autenticado"}', headers: {'content-type': 'application/json'});
        }

        final existing = await _estService.getById(id);
        if (existing == null) {
          return Response(HttpStatus.notFound, body: '{"error": "Estabelecimento não encontrado"}', headers: {'content-type': 'application/json'});
        }

        // Segurança cibernética: Verificar se o usuário atual é o proprietário ou se é gestor
        if (existing.usuarioId != userId && userRole != 'gestor') {
          return Response(HttpStatus.forbidden, body: '{"error": "Acesso negado: Você não é o proprietário deste estabelecimento"}', headers: {'content-type': 'application/json'});
        }

        final payload = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
        
        final balnearioId = payload['balneario_id'] as String? ?? existing.balnearioId;
        final categoriaId = payload['categoria_id'] as String? ?? existing.categoriaId;
        final nomeFantasia = payload['nome_fantasia'] as String? ?? existing.nomeFantasia;
        final documento = payload['documento'] as String? ?? existing.documento;
        final endereco = payload['endereco'] as String? ?? existing.endereco;
        final telefone = payload['telefone'] as String? ?? existing.telefone;
        final whatsapp = payload['whatsapp'] as String? ?? existing.whatsapp;
        final instagram = payload['instagram'] as String? ?? existing.instagram;
        final descricao = payload['descricao'] as String? ?? existing.descricao;
        final logomarcaUrl = payload['logomarca_url'] as String? ?? existing.logomarcaUrl;
        final plano = payload['plano'] as String? ?? existing.plano;
        final status = payload['status'] as String? ?? existing.status;
        final horarios = payload['horarios'] as Map<String, dynamic>? ?? existing.horarios;

        final updated = await _estService.update(
          id,
          balnearioId: balnearioId,
          categoriaId: categoriaId,
          nomeFantasia: nomeFantasia,
          documento: documento,
          endereco: endereco,
          telefone: telefone,
          whatsapp: whatsapp,
          instagram: instagram,
          descricao: descricao,
          logomarcaUrl: logomarcaUrl,
          plano: plano,
          status: status,
          horarios: horarios,
        );

        return Response.ok(jsonEncode(updated?.toJson()), headers: {'content-type': 'application/json'});
      } catch (e) {
        return Response(HttpStatus.badRequest, body: jsonEncode({'error': e.toString()}), headers: {'content-type': 'application/json'});
      }
    });

    // Deletar um estabelecimento (Apenas dono ou gestor)
    router.delete('/<id>', (Request request, String id) async {
      try {
        final userId = request.context['user_id'] as String?;
        final userRole = request.context['user_role'] as String?;

        if (userId == null) {
          return Response(HttpStatus.unauthorized, body: '{"error": "Não autenticado"}', headers: {'content-type': 'application/json'});
        }

        final existing = await _estService.getById(id);
        if (existing == null) {
          return Response(HttpStatus.notFound, body: '{"error": "Estabelecimento não encontrado"}', headers: {'content-type': 'application/json'});
        }

        if (existing.usuarioId != userId && userRole != 'gestor') {
          return Response(HttpStatus.forbidden, body: '{"error": "Acesso negado"}', headers: {'content-type': 'application/json'});
        }

        final deleted = await _estService.delete(id);
        if (!deleted) {
          return Response(HttpStatus.notFound, body: '{"error": "Estabelecimento não encontrado"}', headers: {'content-type': 'application/json'});
        }

        return Response.ok('{"message": "Estabelecimento deletado com sucesso"}', headers: {'content-type': 'application/json'});
      } catch (e) {
        return Response(HttpStatus.internalServerError, body: jsonEncode({'error': e.toString()}), headers: {'content-type': 'application/json'});
      }
    });

    return router;
  }
}
