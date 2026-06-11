import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';

class AdminLayout extends StatelessWidget {
  final Widget child;

  const AdminLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isMobile = MediaQuery.of(context).size.width < 900;
    final user = auth.currentUser;
    final currentRoute = GoRouterState.of(context).matchedLocation;

    return Scaffold(
      appBar: isMobile
          ? AppBar(
              title: const Text('Painel Tô Na Rota'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.exit_to_app),
                  onPressed: () {
                    auth.logout();
                  },
                ),
              ],
            )
          : null,
      drawer: isMobile ? Drawer(child: _buildSidebarContent(context, currentRoute, auth)) : null,
      body: Row(
        children: [
          // Sidebar fixa para telas grandes
          if (!isMobile)
            Container(
              width: 260,
              decoration: const BoxDecoration(
                border: Border(right: BorderSide(color: AppTheme.borderLight, width: 1)),
              ),
              child: _buildSidebarContent(context, currentRoute, auth),
            ),
          // Área do Conteúdo Principal
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header superior apenas para telas grandes
                if (!isMobile)
                  Container(
                    height: 70,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppTheme.borderLight, width: 1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _getRouteTitle(currentRoute),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryLight),
                        ),
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppTheme.primaryTeal.withOpacity(0.1),
                              child: Text(
                                user?.nome.substring(0, 1).toUpperCase() ?? 'A',
                                style: const TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.nome ?? 'Administrador',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimaryLight),
                                ),
                                Text(
                                  user?.role.toUpperCase() ?? 'GESTOR',
                                  style: const TextStyle(fontSize: 11, color: AppTheme.primaryTeal, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                // Conteúdo dinâmico da View
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getRouteTitle(String route) {
    if (route.contains('/dashboard')) return 'Painel Geral';
    if (route.contains('/balnearios')) return 'Gerenciar Balneários';
    if (route.contains('/categorias')) return 'Gerenciar Categorias';
    return 'Administração';
  }

  Widget _buildSidebarContent(BuildContext context, String currentRoute, AuthProvider auth) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Cabeçalho da Sidebar
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Icon(Icons.explore, color: Theme.of(context).colorScheme.primary, size: 28),
              const SizedBox(width: 10),
              Text(
                'Tô Na Rota',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        const Divider(color: AppTheme.borderLight, height: 1),
        const SizedBox(height: 16),
        // Links de Navegação
        _buildSidebarItem(
          context,
          icon: Icons.dashboard_outlined,
          label: 'Dashboard',
          route: '/admin/dashboard',
          isSelected: currentRoute == '/admin/dashboard',
        ),
        _buildSidebarItem(
          context,
          icon: Icons.beach_access_outlined,
          label: 'Balneários',
          route: '/admin/balnearios',
          isSelected: currentRoute == '/admin/balnearios',
        ),
        _buildSidebarItem(
          context,
          icon: Icons.category_outlined,
          label: 'Categorias',
          route: '/admin/categorias',
          isSelected: currentRoute == '/admin/categorias',
        ),
        const Spacer(),
        // Rodapé com Logout
        const Divider(color: AppTheme.borderLight, height: 1),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Sair do Painel', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onTap: () {
              auth.logout();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
    required bool isSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? AppTheme.primaryTeal : AppTheme.textSecondaryLight,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.primaryTeal : AppTheme.textPrimaryLight,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        selectedTileColor: AppTheme.primaryTeal.withOpacity(0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () {
          // Se for mobile, fecha o drawer antes de navegar
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
          context.go(route);
        },
      ),
    );
  }
}
