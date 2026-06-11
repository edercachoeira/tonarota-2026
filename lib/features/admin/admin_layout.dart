import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight;
    final secondaryColor = isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight;
    final borderColor = isDark ? AppTheme.borderDark : AppTheme.borderLight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: isMobile
          ? AppBar(
              title: const Text('Tô Na Rota'),
              backgroundColor: (isDark ? AppTheme.surfaceDark : Colors.white).withOpacity(0.8),
              flexibleSpace: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(color: Colors.transparent),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.home_outlined),
                  tooltip: 'Ir para o Site Público',
                  onPressed: () => context.go('/'),
                ),
              ],
            )
          : null,
      drawer: isMobile ? Drawer(child: _buildSidebarContent(context, currentRoute, auth, primaryColor, secondaryColor, borderColor, isDark)) : null,
      body: Stack(
        children: [
          // Background Decorativo "Wow Factor" (Luxury Tech)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF0F172A), const Color(0xFF060B14), const Color(0xFF0F172A)]
                      : [const Color(0xFFF8FAFC), const Color(0xFFE2E8F0), const Color(0xFFF1F5F9)],
                ),
              ),
            ),
          ),
          // Blur Blobs
          Positioned(
            top: -150,
            left: -150,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                color: AppTheme.primaryTeal.withOpacity(isDark ? 0.15 : 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -200,
            right: -100,
            child: Container(
              width: 600,
              height: 600,
              decoration: BoxDecoration(
                color: AppTheme.secondaryAmber.withOpacity(isDark ? 0.08 : 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
              child: Container(color: Colors.transparent),
            ),
          ),
          
          // Main Content
          SafeArea(
            child: Row(
              children: [
                // Floating Sidebar
                if (!isMobile)
                  Container(
                    width: 280,
                    margin: const EdgeInsets.fromLTRB(24, 24, 12, 24),
                    decoration: BoxDecoration(
                      color: (isDark ? AppTheme.surfaceDark : Colors.white).withOpacity(isDark ? 0.6 : 0.8),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(isDark ? 0.05 : 0.5), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                        child: _buildSidebarContent(context, currentRoute, auth, primaryColor, secondaryColor, borderColor, isDark),
                      ),
                    ),
                  ),

                // Área do Conteúdo Principal
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Floating Header Superior
                      if (!isMobile)
                        Container(
                          height: 76,
                          margin: const EdgeInsets.fromLTRB(12, 24, 24, 0),
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          decoration: BoxDecoration(
                            color: (isDark ? AppTheme.surfaceDark : Colors.white).withOpacity(isDark ? 0.6 : 0.8),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white.withOpacity(isDark ? 0.05 : 0.5), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _getRouteTitle(currentRoute),
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: primaryColor,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            user?.nome ?? 'Administrador',
                                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: primaryColor),
                                          ),
                                          Text(
                                            user?.role.toUpperCase() ?? 'GESTOR',
                                            style: const TextStyle(fontSize: 10, color: AppTheme.primaryTeal, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 16),
                                      Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: const LinearGradient(
                                            colors: [AppTheme.primaryTeal, AppTheme.secondaryAmber],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppTheme.primaryTeal.withOpacity(0.3),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: CircleAvatar(
                                          radius: 20,
                                          backgroundColor: isDark ? AppTheme.backgroundDark : Colors.white,
                                          child: Text(
                                            user?.nome.substring(0, 1).toUpperCase() ?? 'A',
                                            style: TextStyle(color: primaryColor, fontWeight: FontWeight.w800, fontSize: 16),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      // Conteúdo dinâmico da View
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(isMobile ? 16 : 12, isMobile ? 16 : 24, isMobile ? 16 : 24, 24),
                          child: child, // View em si (Cards, Tabelas) que já terão o design arredondado por causa do AppTheme
                        ),
                      ),
                    ],
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
    if (route.contains('/dashboard')) return 'Visão Geral';
    if (route.contains('/balnearios')) return 'Gestão de Balneários';
    if (route.contains('/categorias')) return 'Gestão de Categorias';
    if (route.contains('/gestores')) return 'Equipe & Gestores';
    if (route.contains('/auditoria')) return 'Auditoria do Sistema';
    if (route.contains('/perfil')) return 'Meu Perfil';
    return 'Administração';
  }

  Widget _buildSidebarContent(
    BuildContext context,
    String currentRoute,
    AuthProvider auth,
    Color primaryColor,
    Color secondaryColor,
    Color borderColor,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Cabeçalho da Sidebar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryTeal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Text(
                  '🏝️',
                  style: TextStyle(fontSize: 22),
                ),
                SizedBox(width: 8),
                Text(
                  'Tô Na Rota',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryTeal,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'MENU PRINCIPAL',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: secondaryColor.withOpacity(0.6), letterSpacing: 1.5),
          ),
        ),
        const SizedBox(height: 12),
        
        // Links de Navegação
        _AnimatedSidebarItem(
          icon: Icons.grid_view_rounded,
          label: 'Dashboard',
          route: '/admin/dashboard',
          isSelected: currentRoute == '/admin/dashboard',
        ),
        _AnimatedSidebarItem(
          icon: Icons.map_rounded,
          label: 'Balneários',
          route: '/admin/balnearios',
          isSelected: currentRoute == '/admin/balnearios',
        ),
        _AnimatedSidebarItem(
          icon: Icons.category_rounded,
          label: 'Categorias',
          route: '/admin/categorias',
          isSelected: currentRoute == '/admin/categorias',
        ),

        if (auth.currentUser?.role == 'gestor') ...[
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'ADMINISTRAÇÃO',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: secondaryColor.withOpacity(0.6), letterSpacing: 1.5),
            ),
          ),
          const SizedBox(height: 12),
          _AnimatedSidebarItem(
            icon: Icons.shield_rounded,
            label: 'Gestores',
            route: '/admin/gestores',
            isSelected: currentRoute == '/admin/gestores',
          ),
          _AnimatedSidebarItem(
            icon: Icons.history_rounded,
            label: 'Auditoria',
            route: '/admin/auditoria',
            isSelected: currentRoute == '/admin/auditoria',
          ),
        ],

        const Spacer(),
        
        // Rodapé
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: borderColor.withOpacity(0.5))),
          ),
          child: Column(
            children: [
              _AnimatedSidebarItem(
                icon: Icons.account_circle_rounded,
                label: 'Minha Conta',
                route: '/admin/perfil',
                isSelected: currentRoute == '/admin/perfil',
                isCompact: true,
              ),
              const SizedBox(height: 4),
              _AnimatedSidebarItem(
                icon: Icons.public_rounded,
                label: 'Ver Site',
                route: '/',
                isSelected: false,
                isCompact: true,
              ),
              const SizedBox(height: 4),
              _AnimatedSidebarItem(
                icon: Icons.logout_rounded,
                label: 'Sair',
                route: '',
                isSelected: false,
                isCompact: true,
                isDestructive: true,
                onTapOverride: () => auth.logout(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Custom Widget para Animação Premium de Hover no Menu
class _AnimatedSidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final String route;
  final bool isSelected;
  final bool isCompact;
  final bool isDestructive;
  final VoidCallback? onTapOverride;

  const _AnimatedSidebarItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.isSelected,
    this.isCompact = false,
    this.isDestructive = false,
    this.onTapOverride,
  });

  @override
  State<_AnimatedSidebarItem> createState() => _AnimatedSidebarItemState();
}

class _AnimatedSidebarItemState extends State<_AnimatedSidebarItem> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight;
    
    final baseColor = widget.isDestructive ? Colors.redAccent : AppTheme.primaryTeal;
    final iconColor = widget.isSelected ? Colors.white : (widget.isDestructive ? Colors.redAccent : primaryColor.withOpacity(0.7));
    final textColor = widget.isSelected ? Colors.white : (widget.isDestructive ? Colors.redAccent : primaryColor);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          if (widget.onTapOverride != null) {
            widget.onTapOverride!();
          } else {
            if (Navigator.canPop(context)) Navigator.pop(context); // Mobile Drawer
            context.go(widget.route);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutQuart,
          margin: EdgeInsets.symmetric(horizontal: widget.isCompact ? 0 : 16, vertical: 4),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: widget.isCompact ? 10 : 14),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? baseColor
                : (_isHovering ? baseColor.withOpacity(isDark ? 0.15 : 0.08) : Colors.transparent),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isSelected 
                  ? baseColor 
                  : (_isHovering ? baseColor.withOpacity(0.3) : Colors.transparent),
              width: 1,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: baseColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          transform: Matrix4.identity()..translate(_isHovering && !widget.isSelected ? 4.0 : 0.0), // Animação sutil no eixo X
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                transform: Matrix4.identity()..scale(_isHovering ? 1.1 : 1.0),
                child: Icon(
                  widget.icon,
                  color: _isHovering && !widget.isSelected ? baseColor : iconColor,
                  size: widget.isCompact ? 18 : 20,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                widget.label,
                style: TextStyle(
                  color: _isHovering && !widget.isSelected ? baseColor : textColor,
                  fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.w600,
                  fontSize: widget.isCompact ? 13 : 14,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
