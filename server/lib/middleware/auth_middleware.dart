import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

final String jwtSecret = Platform.environment['JWT_SECRET'] ?? 'dev_tonarota_secret_key_2026_super_secure';

/// Middleware que decodifica o JWT e injeta os dados do usuário no contexto da Request.
Middleware authMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      final authHeader = request.headers['Authorization'];
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return innerHandler(request); // Prossegue sem usuário autenticado
      }

      final token = authHeader.substring(7);
      try {
        final jwt = JWT.verify(token, SecretKey(jwtSecret));
        final payload = jwt.payload as Map<String, dynamic>;

        // Injeta as informações do usuário logado no contexto da requisição
        final newContext = Map<String, Object>.from(request.context);
        newContext['user_id'] = payload['id'] as String;
        newContext['user_email'] = payload['email'] as String;
        newContext['user_role'] = payload['role'] as String;

        final newRequest = request.change(context: newContext);
        return await innerHandler(newRequest);
      } catch (e) {
        // Token inválido ou expirado
        return Response(HttpStatus.unauthorized, body: '{"error": "Não autorizado: Token inválido ou expirado"}', headers: {
          'content-type': 'application/json',
        });
      }
    };
  };
}

/// Helper para exigir autenticação geral.
Middleware requireAuth() {
  return (Handler innerHandler) {
    return (Request request) async {
      if (request.context['user_id'] == null) {
        return Response(HttpStatus.unauthorized, body: '{"error": "Acesso negado: Autenticação necessária"}', headers: {
          'content-type': 'application/json',
        });
      }
      return await innerHandler(request);
    };
  };
}

/// Helper para exigir roles específicas.
Middleware requireRole(List<String> roles) {
  return (Handler innerHandler) {
    return (Request request) async {
      final userId = request.context['user_id'];
      final userRole = request.context['user_role'] as String?;

      if (userId == null) {
        return Response(HttpStatus.unauthorized, body: '{"error": "Acesso negado: Autenticação necessária"}', headers: {
          'content-type': 'application/json',
        });
      }

      if (userRole == null || !roles.contains(userRole)) {
        return Response(HttpStatus.forbidden, body: '{"error": "Acesso negado: Permissão insuficiente"}', headers: {
          'content-type': 'application/json',
        });
      }

      return await innerHandler(request);
    };
  };
}
