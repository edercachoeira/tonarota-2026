import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tonarota_shared/tonarota_shared.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/auth_provider.dart';

class GestoresView extends StatefulWidget {
  const GestoresView({super.key});

  @override
  State<GestoresView> createState() => _GestoresViewState();
}

class _GestoresViewState extends State<GestoresView> {
  final ApiService _apiService = ApiService();
  List<Usuario> _gestores = [];
  bool _isLoading = false;
  String? _error;

  // Filtros
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'Todos';

  List<Usuario> get _filteredGestores {
    return _gestores.where((u) {
      final matchesSearch = u.nome.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          u.email.toLowerCase().contains(_searchController.text.toLowerCase());
      
      final matchesStatus = _selectedStatus == 'Todos' ||
          (_selectedStatus == 'Ativos' && u.ativo) ||
          (_selectedStatus == 'Inativos' && !u.ativo);

      return matchesSearch && matchesStatus;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _fetchGestores();
  }

  Future<void> _fetchGestores() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await _apiService.get('/v1/auth/gestores');
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body) as List;
        setState(() {
          _gestores = data.map((json) => Usuario.fromJson(json as Map<String, dynamic>)).toList();
          _isLoading = false;
        });
      } else {
        final errBody = jsonDecode(res.body);
        setState(() {
          _error = errBody['error'] ?? 'Erro ao carregar administradores.';
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

  Future<void> _deleteGestor(String id) async {
    try {
      final res = await _apiService.delete('/v1/auth/gestores/$id');
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Administrador removido com sucesso.')),
        );
        _fetchGestores();
      } else {
        final errBody = jsonDecode(res.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errBody['error'] ?? 'Erro ao remover administrador.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao se conectar ao servidor.')),
      );
    }
  }

  void _showCreateModal() {
    final formKey = GlobalKey<FormState>();
    final nomeController = TextEditingController();
    final emailController = TextEditingController();
    final senhaController = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('Cadastrar Novo Gestor'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nomeController,
                      decoration: const InputDecoration(labelText: 'Nome Completo'),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Insira o nome.' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'E-mail'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Insira o e-mail.';
                        if (!val.contains('@')) return 'E-mail inválido.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: senhaController,
                      decoration: const InputDecoration(labelText: 'Senha (mín. 6 caracteres)'),
                      obscureText: true,
                      validator: (val) => val == null || val.length < 6 ? 'A senha deve conter pelo menos 6 caracteres.' : null,
                    ),
                  ],
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
                          if (formKey.currentState!.validate()) {
                            setModalState(() => isSaving = true);
                            try {
                              final res = await _apiService.post('/v1/auth/register', {
                                'nome': nomeController.text,
                                'email': emailController.text,
                                'password': senhaController.text,
                                'role': 'gestor',
                              });

                              if (res.statusCode == 201) {
                                Navigator.pop(context);
                                _fetchGestores();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Gestor cadastrado com sucesso!')),
                                );
                              } else {
                                final errBody = jsonDecode(res.body);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(errBody['error'] ?? 'Erro ao cadastrar.')),
                                );
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Erro de conexão.')),
                              );
                            } finally {
                              setModalState(() => isSaving = false);
                            }
                          }
                        },
                  child: isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final currentUser = auth.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight;
    final secondaryColor = isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight;
    final cardBg = isDark ? AppTheme.surfaceDark : Colors.white;
    final borderColor = isDark ? AppTheme.borderDark : AppTheme.borderLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Topo / Ações
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gestores do Sistema',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryColor),
                ),
                const SizedBox(height: 6),
                Text(
                  'Cadastre e gerencie administradores do portal Tô Na Rota.',
                  style: TextStyle(fontSize: 14, color: secondaryColor),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: _showCreateModal,
              icon: const Icon(Icons.person_add_rounded, size: 20),
              label: const Text('Cadastrar Gestor'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryTeal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
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
                      hintText: 'Buscar por nome ou e-mail...',
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

        // Listagem
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryTeal))
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                          const SizedBox(height: 16),
                          Text(_error!, style: TextStyle(color: primaryColor, fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ElevatedButton(onPressed: _fetchGestores, child: const Text('Tentar Novamente')),
                        ],
                      ),
                    )
                  : _gestores.isEmpty
                      ? Center(
                          child: Text('Nenhum administrador cadastrado.', style: TextStyle(color: secondaryColor)),
                        )
                      : _filteredGestores.isEmpty
                          ? Center(
                              child: Text('Nenhum gestor corresponde aos filtros selecionados.', style: TextStyle(color: secondaryColor)),
                            )
                          : Card(
                              color: cardBg,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: borderColor),
                              ),
                              child: ListView.separated(
                                padding: const EdgeInsets.all(12),
                                itemCount: _filteredGestores.length,
                                separatorBuilder: (context, index) => Divider(color: borderColor),
                                itemBuilder: (context, index) {
                                  final item = _filteredGestores[index];
                                  final isSelf = item.id == currentUser?.id;

                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: AppTheme.primaryTeal.withOpacity(0.08),
                                      child: Text(
                                        item.nome.substring(0, 1).toUpperCase(),
                                        style: const TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    title: Row(
                                      children: [
                                        Text(item.nome, style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                                        if (isSelf) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppTheme.primaryTeal.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text('Você', style: TextStyle(fontSize: 10, color: AppTheme.primaryTeal, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ],
                                    ),
                                    subtitle: Text(item.email, style: TextStyle(color: secondaryColor)),
                                    trailing: isSelf
                                        ? const IconButton(
                                            icon: Icon(Icons.delete_forever_rounded, color: Colors.grey),
                                            tooltip: 'Você não pode se autoexcluir',
                                            onPressed: null,
                                          )
                                        : IconButton(
                                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                builder: (context) {
                                                  return AlertDialog(
                                                    title: const Text('Remover Administrador'),
                                                    content: Text('Tem certeza que deseja remover o gestor "${item.nome}"? Esta ação é irreversível.'),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () => Navigator.pop(context),
                                                        child: const Text('Cancelar'),
                                                      ),
                                                      ElevatedButton(
                                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                                        onPressed: () {
                                                          Navigator.pop(context);
                                                          _deleteGestor(item.id);
                                                        },
                                                        child: const Text('Excluir'),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                            },
                                          ),
                                  );
                                },
                              ),
                            ),
        ),
      ],
    );
  }
}
