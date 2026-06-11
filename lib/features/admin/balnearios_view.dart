import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:tonarota_shared/tonarota_shared.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';

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
    final estadoController = TextEditingController(text: balneario?.estado ?? 'SP');
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
                      TextFormField(
                        controller: imagemController,
                        decoration: const InputDecoration(labelText: 'URL da Imagem de Capa'),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Lista de Balneários',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryLight),
            ),
            ElevatedButton.icon(
              onPressed: () => _showFormModal(),
              icon: const Icon(Icons.add),
              label: const Text('Adicionar Balneário'),
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
                  ElevatedButton(onPressed: _fetchBalnearios, child: const Text('Tentar Novamente')),
                ],
              ),
            ),
          )
        else if (_balnearios.isEmpty)
          const Expanded(
            child: Center(
              child: Text('Nenhum balneário cadastrado no sistema.'),
            ),
          )
        else
          Expanded(
            child: Card(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: ListView.separated(
                  itemCount: _balnearios.length,
                  separatorBuilder: (context, index) => const Divider(color: AppTheme.borderLight, height: 1),
                  itemBuilder: (context, index) {
                    final item = _balnearios[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      title: Text(item.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${item.municipio} - ${item.estado}'),
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
