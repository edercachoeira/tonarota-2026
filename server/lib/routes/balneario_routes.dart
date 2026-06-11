import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/balneario_service.dart';

class BalnearioRoutes {
  final BalnearioService _balnearioService = BalnearioService();

  Router get router {
    final router = Router();

    // Listar todos os balneários
    router.get('/', (Request request) async {
      try {
        final apenasAtivos = request.url.queryParameters['ativos'] == 'true';
        final list = await _balnearioService.getAll(apenasAtivos: apenasAtivos);
        final listJson = list.map((b) => b.toJson()).toList();
        return Response.ok(jsonEncode(listJson), headers: {'content-type': 'application/json'});
      } catch (e) {
        return Response(HttpStatus.internalServerError, body: jsonEncode({'error': e.toString()}), headers: {'content-type': 'application/json'});
      }
    });

    // Obter um balneário por ID
    router.get('/<id>', (Request request, String id) async {
      try {
        final balneario = await _balnearioService.getById(id);
        if (balneario == null) {
          return Response(HttpStatus.notFound, body: '{"error": "Balneário não encontrado"}', headers: {'content-type': 'application/json'});
        }
        return Response.ok(jsonEncode(balneario.toJson()), headers: {'content-type': 'application/json'});
      } catch (e) {
        return Response(HttpStatus.internalServerError, body: jsonEncode({'error': e.toString()}), headers: {'content-type': 'application/json'});
      }
    });

    // Criar um balneário (Somente gestor)
    router.post('/', (Request request) async {
      try {
        // Validação de Role do usuário
        final userRole = request.context['user_role'] as String?;
        if (userRole != 'gestor') {
          return Response(HttpStatus.forbidden, body: '{"error": "Permissão insuficiente"}', headers: {'content-type': 'application/json'});
        }

        final payload = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
        final nome = payload['nome'] as String?;
        final municipio = payload['municipio'] as String?;
        final estado = payload['estado'] as String?;
        final descricao = payload['descricao'] as String? ?? '';
        final imagemCapaUrl = payload['imagem_capa_url'] as String? ?? '';

        if (nome == null || municipio == null || estado == null) {
          return Response(HttpStatus.badRequest, body: '{"error": "Campos obrigatórios: nome, municipio, estado"}', headers: {'content-type': 'application/json'});
        }

        final balneario = await _balnearioService.create(
          nome: nome,
          municipio: municipio,
          estado: estado,
          descricao: descricao,
          imagemCapaUrl: imagemCapaUrl,
        );

        return Response(HttpStatus.created, body: jsonEncode(balneario.toJson()), headers: {'content-type': 'application/json'});
      } catch (e) {
        return Response(HttpStatus.badRequest, body: jsonEncode({'error': e.toString()}), headers: {'content-type': 'application/json'});
      }
    });

    // Atualizar um balneário (Somente gestor)
    router.put('/<id>', (Request request, String id) async {
      try {
        // Validação de Role do usuário
        final userRole = request.context['user_role'] as String?;
        if (userRole != 'gestor') {
          return Response(HttpStatus.forbidden, body: '{"error": "Permissão insuficiente"}', headers: {'content-type': 'application/json'});
        }

        final payload = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
        final nome = payload['nome'] as String?;
        final municipio = payload['municipio'] as String?;
        final estado = payload['estado'] as String?;
        final descricao = payload['descricao'] as String? ?? '';
        final imagemCapaUrl = payload['imagem_capa_url'] as String? ?? '';
        final ativo = payload['ativo'] as bool? ?? true;

        if (nome == null || municipio == null || estado == null) {
          return Response(HttpStatus.badRequest, body: '{"error": "Campos obrigatórios: nome, municipio, estado"}', headers: {'content-type': 'application/json'});
        }

        final updated = await _balnearioService.update(
          id,
          nome: nome,
          municipio: municipio,
          estado: estado,
          descricao: descricao,
          imagemCapaUrl: imagemCapaUrl,
          ativo: ativo,
        );

        if (updated == null) {
          return Response(HttpStatus.notFound, body: '{"error": "Balneário não encontrado"}', headers: {'content-type': 'application/json'});
        }

        return Response.ok(jsonEncode(updated.toJson()), headers: {'content-type': 'application/json'});
      } catch (e) {
        return Response(HttpStatus.badRequest, body: jsonEncode({'error': e.toString()}), headers: {'content-type': 'application/json'});
      }
    });

    // Deletar um balneário (Somente gestor)
    router.delete('/<id>', (Request request, String id) async {
      try {
        // Validação de Role do usuário
        final userRole = request.context['user_role'] as String?;
        if (userRole != 'gestor') {
          return Response(HttpStatus.forbidden, body: '{"error": "Permissão insuficiente"}', headers: {'content-type': 'application/json'});
        }

        final deleted = await _balnearioService.delete(id);
        if (!deleted) {
          return Response(HttpStatus.notFound, body: '{"error": "Balneário não encontrado"}', headers: {'content-type': 'application/json'});
        }

        return Response.ok('{"message": "Balneário deletado com sucesso"}', headers: {'content-type': 'application/json'});
      } catch (e) {
        return Response(HttpStatus.internalServerError, body: jsonEncode({'error': e.toString()}), headers: {'content-type': 'application/json'});
      }
    });

    return router;
  }
}
