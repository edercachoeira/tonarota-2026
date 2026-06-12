import 'dart:ui';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:tonarota_shared/tonarota_shared.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/api_service.dart';
import 'dart:convert';

class MerchantLayout extends StatefulWidget {
  final Widget child;
  const MerchantLayout({super.key, required this.child});

  @override
  State<MerchantLayout> createState() => MerchantLayoutState();
}

class MerchantLayoutState extends State<MerchantLayout> {
  final ApiService _api = ApiService();
  Estabelecimento? _estabelecimento;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    loadEstabelecimento();
  }

  Future<void> loadEstabelecimento() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    if (user == null) return;

    try {
      final response = await _api.get('/v1/estabelecimentos');
      if (response.statusCode == 200) {
        final list = (jsonDecode(response.body) as List)
            .map((e) => Estabelecimento.fromJson(e as Map<String, dynamic>))
            .toList();
        
        final myEst = list.firstWhere(
          (element) => element.usuarioId == user.id,
          orElse: () => throw Exception('Estabelecimento não encontrado.'),
        );

        setState(() {
          _estabelecimento = myEst;
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Erro ao carregar dados do estabelecimento.';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erro: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 950;
    final currentRoute = GoRouterState.of(context).matchedLocation;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight;
    final secondaryColor = isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight;
    final borderColor = isDark ? AppTheme.borderDark : AppTheme.borderLight;

    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryTeal),
        ),
      );
    }

    // Provedor interno para os filhos acessarem o estabelecimento atualizado
    return Provider<Estabelecimento?>.value(
      value: _estabelecimento,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: isMobile
            ? AppBar(
                title: Text(_estabelecimento?.nomeFantasia ?? 'Painel Lojista'),
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
        drawer: isMobile
            ? Drawer(
                child: _buildSidebarContent(
                  context,
                  currentRoute,
                  auth,
                  primaryColor,
                  secondaryColor,
                  borderColor,
                  isDark,
                ),
              )
            : null,
        body: Stack(
          children: [
            // Background Luxury Tech
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [const Color(0xFF0D1117), const Color(0xFF070A0F), const Color(0xFF0D1117)]
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
                  color: AppTheme.primaryTeal.withOpacity(isDark ? 0.12 : 0.06),
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
                  color: AppTheme.secondaryAmber.withOpacity(isDark ? 0.06 : 0.03),
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
            
            // Content Row
            SafeArea(
              child: Row(
                children: [
                  if (!isMobile)
                    _buildSidebar(
                      context,
                      currentRoute,
                      auth,
                      primaryColor,
                      secondaryColor,
                      borderColor,
                      isDark,
                    ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
                      child: widget.child,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar(
    BuildContext context,
    String currentRoute,
    AuthProvider auth,
    Color primaryColor,
    Color secondaryColor,
    Color borderColor,
    bool isDark,
  ) {
    return Container(
      width: 280,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A).withOpacity(0.85) : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: _buildSidebarContent(
            context,
            currentRoute,
            auth,
            primaryColor,
            secondaryColor,
            borderColor,
            isDark,
          ),
        ),
      ),
    );
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
    final isPremium = _estabelecimento?.plano == 'premium';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
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
            'MENU LOJISTA',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: secondaryColor.withOpacity(0.6),
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 12),

        _AnimatedSidebarItem(
          icon: Icons.dashboard_rounded,
          label: 'Dashboard',
          route: '/merchant/dashboard',
          isSelected: currentRoute == '/merchant/dashboard',
        ),
        _AnimatedSidebarItem(
          icon: Icons.storefront_rounded,
          label: 'Meu Perfil',
          route: '/merchant/perfil',
          isSelected: currentRoute == '/merchant/perfil',
        ),
        _AnimatedSidebarItem(
          icon: isPremium ? Icons.restaurant_menu_rounded : Icons.lock_outline_rounded,
          label: isPremium ? 'Catálogo Digital' : 'Catálogo (Bloqueado)',
          route: '/merchant/catalogo',
          isSelected: currentRoute == '/merchant/catalogo',
          accentColor: isPremium ? null : AppTheme.secondaryAmber,
        ),

        const Spacer(),
        
        // Footer Info & Logout
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: borderColor.withOpacity(0.5))),
          ),
          child: Column(
            children: [
              // Badge do Plano
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isPremium 
                      ? AppTheme.primaryTeal.withOpacity(0.15) 
                      : Colors.grey.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isPremium ? '💎 PLANO PREMIUM' : '✉️ PLANO GRATUITO',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isPremium ? AppTheme.primaryTeal : secondaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              _AnimatedSidebarItem(
                icon: Icons.public_rounded,
                label: 'Ver Site',
                route: '/',
                isSelected: false,
                isCompact: true,
                onTapOverride: () => html.window.open('/', '_blank'),
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

class _AnimatedSidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final String route;
  final bool isSelected;
  final bool isCompact;
  final bool isDestructive;
  final Color? accentColor;
  final VoidCallback? onTapOverride;

  const _AnimatedSidebarItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.isSelected,
    this.isCompact = false,
    this.isDestructive = false,
    this.accentColor,
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
    
    final baseColor = widget.isDestructive 
        ? Colors.redAccent 
        : (widget.accentColor ?? AppTheme.primaryTeal);
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
          transform: Matrix4.identity()..translate(_isHovering && !widget.isSelected ? 4.0 : 0.0),
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
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    color: _isHovering && !widget.isSelected ? baseColor : textColor,
                    fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: widget.isCompact ? 13 : 14,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
