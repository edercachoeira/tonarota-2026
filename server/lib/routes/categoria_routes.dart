import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/categoria_service.dart';

class CategoriaRoutes {
  final CategoriaService _categoriaService = CategoriaService();

  Router get router {
    final router = Router();

    // Listar todas as categorias
    router.get('/', (Request request) async {
      try {
        final apenasAtivos = request.url.queryParameters['ativos'] == 'true';
        final list = await _categoriaService.getAll(apenasAtivos: apenasAtivos);
        final listJson = list.map((c) => c.toJson()).toList();
        return Response.ok(jsonEncode(listJson), headers: {'content-type': 'application/json'});
      } catch (e) {
        return Response(HttpStatus.internalServerError, body: jsonEncode({'error': e.toString()}), headers: {'content-type': 'application/json'});
      }
    });

    // Obter categoria por ID
    router.get('/<id>', (Request request, String id) async {
      try {
        final categoria = await _categoriaService.getById(id);
        if (categoria == null) {
          return Response(HttpStatus.notFound, body: '{"error": "Categoria não encontrada"}', headers: {'content-type': 'application/json'});
        }
        return Response.ok(jsonEncode(categoria.toJson()), headers: {'content-type': 'application/json'});
      } catch (e) {
        return Response(HttpStatus.internalServerError, body: jsonEncode({'error': e.toString()}), headers: {'content-type': 'application/json'});
      }
    });

    // Criar categoria (Somente gestor)
    router.post('/', (Request request) async {
      try {
        final userRole = request.context['user_role'] as String?;
        if (userRole != 'gestor') {
          return Response(HttpStatus.forbidden, body: '{"error": "Permissão insuficiente"}', headers: {'content-type': 'application/json'});
        }

        final payload = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
        final nome = payload['nome'] as String?;
        final icone = payload['icone'] as String? ?? '';
        final descricao = payload['descricao'] as String? ?? '';
        final ordem = payload['ordem'] as int? ?? 0;
        final parentId = payload['parent_id'] as String?;

        if (nome == null) {
          return Response(HttpStatus.badRequest, body: '{"error": "Campo obrigatório: nome"}', headers: {'content-type': 'application/json'});
        }

        final categoria = await _categoriaService.create(
          nome: nome,
          icone: icone,
          descricao: descricao,
          ordem: ordem,
          parentId: parentId,
        );

        return Response(HttpStatus.created, body: jsonEncode(categoria.toJson()), headers: {'content-type': 'application/json'});
      } catch (e) {
        return Response(HttpStatus.badRequest, body: jsonEncode({'error': e.toString()}), headers: {'content-type': 'application/json'});
      }
    });

    // Atualizar categoria (Somente gestor)
    router.put('/<id>', (Request request, String id) async {
      try {
        final userRole = request.context['user_role'] as String?;
        if (userRole != 'gestor') {
          return Response(HttpStatus.forbidden, body: '{"error": "Permissão insuficiente"}', headers: {'content-type': 'application/json'});
        }

        final payload = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
        final nome = payload['nome'] as String?;
        final icone = payload['icone'] as String? ?? '';
        final descricao = payload['descricao'] as String? ?? '';
        final ordem = payload['ordem'] as int? ?? 0;
        final parentId = payload['parent_id'] as String?;
        final ativo = payload['ativo'] as bool? ?? true;

        if (nome == null) {
          return Response(HttpStatus.badRequest, body: '{"error": "Campo obrigatório: nome"}', headers: {'content-type': 'application/json'});
        }

        final updated = await _categoriaService.update(
          id,
          nome: nome,
          icone: icone,
          descricao: descricao,
          ordem: ordem,
          parentId: parentId,
          ativo: ativo,
        );

        if (updated == null) {
          return Response(HttpStatus.notFound, body: '{"error": "Categoria não encontrada"}', headers: {'content-type': 'application/json'});
        }

        return Response.ok(jsonEncode(updated.toJson()), headers: {'content-type': 'application/json'});
      } catch (e) {
        return Response(HttpStatus.badRequest, body: jsonEncode({'error': e.toString()}), headers: {'content-type': 'application/json'});
      }
    });

    // Deletar categoria (Somente gestor)
    router.delete('/<id>', (Request request, String id) async {
      try {
        final userRole = request.context['user_role'] as String?;
        if (userRole != 'gestor') {
          return Response(HttpStatus.forbidden, body: '{"error": "Permissão insuficiente"}', headers: {'content-type': 'application/json'});
        }

        final deleted = await _categoriaService.delete(id);
        if (!deleted) {
          return Response(HttpStatus.notFound, body: '{"error": "Categoria não encontrada"}', headers: {'content-type': 'application/json'});
        }

        return Response.ok('{"message": "Categoria deletada com sucesso"}', headers: {'content-type': 'application/json'});
      } catch (e) {
        return Response(HttpStatus.internalServerError, body: jsonEncode({'error': e.toString()}), headers: {'content-type': 'application/json'});
      }
    });

    return router;
  }
}
