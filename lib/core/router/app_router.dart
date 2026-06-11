import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../features/auth/login_view.dart';
import '../../features/admin/admin_layout.dart';
import '../../features/admin/dashboard_view.dart';
import '../../features/admin/balnearios_view.dart';
import '../../features/admin/categorias_view.dart';
import '../../features/admin/gestores_view.dart';
import '../../features/admin/perfil_view.dart';
import '../../features/admin/auditoria_view.dart';
import '../../features/auth/confirmacao_email_view.dart';
import '../../features/auth/recuperacao_senha_view.dart';
import '../../features/public/home_view.dart';
import '../../features/merchant/merchant_layout.dart';
import '../../features/merchant/merchant_dashboard_view.dart';
import '../../features/merchant/merchant_perfil_view.dart';
import '../../features/merchant/merchant_catalogo_view.dart';
import '../../features/merchant/register_view.dart';

class AppRouter {
  final AuthProvider authProvider;

  AppRouter(this.authProvider);

  late final GoRouter router = GoRouter(
    initialLocation: '/',
    refreshListenable: authProvider,
    redirect: (BuildContext context, GoRouterState state) {
      final isAuthenticated = authProvider.isAuthenticated;
      final isLoggingIn = state.matchedLocation == '/login';
      final isAdminArea = state.matchedLocation.startsWith('/admin');
      final isMerchantArea = state.matchedLocation.startsWith('/merchant') && state.matchedLocation != '/merchant/register';

      // Redireciona para /login se tentar acessar área restrita sem autenticar
      if ((isAdminArea || isMerchantArea) && !isAuthenticated) {
        return '/login';
      }

      // Redireciona para o dashboard correto se logado e tentar acessar o /login
      if (isAuthenticated && isLoggingIn) {
        final role = authProvider.currentUser?.role;
        if (role == 'gestor') {
          return '/admin';
        } else if (role == 'estabelecimento') {
          return '/merchant';
        }
        return '/';
      }

      // Proteção de roles cruzadas
      if (isAuthenticated) {
        final role = authProvider.currentUser?.role;
        if (isAdminArea && role != 'gestor') {
          return role == 'estabelecimento' ? '/merchant' : '/';
        }
        if (isMerchantArea && role != 'estabelecimento') {
          return role == 'gestor' ? '/admin' : '/';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeView(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginView(),
      ),
      GoRoute(
        path: '/merchant/register',
        builder: (context, state) => const RegisterView(),
      ),
      GoRoute(
        path: '/confirm-email',
        builder: (context, state) {
          final token = state.uri.queryParameters['token'] ?? '';
          return ConfirmacaoEmailView(token: token);
        },
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const RecuperacaoSenhaView(isReset: false),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) {
          final token = state.uri.queryParameters['token'] ?? '';
          return RecuperacaoSenhaView(isReset: true, token: token);
        },
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
          GoRoute(
            path: '/admin/gestores',
            builder: (context, state) => const GestoresView(),
          ),
          GoRoute(
            path: '/admin/perfil',
            builder: (context, state) => const PerfilView(),
          ),
          GoRoute(
            path: '/admin/auditoria',
            builder: (context, state) => const AuditoriaView(),
          ),
        ],
      ),
      ShellRoute(
        builder: (context, state, child) {
          return MerchantLayout(child: child);
        },
        routes: [
          GoRoute(
            path: '/merchant',
            redirect: (context, state) => '/merchant/dashboard',
          ),
          GoRoute(
            path: '/merchant/dashboard',
            builder: (context, state) => const MerchantDashboardView(),
          ),
          GoRoute(
            path: '/merchant/perfil',
            builder: (context, state) => const MerchantPerfilView(),
          ),
          GoRoute(
            path: '/merchant/catalogo',
            builder: (context, state) => const MerchantCatalogoView(),
          ),
        ],
      ),
    ],
  );
}
