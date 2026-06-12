import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:tonarota_shared/tonarota_shared.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';

class CategoriasView extends StatefulWidget {
  const CategoriasView({super.key});

  @override
  State<CategoriasView> createState() => _CategoriasViewState();
}

class _CategoriasViewState extends State<CategoriasView> {
  final ApiService _apiService = ApiService();
  List<Categoria> _categorias = [];
  bool _isLoading = false;
  String? _error;

  // Filtros
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'Todos';

  List<Categoria> get _filteredCategorias {
    return _categorias.where((c) {
      final matchesSearch = c.nome.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          (c.descricao != null && c.descricao!.toLowerCase().contains(_searchController.text.toLowerCase()));
      
      final matchesStatus = _selectedStatus == 'Todos' ||
          (_selectedStatus == 'Ativos' && c.ativo) ||
          (_selectedStatus == 'Inativos' && !c.ativo);

      return matchesSearch && matchesStatus;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _fetchCategorias();
  }

  Future<void> _fetchCategorias() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await _apiService.get('/v1/categorias');
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body) as List;
        setState(() {
          _categorias = data.map((json) => Categoria.fromJson(json as Map<String, dynamic>)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Erro do servidor ao carregar categorias.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erro ao se conectar ao servidor.';
        _isLoading = false;
      });
    }
  }

  void _showFormModal({Categoria? categoria}) {
    final formKey = GlobalKey<FormState>();
    final nomeController = TextEditingController(text: categoria?.nome ?? '');
    final iconeController = TextEditingController(text: categoria?.icone ?? '');
    final descricaoController = TextEditingController(text: categoria?.descricao ?? '');
    final ordemController = TextEditingController(text: (categoria?.ordem ?? 0).toString());
    String? parentId = categoria?.parentId;
    bool ativo = categoria?.ativo ?? true;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text(categoria == null ? 'Criar Categoria' : 'Editar Categoria'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nomeController,
                        decoration: const InputDecoration(labelText: 'Nome da Categoria'),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Insira o nome.' : null,
                      ),
                      const SizedBox(height: 16),
                      // ─── Seletor Visual de Ícone ───────────────────
                      _IconPickerField(
                        currentValue: iconeController.text,
                        onChanged: (val) => setModalState(() {
                          iconeController.text = val;
                        }),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: descricaoController,
                        decoration: const InputDecoration(labelText: 'Descrição'),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: ordemController,
                        decoration: const InputDecoration(labelText: 'Ordem de Exibição'),
                        keyboardType: TextInputType.number,
                        validator: (val) => val == null || int.tryParse(val) == null ? 'Insira um número.' : null,
                      ),
                      const SizedBox(height: 16),
                      // Dropdown de categoria pai
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Categoria Pai (Opcional)'),
                        value: parentId,
                        items: [
                          const DropdownMenuItem<String>(value: null, child: Text('Nenhuma (Categoria Raiz)')),
                          ..._categorias
                              .where((c) => c.id != categoria?.id) // Não pode ser pai de si mesma
                              .map((c) => DropdownMenuItem<String>(
                                    value: c.id,
                                    child: Text(c.nome),
                                  )),
                        ],
                        onChanged: (val) => setModalState(() => parentId = val),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Categoria Ativa'),
                        value: ativo,
                        onChanged: (val) => setModalState(() => ativo = val),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;

                          setModalState(() => isSaving = true);

                          final body = {
                            'nome': nomeController.text,
                            'icone': iconeController.text,
                            'descricao': descricaoController.text,
                            'ordem': int.tryParse(ordemController.text) ?? 0,
                            'parent_id': parentId,
                            'ativo': ativo,
                          };

                          try {
                            final response = categoria == null
                                ? await _apiService.post('/v1/categorias', body)
                                : await _apiService.put('/v1/categorias/${categoria.id}', body);

                            if (response.statusCode == 200 || response.statusCode == 201) {
                              Navigator.pop(context);
                              _fetchCategorias();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Erro ao salvar categoria.')),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Erro de conexão ao salvar.')),
                            );
                          } finally {
                            setModalState(() => isSaving = false);
                          }
                        },
                  child: isSaving
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteCategoria(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Tem certeza que deseja excluir permanentemente esta categoria?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Não')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final res = await _apiService.delete('/v1/categorias/$id');
        if (res.statusCode == 200) {
          _fetchCategorias();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Não foi possível excluir a categoria.')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro de conexão ao excluir.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight;
    final secondaryColor = isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight;
    final borderColor = isDark ? AppTheme.borderDark : AppTheme.borderLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Lista de Categorias',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
            ),
            ElevatedButton.icon(
              onPressed: () => _showFormModal(),
              icon: const Icon(Icons.add),
              label: const Text('Adicionar Categoria'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Barra de Filtros
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: borderColor),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar por nome...',
                      prefixIcon: const Icon(Icons.search, color: AppTheme.primaryTeal),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (val) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Todos', child: Text('Todos')),
                      DropdownMenuItem(value: 'Ativos', child: Text('Ativos')),
                      DropdownMenuItem(value: 'Inativos', child: Text('Inativos')),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedStatus = val ?? 'Todos';
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (_isLoading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (_error != null)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _fetchCategorias, child: const Text('Tentar Novamente')),
                ],
              ),
            ),
          )
        else if (_categorias.isEmpty)
          Expanded(
            child: Center(
              child: Text('Nenhuma categoria cadastrada no sistema.', style: TextStyle(color: secondaryColor)),
            ),
          )
        else if (_filteredCategorias.isEmpty)
          Expanded(
            child: Center(
              child: Text('Nenhuma categoria corresponde aos filtros selecionados.', style: TextStyle(color: secondaryColor)),
            ),
          )
        else
          Expanded(
            child: Card(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: ListView.separated(
                  itemCount: _filteredCategorias.length,
                  separatorBuilder: (context, index) => Divider(color: borderColor, height: 1),
                  itemBuilder: (context, index) {
                    final item = _filteredCategorias[index];
                    final parent = item.parentId != null
                        ? _categorias.firstWhere((c) => c.id == item.parentId, orElse: () => item)
                        : null;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryTeal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _kAvailableIcons[item.icone]?.icon ?? Icons.category_outlined,
                          color: AppTheme.primaryTeal,
                          size: 22,
                        ),
                      ),
                      title: Text(item.nome, style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
                      subtitle: Text(
                        parent != null ? 'Subcategoria de: ${parent.nome}' : 'Categoria Principal (Ordem: ${item.ordem})',
                        style: TextStyle(color: secondaryColor),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: item.ativo ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              item.ativo ? 'ATIVO' : 'INATIVO',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: item.ativo ? Colors.green : Colors.red,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryTeal),
                            onPressed: () => _showFormModal(categoria: item),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () => _deleteCategoria(item.id),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Mapa de ícones disponíveis para categorias ─────────────────
// Chave: valor salvo no backend (string), Valor: {icon, label}
const Map<String, _IconOption> _kAvailableIcons = {
  'beach_access': _IconOption(Icons.beach_access, 'Praia'),
  'pool': _IconOption(Icons.pool, 'Piscina / Lagoa'),
  'waves': _IconOption(Icons.waves, 'Ondas / Mar'),
  'water_drop': _IconOption(Icons.water_drop, 'Água'),
  'waterfall_chart': _IconOption(Icons.waterfall_chart, 'Cachoeira'),
  'hot_tub': _IconOption(Icons.hot_tub, 'Termas'),
  'landscape': _IconOption(Icons.landscape, 'Montanha'),
  'forest': _IconOption(Icons.forest, 'Floresta'),
  'park': _IconOption(Icons.park, 'Parque'),
  'nature': _IconOption(Icons.nature, 'Natureza'),
  'nature_people': _IconOption(Icons.nature_people, 'Ecoturismo'),
  'hiking': _IconOption(Icons.hiking, 'Trilha'),
  'terrain': _IconOption(Icons.terrain, 'Terreno'),
  'wb_sunny': _IconOption(Icons.wb_sunny, 'Sol'),
  'spa': _IconOption(Icons.spa, 'Spa'),
  'restaurant': _IconOption(Icons.restaurant, 'Restaurante'),
  'local_cafe': _IconOption(Icons.local_cafe, 'Café'),
  'local_bar': _IconOption(Icons.local_bar, 'Bar'),
  'fastfood': _IconOption(Icons.fastfood, 'Fast Food'),
  'bakery_dining': _IconOption(Icons.bakery_dining, 'Padaria'),
  'icecream': _IconOption(Icons.icecream, 'Sorveteria'),
  'local_pizza': _IconOption(Icons.local_pizza, 'Pizzaria'),
  'hotel': _IconOption(Icons.hotel, 'Hotel'),
  'cottage': _IconOption(Icons.cottage, 'Chalé / Pousada'),
  'house': _IconOption(Icons.house, 'Casa'),
  'storefront': _IconOption(Icons.storefront, 'Loja'),
  'shopping_bag': _IconOption(Icons.shopping_bag, 'Compras'),
  'local_gas_station': _IconOption(Icons.local_gas_station, 'Posto'),
  'local_hospital': _IconOption(Icons.local_hospital, 'Hospital'),
  'local_pharmacy': _IconOption(Icons.local_pharmacy, 'Farmácia'),
  'directions_boat': _IconOption(Icons.directions_boat, 'Barco'),
  'pedal_bike': _IconOption(Icons.pedal_bike, 'Bicicleta'),
  'surfing': _IconOption(Icons.surfing, 'Surf'),
  'kayaking': _IconOption(Icons.kayaking, 'Caiaque'),
  'sports_esports': _IconOption(Icons.sports_esports, 'Games'),
  'music_note': _IconOption(Icons.music_note, 'Música'),
  'theater_comedy': _IconOption(Icons.theater_comedy, 'Teatro'),
  'camera_alt': _IconOption(Icons.camera_alt, 'Foto'),
  'explore': _IconOption(Icons.explore, 'Explorar'),
  'place': _IconOption(Icons.place, 'Local'),
  'map': _IconOption(Icons.map, 'Mapa'),
  'pets': _IconOption(Icons.pets, 'Animais'),
  'child_care': _IconOption(Icons.child_care, 'Crianças'),
  'accessibility': _IconOption(Icons.accessibility, 'Acessibilidade'),
  'star': _IconOption(Icons.star, 'Destaque'),
  'favorite': _IconOption(Icons.favorite, 'Favorito'),
  'category': _IconOption(Icons.category, 'Categoria'),
  'local_activity': _IconOption(Icons.local_activity, 'Atividade'),
  'attractions': _IconOption(Icons.attractions, 'Atração'),
  'festival': _IconOption(Icons.festival, 'Festival'),
  'nightlife': _IconOption(Icons.nightlife, 'Vida Noturna'),
  'church': _IconOption(Icons.church, 'Igreja'),
  'museum': _IconOption(Icons.museum, 'Museu'),
  'stadium': _IconOption(Icons.stadium, 'Estádio'),
};

class _IconOption {
  final IconData icon;
  final String label;
  const _IconOption(this.icon, this.label);
}

// ─── Widget de Seleção de Ícone ──────────────────────────────────
class _IconPickerField extends StatelessWidget {
  final String currentValue;
  final ValueChanged<String> onChanged;

  const _IconPickerField({
    required this.currentValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentOption = _kAvailableIcons[currentValue];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ícone da Categoria',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white60 : Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _showIconPickerDialog(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryTeal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    currentOption?.icon ?? Icons.add_circle_outline,
                    color: AppTheme.primaryTeal,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentOption?.label ?? 'Nenhum ícone selecionado',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      if (currentValue.isNotEmpty)
                        Text(
                          currentValue,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showIconPickerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _IconPickerDialog(
        currentValue: currentValue,
        onSelected: (val) {
          onChanged(val);
          Navigator.pop(ctx);
        },
      ),
    );
  }
}

// ─── Dialog com Grid de Ícones ───────────────────────────────────
class _IconPickerDialog extends StatefulWidget {
  final String currentValue;
  final ValueChanged<String> onSelected;

  const _IconPickerDialog({
    required this.currentValue,
    required this.onSelected,
  });

  @override
  State<_IconPickerDialog> createState() => _IconPickerDialogState();
}

class _IconPickerDialogState extends State<_IconPickerDialog> {
  String _searchQuery = '';

  List<MapEntry<String, _IconOption>> get _filteredIcons {
    if (_searchQuery.isEmpty) return _kAvailableIcons.entries.toList();
    final q = _searchQuery.toLowerCase();
    return _kAvailableIcons.entries.where((e) {
      return e.key.contains(q) || e.value.label.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 520),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.emoji_symbols, color: AppTheme.primaryTeal, size: 22),
                const SizedBox(width: 10),
                Text(
                  'Escolha um Ícone',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Busca
            TextField(
              decoration: InputDecoration(
                hintText: 'Buscar ícone...',
                prefixIcon: const Icon(Icons.search, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                isDense: true,
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
            const SizedBox(height: 14),

            // Grid de Ícones
            Expanded(
              child: _filteredIcons.isEmpty
                  ? Center(
                      child: Text(
                        'Nenhum ícone encontrado.',
                        style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                      ),
                    )
                  : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: _filteredIcons.length,
                      itemBuilder: (context, index) {
                        final entry = _filteredIcons[index];
                        final isSelected = entry.key == widget.currentValue;

                        return Tooltip(
                          message: entry.value.label,
                          waitDuration: const Duration(milliseconds: 300),
                          child: InkWell(
                            onTap: () => widget.onSelected(entry.key),
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primaryTeal.withOpacity(0.15)
                                    : isDark
                                        ? const Color(0xFF0F172A)
                                        : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.primaryTeal
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    entry.value.icon,
                                    size: 24,
                                    color: isSelected
                                        ? AppTheme.primaryTeal
                                        : isDark
                                            ? Colors.white54
                                            : Colors.black54,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    entry.value.label,
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      color: isSelected
                                          ? AppTheme.primaryTeal
                                          : isDark
                                              ? Colors.white38
                                              : Colors.black45,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
