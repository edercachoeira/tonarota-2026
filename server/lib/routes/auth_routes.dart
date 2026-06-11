import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/auth_service.dart';
import '../services/auditoria_service.dart';

class AuthRoutes {
  final AuthService _authService = AuthService();
  final AuditoriaService _auditoriaService = AuditoriaService();

  Router get router {
    final router = Router();

    // Rota de registro
    router.post('/register', (Request request) async {
      try {
        final payload = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
        
        final email = payload['email'] as String?;
        final password = payload['password'] as String?;
        final nome = payload['nome'] as String?;
        final role = payload['role'] as String? ?? 'turista';

        if (email == null || password == null || nome == null) {
          return Response(HttpStatus.badRequest, body: '{"error": "Campos obrigatórios: email, password, nome"}', headers: {'content-type': 'application/json'});
        }

        final user = await _authService.register(
          email: email,
          password: password,
          nome: nome,
          role: role,
        );

        final forwarded = request.headers['x-forwarded-for'] ?? '127.0.0.1';
        await _auditoriaService.registrarLog(
          usuarioId: user.id,
          acao: 'REGISTRO_CONTA',
          detalhes: 'Conta criada: ${user.nome} (${user.email}) com cargo ${user.role}',
          ip: forwarded.split(',').first.trim(),
        );

        return Response(HttpStatus.created, body: jsonEncode(user.toJson()), headers: {'content-type': 'application/json'});
      } catch (e) {
        return Response(HttpStatus.badRequest, body: jsonEncode({'error': e.toString()}), headers: {'content-type': 'application/json'});
      }
    });

    // Rota de login
    router.post('/login', (Request request) async {
      try {
        final payload = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
        
        final email = payload['email'] as String?;
        final password = payload['password'] as String?;

        if (email == null || password == null) {
          return Response(HttpStatus.badRequest, body: '{"error": "Campos obrigatórios: email, password"}', headers: {'content-type': 'application/json'});
        }

        final loginData = await _authService.login(email, password);
        if (loginData == null) {
          return Response(HttpStatus.unauthorized, body: '{"error": "E-mail ou senha incorretos"}', headers: {'content-type': 'application/json'});
        }

        final userMap = loginData['user'] as Map<String, dynamic>;
        final userId = userMap['id'] as String;
        final forwarded = request.headers['x-forwarded-for'] ?? '127.0.0.1';
        await _auditoriaService.registrarLog(
          usuarioId: userId,
          acao: 'LOGIN',
          detalhes: 'Realizou login no sistema',
          ip: forwarded.split(',').first.trim(),
        );

        return Response.ok(jsonEncode(loginData), headers: {'content-type': 'application/json'});
      } catch (e) {
        return Response(HttpStatus.badRequest, body: jsonEncode({'error': e.toString()}), headers: {'content-type': 'application/json'});
      }
    });

    // Rota de perfil (me)
    router.get('/me', (Request request) async {
      try {
        final userId = request.context['user_id'] as String?;
        if (userId == null) {
          return Response(HttpStatus.unauthorized, body: '{"error": "Não autenticado"}', headers: {'content-type': 'application/json'});
        }

        final user = await _authService.getUserById(userId);
        if (user == null) {
          return Response(HttpStatus.notFound, body: '{"error": "Usuário não encontrado"}', headers: {'content-type': 'application/json'});
        }

        return Response.ok(jsonEncode(user.toJson()), headers: {'content-type': 'application/json'});
      } catch (e) {
        return Response(HttpStatus.internalServerError, body: jsonEncode({'error': e.toString()}), headers: {'content-type': 'application/json'});
      }
    });

    // Atualizar perfil/senha do usuário logado
    router.put('/me', (Request request) async {
      try {
        final userId = request.context['user_id'] as String?;
        if (userId == null) {
          return Response(HttpStatus.unauthorized, body: '{"error": "Não autenticado"}', headers: {'content-type': 'application/json'});
        }

        final payload = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
        final nome = payload['nome'] as String?;
        final email = payload['email'] as String?;
        final oldPassword = payload['old_password'] as String?;
        final newPassword = payload['new_password'] as String?;

        if (nome == null || email == null) {
          return Response(HttpStatus.badRequest, body: '{"error": "Campos nome e email são obrigatórios"}', headers: {'content-type': 'application/json'});
        }

        final updatedUser = await _authService.updateProfile(
          userId,
          nome,
          email,
          oldPassword: oldPassword,
          newPassword: newPassword,
        );

        final forwarded = request.headers['x-forwarded-for'] ?? '127.0.0.1';
        await _auditoriaService.registrarLog(
          usuarioId: userId,
          acao: 'ATUALIZAR_PERFIL',
          detalhes: 'Atualizou dados do perfil ou senha',
          ip: forwarded.split(',').first.trim(),
        );

        return Response.ok(jsonEncode(updatedUser?.toJson()), headers: {'content-type': 'application/json'});
      } catch (e) {
        return Response(HttpStatus.badRequest, body: jsonEncode({'error': e.toString()}), headers: {'content-type': 'application/json'});
      }
    });

    // Listar todos os gestores (apenas para gestores)
    router.get('/gestores', (Request request) async {
      try {
        final userRole = request.context['user_role'] as String?;
        if (userRole != 'gestor') {
          return Response(HttpStatus.forbidden, body: '{"error": "Acesso negado: Apenas gestores podem visualizar administradores"}', headers: {'content-type': 'application/json'});
        }

        final list = await _authService.getGestores();
        final listJson = list.map((u) => u.toJson()).toList();
        return Response.ok(jsonEncode(listJson), headers: {'content-type': 'application/json'});
      } catch (e) {
        return Response(HttpStatus.internalServerError, body: jsonEncode({'error': e.toString()}), headers: {'content-type': 'application/json'});
      }
    });

    // Excluir gestor (apenas para gestores, impede deletar a si mesmo)
    router.delete('/gestores/<id>', (Request request, String id) async {
      try {
        final userId = request.context['user_id'] as String?;
        final userRole = request.context['user_role'] as String?;

        if (userRole != 'gestor') {
          return Response(HttpStatus.forbidden, body: '{"error": "Acesso negado"}', headers: {'content-type': 'application/json'});
        }

        if (userId == id) {
          return Response(HttpStatus.badRequest, body: '{"error": "Você não pode excluir seu próprio usuário administrador"}', headers: {'content-type': 'application/json'});
        }

        final deleted = await _authService.deleteUser(id);
        if (!deleted) {
          return Response(HttpStatus.notFound, body: '{"error": "Usuário não encontrado"}', headers: {'content-type': 'application/json'});
        }

        final forwarded = request.headers['x-forwarded-for'] ?? '127.0.0.1';
        await _auditoriaService.registrarLog(
          usuarioId: userId ?? '',
          acao: 'EXCLUIR_GESTOR',
          detalhes: 'Removeu a conta do gestor de ID $id do sistema',
          ip: forwarded.split(',').first.trim(),
        );

        return Response.ok('{"message": "Gestor removido com sucesso"}', headers: {'content-type': 'application/json'});
      } catch (e) {
        return Response(HttpStatus.internalServerError, body: jsonEncode({'error': e.toString()}), headers: {'content-type': 'application/json'});
      }
    });

    // Confirmar e-mail de cadastro
    router.post('/confirm-email', (Request request) async {
      try {
        final payload = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
        final token = payload['token'] as String?;

        if (token == null || token.isEmpty) {
          return Response(HttpStatus.badRequest, body: '{"error": "Token obrigatório"}', headers: {'content-type': 'application/json'});
        }

        final success = await _authService.confirmarEmail(token);
        if (!success) {
          return Response(HttpStatus.badRequest, body: '{"error": "Token inválido ou expirado"}', headers: {'content-type': 'application/json'});
        }

        return Response.ok('{"message": "E-mail confirmado com sucesso. Sua conta está ativa!"}', headers: {'content-type': 'application/json'});
      } catch (e) {
        return Response(HttpStatus.badRequest, body: jsonEncode({'error': e.toString()}), headers: {'content-type': 'application/json'});
      }
    });

    // Solicitar recuperação de senha
    router.post('/forgot-password', (Request request) async {
      try {
        final payload = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
        final email = payload['email'] as String?;

        if (email == null || email.isEmpty) {
          return Response(HttpStatus.badRequest, body: '{"error": "E-mail obrigatório"}', headers: {'content-type': 'application/json'});
        }

        final success = await _authService.solicitarRecuperacao(email);
        // Retornamos OK mesmo se o e-mail não existir por questões de segurança (impedir user enumeration),
        // mas informamos ao cliente a mensagem padrão de envio.
        return Response.ok('{"message": "Se o e-mail estiver cadastrado, um link de recuperação foi enviado."}', headers: {'content-type': 'application/json'});
      } catch (e) {
        return Response(HttpStatus.badRequest, body: jsonEncode({'error': e.toString()}), headers: {'content-type': 'application/json'});
      }
    });

    // Redefinir a senha com o token
    router.post('/reset-password', (Request request) async {
      try {
        final payload = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
        final token = payload['token'] as String?;
        final newPassword = payload['new_password'] as String?;

        if (token == null || newPassword == null || newPassword.length < 6) {
          return Response(HttpStatus.badRequest, body: '{"error": "Token e nova senha (mínimo 6 caracteres) são obrigatórios"}', headers: {'content-type': 'application/json'});
        }

        final success = await _authService.redefinirSenha(token, newPassword);
        if (!success) {
          return Response(HttpStatus.badRequest, body: '{"error": "Token inválido ou expirado"}', headers: {'content-type': 'application/json'});
        }

        return Response.ok('{"message": "Senha redefinida com sucesso!"}', headers: {'content-type': 'application/json'});
      } catch (e) {
        return Response(HttpStatus.badRequest, body: jsonEncode({'error': e.toString()}), headers: {'content-type': 'application/json'});
      }
    });

    return router;
  }
}
