import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/produto_service.dart';
import '../services/estabelecimento_service.dart';

class ProdutoRoutes {
  final ProdutoService _produtoService = ProdutoService();
  final EstabelecimentoService _estService = EstabelecimentoService();

  Router get router {
    final router = Router();

    // Listar todos os produtos de um estabelecimento (Acesso público)
    router.get('/estabelecimento/<estabelecimentoId>', (Request request, String estabelecimentoId) async {
      try {
        final list = await _produtoService.getAllByEstabelecimentoId(estabelecimentoId);
        final listJson = list.map((e) => e.toJson()).toList();
        return Response.ok(jsonEncode(listJson), headers: {'content-type': 'application/json'});
      } catch (e) {
        return Response(HttpStatus.internalServerError, body: jsonEncode({'error': e.toString()}), headers: {'content-type': 'application/json'});
      }
    });

    // Obter um produto específico (Acesso público)
    router.get('/<id>', (Request request, String id) async {
      try {
        final prod = await _produtoService.getById(id);
        if (prod == null) {
          return Response(HttpStatus.notFound, body: '{"error": "Produto não encontrado"}', headers: {'content-type': 'application/json'});
        }
        return Response.ok(jsonEncode(prod.toJson()), headers: {'content-type': 'application/json'});
      } catch (e) {
        return Response(HttpStatus.internalServerError, body: jsonEncode({'error': e.toString()}), headers: {'content-type': 'application/json'});
      }
    });

    // Criar um produto (Apenas dono do estabelecimento com plano Premium ou gestor)
    router.post('/', (Request request) async {
      try {
        final userId = request.context['user_id'] as String?;
        final userRole = request.context['user_role'] as String?;

        if (userId == null) {
          return Response(HttpStatus.unauthorized, body: '{"error": "Não autenticado"}', headers: {'content-type': 'application/json'});
        }

        final payload = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
        final estId = payload['estabelecimento_id'] as String?;

        if (estId == null) {
          return Response(HttpStatus.badRequest, body: '{"error": "ID do estabelecimento é obrigatório"}', headers: {'content-type': 'application/json'});
        }

        final est = await _estService.getById(estId);
        if (est == null) {
          return Response(HttpStatus.notFound, body: '{"error": "Estabelecimento não encontrado"}', headers: {'content-type': 'application/json'});
        }

        // Segurança cibernética: Verificar se o usuário atual é o proprietário ou se é gestor
        if (est.usuarioId != userId && userRole != 'gestor') {
          return Response(HttpStatus.forbidden, body: '{"error": "Acesso negado: Você não é o proprietário deste estabelecimento"}', headers: {'content-type': 'application/json'});
        }

        // Verificar se o plano do estabelecimento é Premium
        if (est.plano != 'premium' && userRole != 'gestor') {
          return Response(HttpStatus.forbidden, body: '{"error": "Acesso negado: Apenas estabelecimentos com plano Premium podem gerenciar catálogo"}', headers: {'content-type': 'application/json'});
        }

        final titulo = payload['titulo'] as String? ?? '';
        final descricao = payload['descricao'] as String? ?? '';
        final preco = (payload['preco'] as num?)?.toDouble() ?? 0.0;
        final fotoUrl = payload['foto_url'] as String? ?? '';
        final ordem = payload['ordem'] as int? ?? 0;
        final ativo = payload['ativo'] as bool? ?? true;

        if (titulo.trim().isEmpty) {
          return Response(HttpStatus.badRequest, body: '{"error": "Título do produto é obrigatório"}', headers: {'content-type': 'application/json'});
        }

        final prod = await _produtoService.create(
          estabelecimentoId: estId,
          titulo: titulo,
          descricao: descricao,
          preco: preco,
          fotoUrl: fotoUrl,
          ordem: ordem,
          ativo: ativo,
        );

        return Response(HttpStatus.created, body: jsonEncode(prod.toJson()), headers: {'content-type': 'application/json'});
      } catch (e) {
        return Response(HttpStatus.badRequest, body: jsonEncode({'error': e.toString()}), headers: {'content-type': 'application/json'});
      }
    });

    // Atualizar um produto (Apenas dono do estabelecimento com plano Premium ou gestor)
    router.put('/<id>', (Request request, String id) async {
      try {
        final userId = request.context['user_id'] as String?;
        final userRole = request.context['user_role'] as String?;

        if (userId == null) {
          return Response(HttpStatus.unauthorized, body: '{"error": "Não autenticado"}', headers: {'content-type': 'application/json'});
        }

        final existing = await _produtoService.getById(id);
        if (existing == null) {
          return Response(HttpStatus.notFound, body: '{"error": "Produto não encontrado"}', headers: {'content-type': 'application/json'});
        }

        final est = await _estService.getById(existing.estabelecimentoId);
        if (est == null) {
          return Response(HttpStatus.notFound, body: '{"error": "Estabelecimento não encontrado"}', headers: {'content-type': 'application/json'});
        }

        // Segurança cibernética: Verificar se o usuário atual é o proprietário ou se é gestor
        if (est.usuarioId != userId && userRole != 'gestor') {
          return Response(HttpStatus.forbidden, body: '{"error": "Acesso negado: Você não é o proprietário deste estabelecimento"}', headers: {'content-type': 'application/json'});
        }

        // Verificar se o plano do estabelecimento é Premium
        if (est.plano != 'premium' && userRole != 'gestor') {
          return Response(HttpStatus.forbidden, body: '{"error": "Acesso negado: Apenas estabelecimentos com plano Premium podem gerenciar catálogo"}', headers: {'content-type': 'application/json'});
        }

        final payload = jsonDecode(await request.readAsString()) as Map<String, dynamic>;

        final titulo = payload['titulo'] as String? ?? existing.titulo;
        final descricao = payload['descricao'] as String? ?? existing.descricao;
        final preco = (payload['preco'] as num?)?.toDouble() ?? existing.preco;
        final fotoUrl = payload['foto_url'] as String? ?? existing.fotoUrl;
        final ordem = payload['ordem'] as int? ?? existing.ordem;
        final ativo = payload['ativo'] as bool? ?? existing.ativo;

        final updated = await _produtoService.update(
          id,
          titulo: titulo,
          descricao: descricao,
          preco: preco,
          fotoUrl: fotoUrl,
          ordem: ordem,
          ativo: ativo,
        );

        if (updated == null) {
          return Response(HttpStatus.notFound, body: '{"error": "Produto não encontrado"}', headers: {'content-type': 'application/json'});
        }

        return Response.ok(jsonEncode(updated.toJson()), headers: {'content-type': 'application/json'});
      } catch (e) {
        return Response(HttpStatus.badRequest, body: jsonEncode({'error': e.toString()}), headers: {'content-type': 'application/json'});
      }
    });

    // Deletar um produto (Apenas dono do estabelecimento ou gestor)
    router.delete('/<id>', (Request request, String id) async {
      try {
        final userId = request.context['user_id'] as String?;
        final userRole = request.context['user_role'] as String?;

        if (userId == null) {
          return Response(HttpStatus.unauthorized, body: '{"error": "Não autenticado"}', headers: {'content-type': 'application/json'});
        }

        final existing = await _produtoService.getById(id);
        if (existing == null) {
          return Response(HttpStatus.notFound, body: '{"error": "Produto não encontrado"}', headers: {'content-type': 'application/json'});
        }

        final est = await _estService.getById(existing.estabelecimentoId);
        if (est == null) {
          return Response(HttpStatus.notFound, body: '{"error": "Estabelecimento não encontrado"}', headers: {'content-type': 'application/json'});
        }

        // Segurança cibernética: Verificar se o usuário atual é o proprietário ou se é gestor
        if (est.usuarioId != userId && userRole != 'gestor') {
          return Response(HttpStatus.forbidden, body: '{"error": "Acesso negado: Você não é o proprietário deste estabelecimento"}', headers: {'content-type': 'application/json'});
        }

        final success = await _produtoService.delete(id);
        if (!success) {
          return Response(HttpStatus.notFound, body: '{"error": "Produto não encontrado"}', headers: {'content-type': 'application/json'});
        }

        return Response.ok('{"message": "Produto deletado com sucesso"}', headers: {'content-type': 'application/json'});
      } catch (e) {
        return Response(HttpStatus.badRequest, body: jsonEncode({'error': e.toString()}), headers: {'content-type': 'application/json'});
      }
    });

    return router;
  }
}
