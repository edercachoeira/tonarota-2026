import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/auth_service.dart';

class AuthRoutes {
  final AuthService _authService = AuthService();

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

    return router;
  }
}
