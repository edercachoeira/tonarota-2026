import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../features/auth/login_view.dart';
import '../../features/admin/admin_layout.dart';
import '../../features/admin/dashboard_view.dart';
import '../../features/admin/balnearios_view.dart';
import '../../features/admin/categorias_view.dart';

class AppRouter {
  final AuthProvider authProvider;

  AppRouter(this.authProvider);

  late final GoRouter router = GoRouter(
    initialLocation: '/login',
    refreshListenable: authProvider,
    redirect: (BuildContext context, GoRouterState state) {
      final isAuthenticated = authProvider.isAuthenticated;
      final isLoggingIn = state.matchedLocation == '/login';

      // Redireciona para /login se tentar acessar área restrita sem autenticar
      if (!isAuthenticated && !isLoggingIn) {
        return '/login';
      }

      // Redireciona para o dashboard se logado e tentar acessar o /login
      if (isAuthenticated && isLoggingIn) {
        return '/admin';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginView(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return AdminLayout(child: child);
        },
        routes: [
          GoRoute(
            path: '/admin',
            redirect: (context, state) => '/admin/dashboard',
          ),
          GoRoute(
            path: '/admin/dashboard',
            builder: (context, state) => const DashboardView(),
          ),
          GoRoute(
            path: '/admin/balnearios',
            builder: (context, state) => const BalneariosView(),
          ),
          GoRoute(
            path: '/admin/categorias',
            builder: (context, state) => const CategoriasView(),
          ),
        ],
      ),
    ],
  );
}
