import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/auth_provider.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Todos';
  String _searchQuery = '';

  // Lista mock de balneários para apresentação premium de alta fidelidade
  final List<Map<String, dynamic>> _allBalnearios = [
    {
      'nome': 'Praia da Enseada',
      'categoria': 'Praias',
      'descricao': 'Águas calmas e mornas, ideal para famílias com crianças. Excelente infraestrutura de quiosques.',
      'rating': 4.8,
      'avaliacoes': 124,
      'tags': ['Acessível', 'Quiosques', 'Estacionamento'],
      'image': 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=600&q=80',
    },
    {
      'nome': 'Cachoeira do Salto',
      'categoria': 'Cachoeiras',
      'descricao': 'Uma queda d\'água exuberante de 15 metros com poço natural profundo para banho relaxante.',
      'rating': 4.9,
      'avaliacoes': 86,
      'tags': ['Trilha', 'Natureza', 'Pet Friendly'],
      'image': 'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?auto=format&fit=crop&w=600&q=80',
    },
    {
      'nome': 'Praia Vermelha',
      'categoria': 'Praias',
      'descricao': 'Cercada por costões rochosos e vegetação nativa preservada. Areias de tons avermelhados únicos.',
      'rating': 4.7,
      'avaliacoes': 93,
      'tags': ['Preservada', 'Surf', 'Visual Único'],
      'image': 'https://images.unsplash.com/photo-1519046904884-53103b34b206?auto=format&fit=crop&w=600&q=80',
    },
    {
      'nome': 'Balneário das Termas',
      'categoria': 'Termas',
      'descricao': 'Piscinas de águas termais naturalmente aquecidas, com propriedades terapêuticas e relaxantes.',
      'rating': 4.6,
      'avaliacoes': 150,
      'tags': ['Infraestrutura', 'Restaurante', 'Familiar'],
      'image': 'https://images.unsplash.com/photo-1540555700478-4be289fbecef?auto=format&fit=crop&w=600&q=80',
    },
    {
      'nome': 'Cachoeira Escondida',
      'categoria': 'Cachoeiras',
      'descricao': 'Acesso por trilha moderada na mata fechada. Perfeita para quem busca aventura e sossego absoluto.',
      'rating': 4.9,
      'avaliacoes': 42,
      'tags': ['Trilha Longa', 'Selvagem', 'Aventura'],
      'image': 'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?auto=format&fit=crop&w=600&q=80',
    },
    {
      'nome': 'Praia Grande do Sul',
      'categoria': 'Praias',
      'descricao': 'Extensa faixa de areia dourada e mar aberto com ondas propícias para a prática de surf e esportes.',
      'rating': 4.5,
      'avaliacoes': 210,
      'tags': ['Ducha Pública', 'Surf', 'Ciclovia'],
      'image': 'https://images.unsplash.com/photo-1506929562872-bb421503ef21?auto=format&fit=crop&w=600&q=80',
    },
  ];

  List<Map<String, dynamic>> get _filteredBalnearios {
    return _allBalnearios.where((item) {
      final matchesCategory = _selectedCategory == 'Todos' || item['categoria'] == _selectedCategory;
      final matchesSearch = item['nome'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item['descricao'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item['tags'].any((tag) => tag.toString().toLowerCase().contains(_searchQuery.toLowerCase()));
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight;
    final secondaryColor = isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight;
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- HEADER NAV BAR ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.backgroundDark : Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        '🏝️',
                        style: TextStyle(fontSize: 28),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Tô Na Rota',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryTeal,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          if (auth.isAuthenticated) {
                            context.go('/admin');
                          } else {
                            context.go('/login');
                          }
                        },
                        icon: const Icon(Icons.dashboard_outlined, size: 18),
                        label: Text(auth.isAuthenticated ? 'Ir para o Painel' : 'Acesso do Gestor'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryTeal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // --- HERO SECTION ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                      : [const Color(0xFF0D9488).withOpacity(0.08), const Color(0xFF3B82F6).withOpacity(0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Encontre o seu próximo destino',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Descubra a infraestrutura, rotas e quiosques dos melhores balneários locais.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: secondaryColor,
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Barra de Pesquisa Hero
                  Container(
                    constraints: const BoxConstraints(maxWidth: 600),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryTeal.withOpacity(isDark ? 0.1 : 0.08),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      style: TextStyle(color: primaryColor),
                      decoration: InputDecoration(
                        hintText: 'Buscar praias, cachoeiras, comodidades...',
                        hintStyle: TextStyle(color: secondaryColor.withOpacity(0.7)),
                        prefixIcon: const Icon(Icons.search, color: AppTheme.primaryTeal),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _searchController.clear();
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- CATEGORIES & GRID ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Filtros de Categorias
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['Todos', 'Praias', 'Cachoeiras', 'Termas'].map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: ChoiceChip(
                            label: Text(cat),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedCategory = cat;
                                });
                              }
                            },
                            selectedColor: AppTheme.primaryTeal,
                            backgroundColor: isDark ? AppTheme.surfaceDark : Colors.white,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected
                                    ? AppTheme.primaryTeal
                                    : (isDark ? AppTheme.borderDark : AppTheme.borderLight),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Lista Filtrada / Grid de Destinos
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      int crossAxisCount = 1;
                      if (width >= 900) {
                        crossAxisCount = 3;
                      } else if (width >= 600) {
                        crossAxisCount = 2;
                      }

                      final filtered = _filteredBalnearios;

                      if (filtered.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 64),
                          child: Column(
                            children: [
                              const Icon(Icons.search_off, size: 64, color: AppTheme.primaryTeal),
                              const SizedBox(height: 16),
                              Text(
                                'Nenhum destino encontrado',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tente redefinir sua busca ou alterar a categoria selecionada.',
                                style: TextStyle(color: secondaryColor),
                              ),
                            ],
                          ),
                        );
                      }

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 24,
                          mainAxisSpacing: 24,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          return _buildPremiumCard(context, item, isDark, primaryColor, secondaryColor);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),

            // --- FOOTER ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '🏝️ Tô Na Rota',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryTeal,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Seu guia completo de balneabilidade, quiosques e lazer.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: secondaryColor, fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  Divider(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                  const SizedBox(height: 16),
                  Text(
                    '© 2026 Tô Na Rota. Todos os direitos reservados.',
                    style: TextStyle(color: secondaryColor.withOpacity(0.8), fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumCard(
    BuildContext context,
    Map<String, dynamic> item,
    bool isDark,
    Color primaryColor,
    Color secondaryColor,
  ) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Imagem
          Expanded(
            flex: 5,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  item['image'],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppTheme.primaryTeal.withOpacity(0.1),
                      child: const Icon(Icons.image, color: AppTheme.primaryTeal, size: 48),
                    );
                  },
                ),
                // Badge de Categoria
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryTeal,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      item['categoria'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Informações
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item['nome'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: AppTheme.secondaryAmber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            item['rating'].toString(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            ' (${item['avaliacoes']})',
                            style: TextStyle(
                              color: secondaryColor,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Text(
                      item['descricao'],
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: secondaryColor,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Tags de Comodidades
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: (item['tags'] as List<String>).map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryTeal.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppTheme.primaryTeal.withOpacity(0.12),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            color: AppTheme.primaryTeal,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
