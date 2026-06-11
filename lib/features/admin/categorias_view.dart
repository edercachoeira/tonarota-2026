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
                      TextFormField(
                        controller: iconeController,
                        decoration: const InputDecoration(labelText: 'Ícone (Ex: restaurant, hotel)'),
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
        else
          Expanded(
            child: Card(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: ListView.separated(
                  itemCount: _categorias.length,
                  separatorBuilder: (context, index) => Divider(color: borderColor, height: 1),
                  itemBuilder: (context, index) {
                    final item = _categorias[index];
                    final parent = item.parentId != null
                        ? _categorias.firstWhere((c) => c.id == item.parentId, orElse: () => item)
                        : null;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      leading: Icon(
                        item.icone.isNotEmpty ? Icons.category : Icons.category_outlined,
                        color: AppTheme.primaryTeal,
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
