import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:bcrypt/bcrypt.dart';

import '../lib/middleware/auth_middleware.dart';
import '../lib/middleware/rate_limit_middleware.dart';

void main() {
  group('Auth Middleware & JWT Tests', () {
    test('Should sign and verify JWT correctly', () {
      final jwt = JWT({'id': 'user-123', 'role': 'gestor', 'email': 'test@test.com'});
      final token = jwt.sign(SecretKey(jwtSecret), expiresIn: const Duration(hours: 1));

      expect(token, isNotEmpty);

      final decoded = JWT.verify(token, SecretKey(jwtSecret));
      expect(decoded.payload['id'], 'user-123');
      expect(decoded.payload['role'], 'gestor');
    });

    test('Should pass through authMiddleware and inject context if valid token is provided', () async {
      final jwt = JWT({'id': 'user-123', 'role': 'gestor', 'email': 'test@test.com'});
      final token = jwt.sign(SecretKey(jwtSecret));

      final request = Request(
        'GET',
        Uri.parse('http://localhost/api/v1/auth/me'),
        headers: {'Authorization': 'Bearer $token'},
      );

      final middleware = authMiddleware();
      final handler = middleware((Request req) {
        expect(req.context['user_id'], 'user-123');
        expect(req.context['user_role'], 'gestor');
        expect(req.context['user_email'], 'test@test.com');
        return Response.ok('Authenticated');
      });

      final response = await handler(request);
      expect(response.statusCode, HttpStatus.ok);
    });

    test('Should return 401 Unauthorized if invalid token is provided', () async {
      final request = Request(
        'GET',
        Uri.parse('http://localhost/api/v1/auth/me'),
        headers: {'Authorization': 'Bearer invalid_token_here'},
      );

      final middleware = authMiddleware();
      final handler = middleware((Request req) {
        return Response.ok('Authenticated');
      });

      final response = await handler(request);
      expect(response.statusCode, HttpStatus.unauthorized);
    });
  });

  group('Password Hashing Tests', () {
    test('Should hash and verify password securely with BCrypt', () {
      const password = 'my_secure_password';
      final hash = BCrypt.hashpw(password, BCrypt.gensalt());

      expect(hash, isNot(password));
      expect(BCrypt.checkpw(password, hash), isTrue);
      expect(BCrypt.checkpw('wrong_password', hash), isFalse);
    });
  });

  group('Rate Limiting Middleware Tests', () {
    test('Should allow requests within limit and return 429 when threshold exceeded', () async {
      final middleware = rateLimitMiddleware();
      final handler = middleware((Request req) {
        return Response.ok('Allowed');
      });

      // Simula conexões vindas do mesmo IP
      final connInfo = HttpConnectionInfoMock(InternetAddress('127.0.0.1'));
      final context = {'shelf.io.connection_info': connInfo};

      // Rota com limite baixo (/auth/ com 30 req/min)
      final request = Request(
        'POST',
        Uri.parse('http://localhost/api/v1/auth/login'),
        context: context,
      );

      // Envia 30 requisições (dentro do limite)
      for (var i = 0; i < 30; i++) {
        final res = await handler(request);
        expect(res.statusCode, HttpStatus.ok);
      }

      // A 31ª requisição deve ser bloqueada com status 429
      final blockedResponse = await handler(request);
      expect(blockedResponse.statusCode, 429);
    });
  });
}

class HttpConnectionInfoMock implements HttpConnectionInfo {
  @override
  final InternetAddress remoteAddress;
  @override
  final int remotePort = 80;
  @override
  final int localPort = 8080;

  HttpConnectionInfoMock(this.remoteAddress);
}
