import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/api_service.dart';

class ModeracaoAvaliacoesView extends StatefulWidget {
  const ModeracaoAvaliacoesView({super.key});

  @override
  State<ModeracaoAvaliacoesView> createState() => _ModeracaoAvaliacoesViewState();
}

class _ModeracaoAvaliacoesViewState extends State<ModeracaoAvaliacoesView> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _allReviews = [];
  String _searchQuery = '';
  int? _selectedRatingFilter;
  String _selectedStatusFilter = 'Todos'; // 'Todos', 'aprovada', 'oculta'

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiService.get('/v1/avaliacoes/admin');
      if (response.statusCode == 200) {
        setState(() {
          _allReviews = jsonDecode(response.body) as List;
          _isLoading = false;
        });
      } else {
        _showError('Erro ao carregar avaliações.');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      _showError('Erro de conexão: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(String id, String newStatus) async {
    try {
      final response = await _apiService.put(
        '/v1/avaliacoes/admin/$id/status',
        {'status': newStatus},
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == 'aprovada'
                  ? 'Avaliação aprovada com sucesso!'
                  : 'Avaliação ocultada com sucesso!',
            ),
            backgroundColor: newStatus == 'aprovada' ? Colors.green : Colors.blueGrey,
          ),
        );
        _loadReviews();
      } else {
        _showError('Erro ao atualizar moderação.');
      }
    } catch (e) {
      _showError('Erro de rede ao moderar: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  List<dynamic> get _filteredReviews {
    return _allReviews.where((item) {
      final matchesSearch = item['comentario']
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          item['estabelecimento_nome']
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());

      final matchesRating = _selectedRatingFilter == null || item['nota'] == _selectedRatingFilter;

      final matchesStatus = _selectedStatusFilter == 'Todos' || item['status'] == _selectedStatusFilter;

      return matchesSearch && matchesRating && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight;
    final secondaryColor = isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight;
    final cardBg = isDark ? AppTheme.surfaceDark : Colors.white;

    final filtered = _filteredReviews;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Filtros e Ferramentas de Busca
        Card(
          color: cardBg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Linha de Cima: Busca e Status
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 800;
                    final searchField = Expanded(
                      flex: isMobile ? 0 : 2,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.backgroundDark : Colors.grey.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                        ),
                        child: TextField(
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val;
                            });
                          },
                          style: TextStyle(color: primaryColor),
                          decoration: InputDecoration(
                            hintText: 'Buscar por comentário ou estabelecimento...',
                            hintStyle: TextStyle(color: secondaryColor.withOpacity(0.6)),
                            prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryTeal),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                    );

                    final statusFilter = SizedBox(
                      width: isMobile ? double.infinity : 200,
                      child: DropdownButtonFormField<String>(
                        value: _selectedStatusFilter,
                        decoration: InputDecoration(
                          labelText: 'Status de Moderação',
                          labelStyle: TextStyle(color: secondaryColor),
                          filled: true,
                          fillColor: isDark ? AppTheme.backgroundDark : Colors.grey.withOpacity(0.08),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                          ),
                        ),
                        dropdownColor: cardBg,
                        style: TextStyle(color: primaryColor),
                        items: const [
                          DropdownMenuItem(value: 'Todos', child: Text('Todos os Status')),
                          DropdownMenuItem(value: 'aprovada', child: Text('Aprovadas')),
                          DropdownMenuItem(value: 'oculta', child: Text('Ocultadas')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedStatusFilter = val;
                            });
                          }
                        },
                      ),
                    );

                    if (isMobile) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          searchField,
                          const SizedBox(height: 12),
                          statusFilter,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        searchField,
                        const SizedBox(width: 16),
                        statusFilter,
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Linha de Baixo: Filtro de Notas (Estrelas)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: const Text('Todas as Notas'),
                          selected: _selectedRatingFilter == null,
                          onSelected: (_) {
                            setState(() {
                              _selectedRatingFilter = null;
                            });
                          },
                          selectedColor: AppTheme.primaryTeal,
                          backgroundColor: isDark ? AppTheme.backgroundDark : Colors.grey.withOpacity(0.08),
                          labelStyle: TextStyle(
                            color: _selectedRatingFilter == null ? Colors.white : primaryColor,
                          ),
                        ),
                      ),
                      ...List.generate(5, (index) {
                        final starCount = 5 - index;
                        final isSelected = _selectedRatingFilter == starCount;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Row(
                              children: [
                                Text('$starCount'),
                                const SizedBox(width: 4),
                                const Icon(Icons.star_rounded, color: AppTheme.secondaryAmber, size: 16),
                              ],
                            ),
                            selected: isSelected,
                            onSelected: (_) {
                              setState(() {
                                _selectedRatingFilter = starCount;
                              });
                            },
                            selectedColor: AppTheme.primaryTeal,
                            backgroundColor: isDark ? AppTheme.backgroundDark : Colors.grey.withOpacity(0.08),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : primaryColor,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Listagem
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.rate_review_outlined, size: 64, color: secondaryColor.withOpacity(0.3)),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhuma avaliação encontrada.',
                            style: TextStyle(fontSize: 18, color: secondaryColor, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final id = item['id'] as String;
                        final estNome = item['estabelecimento_nome'] as String;
                        final nota = item['nota'] as int;
                        final comentario = item['comentario'] as String;
                        final status = item['status'] as String;
                        final dateStr = item['created_at'].toString().split('T').first;

                        final isApproved = status == 'aprovada';

                        return Card(
                          color: cardBg,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isApproved
                                  ? Colors.green.withOpacity(0.3)
                                  : Colors.redAccent.withOpacity(0.3),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            estNome,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: primaryColor,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: isApproved
                                                  ? Colors.green.withOpacity(0.1)
                                                  : Colors.redAccent.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              isApproved ? 'Aprovada' : 'Ocultada',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: isApproved ? Colors.green : Colors.redAccent,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          ...List.generate(5, (starIdx) {
                                            return Icon(
                                              Icons.star_rounded,
                                              color: starIdx < nota
                                                  ? AppTheme.secondaryAmber
                                                  : Colors.grey.withOpacity(0.3),
                                              size: 20,
                                            );
                                          }),
                                          const SizedBox(width: 12),
                                          Text(
                                            dateStr,
                                            style: TextStyle(fontSize: 12, color: secondaryColor),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        comentario.isNotEmpty
                                            ? '"$comentario"'
                                            : 'Sem comentário de texto.',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontStyle: comentario.isNotEmpty
                                              ? FontStyle.italic
                                              : FontStyle.normal,
                                          color: primaryColor.withOpacity(0.9),
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Ações rápidas de moderação
                                isApproved
                                    ? Tooltip(
                                        message: 'Ocultar comentário',
                                        child: ElevatedButton.icon(
                                          onPressed: () => _updateStatus(id, 'oculta'),
                                          icon: const Icon(Icons.visibility_off_rounded, size: 16),
                                          label: const Text('Ocultar'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blueGrey.withOpacity(0.1),
                                            foregroundColor: Colors.blueGrey,
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                        ),
                                      )
                                    : Tooltip(
                                        message: 'Aprovar comentário',
                                        child: ElevatedButton.icon(
                                          onPressed: () => _updateStatus(id, 'aprovada'),
                                          icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                                          label: const Text('Aprovar'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green.withOpacity(0.1),
                                            foregroundColor: Colors.green,
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                        ),
                                      ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
