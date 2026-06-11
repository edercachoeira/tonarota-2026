import 'dart:io';
import 'package:shelf/shelf.dart';

/// Middleware de Rate Limiting em memória.
/// Limita requisições por IP de acordo com o tipo de rota:
/// - Máximo de 30 requisições/minuto em rotas de autenticação (`/auth/`)
/// - Máximo de 100 requisições/minuto em outras rotas públicas e gerais
Middleware rateLimitMiddleware() {
  final Map<String, List<DateTime>> requestHistory = {};

  return (Handler innerHandler) {
    return (Request request) async {
      // Obter IP do cliente a partir da conexão HTTP subjacente
      final connInfo = request.context['shelf.io.connection_info'] as HttpConnectionInfo?;
      final clientIp = connInfo?.remoteAddress.address ?? 'unknown_ip';

      final now = DateTime.now();
      final oneMinuteAgo = now.subtract(const Duration(minutes: 1));

      // Inicializa ou limpa histórico do IP
      final ipHistory = requestHistory[clientIp] ?? [];
      // Remove requisições mais antigas que 1 minuto
      final activeRequests = ipHistory.where((dt) => dt.isAfter(oneMinuteAgo)).toList();

      final isAuthRoute = request.url.path.contains('auth/');
      final limit = isAuthRoute ? 30 : 100;

      if (activeRequests.length >= limit) {
        return Response(
          429, // Too Many Requests
          body: '{"error": "Limite de requisições excedido. Tente novamente mais tarde."}',
          headers: {'content-type': 'application/json'},
        );
      }

      // Adiciona a requisição atual ao histórico do IP
      activeRequests.add(now);
      requestHistory[clientIp] = activeRequests;

      return await innerHandler(request);
    };
  };
}
