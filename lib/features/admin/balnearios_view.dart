import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:tonarota_shared/tonarota_shared.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/image_crop_dialog.dart';

class BalneariosView extends StatefulWidget {
  const BalneariosView({super.key});

  @override
  State<BalneariosView> createState() => _BalneariosViewState();
}

class _BalneariosViewState extends State<BalneariosView> {
  final ApiService _apiService = ApiService();
  List<Balneario> _balnearios = [];
  bool _isLoading = false;
  String? _error;

  // Filtros
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'Todos';
  String _selectedUf = 'Todos';

  List<Balneario> get _filteredBalnearios {
    return _balnearios.where((b) {
      final matchesSearch = b.nome.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          b.municipio.toLowerCase().contains(_searchController.text.toLowerCase());
      
      final matchesStatus = _selectedStatus == 'Todos' ||
          (_selectedStatus == 'Ativos' && b.ativo) ||
          (_selectedStatus == 'Inativos' && !b.ativo);

      final matchesUf = _selectedUf == 'Todos' || b.estado.toUpperCase() == _selectedUf.toUpperCase();

      return matchesSearch && matchesStatus && matchesUf;
    }).toList();
  }

  List<String> get _availableUfs {
    final ufs = _balnearios.map((b) => b.estado.toUpperCase()).toSet().toList();
    ufs.sort();
    return ['Todos', ...ufs];
  }

  @override
  void initState() {
    super.initState();
    _fetchBalnearios();
  }

  Future<void> _fetchBalnearios() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await _apiService.get('/v1/balnearios');
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body) as List;
        setState(() {
          _balnearios = data.map((json) => Balneario.fromJson(json as Map<String, dynamic>)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Erro do servidor ao carregar balneários.';
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

  void _showFormModal({Balneario? balneario}) {
    final formKey = GlobalKey<FormState>();
    final nomeController = TextEditingController(text: balneario?.nome ?? '');
    final municipioController = TextEditingController(text: balneario?.municipio ?? '');
    final estadoController = TextEditingController(text: balneario?.estado ?? 'SC');
    final descricaoController = TextEditingController(text: balneario?.descricao ?? '');
    final imagemController = TextEditingController(text: balneario?.imagemCapaUrl ?? '');
    bool ativo = balneario?.ativo ?? true;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text(balneario == null ? 'Criar Balneário' : 'Editar Balneário'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nomeController,
                        decoration: const InputDecoration(labelText: 'Nome do Balneário'),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Insira o nome.' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: municipioController,
                              decoration: const InputDecoration(labelText: 'Município'),
                              validator: (val) => val == null || val.trim().isEmpty ? 'Insira o município.' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              controller: estadoController,
                              decoration: const InputDecoration(labelText: 'UF'),
                              maxLength: 2,
                              buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                              validator: (val) => val == null || val.trim().length != 2 ? 'Erro.' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: descricaoController,
                        decoration: const InputDecoration(labelText: 'Descrição Curta'),
                        maxLines: 2,
                      ),
                       const SizedBox(height: 16),
                      // Container de Pré-visualização da Imagem de Capa
                      Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: imagemController.text.isNotEmpty
                              ? Image.network(
                                  imagemController.text,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(
                                      child: Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey),
                                    );
                                  },
                                )
                              : const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.image_outlined, size: 40, color: Colors.grey),
                                      SizedBox(height: 8),
                                      Text(
                                        'Nenhuma imagem de capa selecionada',
                                        style: TextStyle(color: Colors.grey, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => ImageCropDialog(
                              title: 'Imagem de Capa (16:9)',
                              aspectRatio: 16 / 9,
                              onUploadSuccess: (url) {
                                setModalState(() {
                                  imagemController.text = url;
                                });
                              },
                            ),
                          );
                        },
                        icon: const Icon(Icons.crop_outlined),
                        label: const Text('Selecionar e Cortar Imagem'),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Balneário Ativo'),
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
                            'municipio': municipioController.text,
                            'estado': estadoController.text,
                            'descricao': descricaoController.text,
                            'imagem_capa_url': imagemController.text,
                            'ativo': ativo,
                          };

                          try {
                            final response = balneario == null
                                ? await _apiService.post('/v1/balnearios', body)
                                : await _apiService.put('/v1/balnearios/${balneario.id}', body);

                            if (response.statusCode == 200 || response.statusCode == 201) {
                              Navigator.pop(context);
                              _fetchBalnearios();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Erro ao salvar balneário.')),
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

  Future<void> _deleteBalneario(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Tem certeza que deseja excluir permanentemente este balneário?'),
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
        final res = await _apiService.delete('/v1/balnearios/$id');
        if (res.statusCode == 200) {
          _fetchBalnearios();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Não foi possível excluir o balneário.')),
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
              'Lista de Balneários',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
            ),
            ElevatedButton.icon(
              onPressed: () => _showFormModal(),
              icon: const Icon(Icons.add),
              label: const Text('Adicionar Balneário'),
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
                      hintText: 'Buscar por nome ou município...',
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
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    value: _availableUfs.contains(_selectedUf) ? _selectedUf : 'Todos',
                    decoration: InputDecoration(
                      labelText: 'UF',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    items: _availableUfs.map((uf) {
                      return DropdownMenuItem(value: uf, child: Text(uf));
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedUf = val ?? 'Todos';
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
                  ElevatedButton(onPressed: _fetchBalnearios, child: const Text('Tentar Novamente')),
                ],
              ),
            ),
          )
        else if (_balnearios.isEmpty)
          Expanded(
            child: Center(
              child: Text('Nenhum balneário cadastrado no sistema.', style: TextStyle(color: secondaryColor)),
            ),
          )
        else if (_filteredBalnearios.isEmpty)
          Expanded(
            child: Center(
              child: Text('Nenhum balneário corresponde aos filtros selecionados.', style: TextStyle(color: secondaryColor)),
            ),
          )
        else
          Expanded(
            child: Card(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: ListView.separated(
                  itemCount: _filteredBalnearios.length,
                  separatorBuilder: (context, index) => Divider(color: borderColor, height: 1),
                  itemBuilder: (context, index) {
                    final item = _filteredBalnearios[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      title: Text(item.nome, style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
                      subtitle: Text('${item.municipio} - ${item.estado}', style: TextStyle(color: secondaryColor)),
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
                            onPressed: () => _showFormModal(balneario: item),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () => _deleteBalneario(item.id),
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
