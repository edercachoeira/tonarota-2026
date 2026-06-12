import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tonarota_shared/tonarota_shared.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/image_crop_dialog.dart';
import '../../core/providers/auth_provider.dart';

class EstabelecimentosView extends StatefulWidget {
  const EstabelecimentosView({super.key});

  @override
  State<EstabelecimentosView> createState() => _EstabelecimentosViewState();
}

class _EstabelecimentosViewState extends State<EstabelecimentosView> {
  final ApiService _apiService = ApiService();
  List<Estabelecimento> _estabelecimentos = [];
  List<Balneario> _balnearios = [];
  List<Categoria> _categorias = [];
  List<Usuario> _merchantUsers = [];
  
  bool _isLoading = false;
  String? _error;

  // Filtros
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'Todos';
  String _selectedPlano = 'Todos';
  String _selectedBalnearioId = 'Todos';

  List<Estabelecimento> get _filteredEstabelecimentos {
    return _estabelecimentos.where((e) {
      final q = _searchController.text.toLowerCase();
      final matchesSearch = e.nomeFantasia.toLowerCase().contains(q) ||
          e.documento.toLowerCase().contains(q);

      final matchesStatus = _selectedStatus == 'Todos' ||
          e.status.toLowerCase() == _selectedStatus.toLowerCase();

      final matchesPlano = _selectedPlano == 'Todos' ||
          e.plano.toLowerCase() == _selectedPlano.toLowerCase();

      final matchesBalneario = _selectedBalnearioId == 'Todos' ||
          e.balnearioId == _selectedBalnearioId;

      return matchesSearch && matchesStatus && matchesPlano && matchesBalneario;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final Future<void> fEst = _fetchEstabelecimentos();
      final Future<void> fBal = _fetchBalnearios();
      final Future<void> fCat = _fetchCategorias();
      final Future<void> fUsr = _fetchMerchantUsers();

      await Future.wait([fEst, fBal, fCat, fUsr]);
    } catch (e) {
      setState(() {
        _error = 'Erro ao carregar dados do servidor.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchEstabelecimentos() async {
    final res = await _apiService.get('/v1/estabelecimentos');
    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body) as List;
      _estabelecimentos = data.map((json) => Estabelecimento.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      throw Exception();
    }
  }

  Future<void> _fetchBalnearios() async {
    final res = await _apiService.get('/v1/balnearios');
    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body) as List;
      _balnearios = data.map((json) => Balneario.fromJson(json as Map<String, dynamic>)).toList();
    }
  }

  Future<void> _fetchCategorias() async {
    final res = await _apiService.get('/v1/categorias');
    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body) as List;
      _categorias = data.map((json) => Categoria.fromJson(json as Map<String, dynamic>)).toList();
    }
  }

  Future<void> _fetchMerchantUsers() async {
    final res = await _apiService.get('/v1/auth/usuarios/estabelecimento');
    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body) as List;
      _merchantUsers = data.map((json) => Usuario.fromJson(json as Map<String, dynamic>)).toList();
    }
  }

  String _getBalnearioName(String id) {
    final bal = _balnearios.firstWhere((b) => b.id == id, orElse: () => Balneario(id: '', nome: 'Desconhecido', municipio: '', estado: '', descricao: '', imagemCapaUrl: '', ativo: false, createdAt: DateTime.now(), updatedAt: DateTime.now()));
    return bal.nome;
  }

  String _getCategoriaName(String id) {
    final cat = _categorias.firstWhere((c) => c.id == id, orElse: () => Categoria(id: '', nome: 'Sem Categoria', icone: '', descricao: '', ordem: 0, parentId: null, ativo: false));
    return cat.nome;
  }

  Future<void> _updateStatus(Estabelecimento est, String newStatus) async {
    try {
      final payload = est.toJson();
      payload['status'] = newStatus;

      final res = await _apiService.put('/v1/estabelecimentos/${est.id}', payload);
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status de "${est.nomeFantasia}" atualizado para ${newStatus.toUpperCase()}.')),
        );
        _fetchInitialData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao atualizar status do estabelecimento.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro de conexão ao atualizar status.')),
      );
    }
  }

  Future<void> _updatePlano(Estabelecimento est, String newPlano) async {
    try {
      final payload = est.toJson();
      payload['plano'] = newPlano;

      final res = await _apiService.put('/v1/estabelecimentos/${est.id}', payload);
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Plano de "${est.nomeFantasia}" atualizado para ${newPlano.toUpperCase()}.')),
        );
        _fetchInitialData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao atualizar plano.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro de conexão ao atualizar plano.')),
      );
    }
  }

  Future<void> _deleteEstabelecimento(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Tem certeza que deseja remover este estabelecimento? Todos os produtos do catálogo vinculados a ele também serão afetados.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
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
        final res = await _apiService.delete('/v1/estabelecimentos/$id');
        if (res.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Estabelecimento excluído com sucesso.')),
          );
          _fetchInitialData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao excluir estabelecimento.')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro de conexão ao excluir.')),
        );
      }
    }
  }

  void _showFormModal({Estabelecimento? est}) {
    final formKey = GlobalKey<FormState>();
    final nomeFantasiaController = TextEditingController(text: est?.nomeFantasia ?? '');
    final documentoController = TextEditingController(text: est?.documento ?? '');
    final enderecoController = TextEditingController(text: est?.endereco ?? '');
    final telefoneController = TextEditingController(text: est?.telefone ?? '');
    final whatsappController = TextEditingController(text: est?.whatsapp ?? '');
    final instagramController = TextEditingController(text: est?.instagram ?? '');
    final descricaoController = TextEditingController(text: est?.descricao ?? '');
    final logomarcaController = TextEditingController(text: est?.logomarcaUrl ?? '');

    String? selectedBalnearioId = est?.balnearioId ?? (_balnearios.isNotEmpty ? _balnearios.first.id : null);
    String? selectedCategoriaId = est?.categoriaId ?? (_categorias.isNotEmpty ? _categorias.first.id : null);
    String? selectedUsuarioId = est?.usuarioId ?? (_merchantUsers.isNotEmpty ? _merchantUsers.first.id : null);
    
    String plano = est?.plano ?? 'gratuito';
    String status = est?.status ?? 'pendente';
    
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;

            return AlertDialog(
              title: Text(est == null ? 'Novo Estabelecimento' : 'Editar Estabelecimento'),
              content: Container(
                width: 600,
                constraints: const BoxConstraints(maxHeight: 650),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (est == null) ...[
                          DropdownButtonFormField<String>(
                            value: selectedUsuarioId,
                            decoration: const InputDecoration(
                              labelText: 'Usuário Lojista Relacionado',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            items: _merchantUsers.map((u) {
                              return DropdownMenuItem(
                                value: u.id,
                                child: Text('${u.nome} (${u.email})'),
                              );
                            }).toList(),
                            onChanged: (val) => setModalState(() => selectedUsuarioId = val),
                            validator: (val) => val == null ? 'Selecione o usuário lojista.' : null,
                          ),
                          const SizedBox(height: 16),
                        ],
                        TextFormField(
                          controller: nomeFantasiaController,
                          decoration: const InputDecoration(
                            labelText: 'Nome Fantasia',
                            prefixIcon: Icon(Icons.storefront_outlined),
                          ),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Insira o nome fantasia.' : null,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: documentoController,
                                decoration: const InputDecoration(
                                  labelText: 'Documento (CPF / CNPJ)',
                                  prefixIcon: Icon(Icons.badge_outlined),
                                ),
                                validator: (val) => val == null || val.trim().isEmpty ? 'Insira o documento.' : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: enderecoController,
                                decoration: const InputDecoration(
                                  labelText: 'Endereço',
                                  prefixIcon: Icon(Icons.location_on_outlined),
                                ),
                                validator: (val) => val == null || val.trim().isEmpty ? 'Insira o endereço.' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: telefoneController,
                                decoration: const InputDecoration(
                                  labelText: 'Telefone',
                                  prefixIcon: Icon(Icons.phone_outlined),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: whatsappController,
                                decoration: const InputDecoration(
                                  labelText: 'WhatsApp',
                                  prefixIcon: Icon(Icons.chat_bubble_outline),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: instagramController,
                          decoration: const InputDecoration(
                            labelText: 'Instagram (Link ou @)',
                            prefixIcon: Icon(Icons.camera_alt_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: descricaoController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Descrição Institucional',
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: selectedBalnearioId,
                                decoration: const InputDecoration(labelText: 'Balneário'),
                                items: _balnearios.map((b) {
                                  return DropdownMenuItem(value: b.id, child: Text(b.nome));
                                }).toList(),
                                onChanged: (val) => setModalState(() => selectedBalnearioId = val),
                                validator: (val) => val == null ? 'Selecione o balneário.' : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: selectedCategoriaId,
                                decoration: const InputDecoration(labelText: 'Categoria'),
                                items: _categorias.map((c) {
                                  return DropdownMenuItem(value: c.id, child: Text(c.nome));
                                }).toList(),
                                onChanged: (val) => setModalState(() => selectedCategoriaId = val),
                                validator: (val) => val == null ? 'Selecione a categoria.' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: plano,
                                decoration: const InputDecoration(labelText: 'Plano'),
                                items: const [
                                  DropdownMenuItem(value: 'gratuito', child: Text('Gratuito')),
                                  DropdownMenuItem(value: 'premium', child: Text('Premium')),
                                ],
                                onChanged: (val) => setModalState(() => plano = val ?? 'gratuito'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: status,
                                decoration: const InputDecoration(labelText: 'Status'),
                                items: const [
                                  DropdownMenuItem(value: 'pendente', child: Text('Pendente')),
                                  DropdownMenuItem(value: 'ativo', child: Text('Ativo')),
                                  DropdownMenuItem(value: 'suspenso', child: Text('Suspenso')),
                                ],
                                onChanged: (val) => setModalState(() => status = val ?? 'pendente'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        // Logomarca Upload & Preview
                        Text(
                          'Logomarca do Estabelecimento',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 120,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: logomarcaController.text.isNotEmpty
                                ? Image.network(
                                    logomarcaController.text,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Center(
                                        child: Icon(Icons.broken_image_outlined, size: 40, color: Colors.grey),
                                      );
                                    },
                                  )
                                : const Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.storefront_outlined, size: 36, color: Colors.grey),
                                        SizedBox(height: 6),
                                        Text('Sem logomarca selecionada', style: TextStyle(color: Colors.grey, fontSize: 11)),
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
                                title: 'Logomarca (1:1)',
                                aspectRatio: 1.0,
                                onUploadSuccess: (url) {
                                  setModalState(() {
                                    logomarcaController.text = url;
                                  });
                                },
                              ),
                            );
                          },
                          icon: const Icon(Icons.cloud_upload_outlined, size: 16),
                          label: const Text('Carregar e Cortar Imagem'),
                        ),
                      ],
                    ),
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
                            'usuario_id': selectedUsuarioId,
                            'balneario_id': selectedBalnearioId,
                            'categoria_id': selectedCategoriaId,
                            'nome_fantasia': nomeFantasiaController.text.trim(),
                            'documento': documentoController.text.trim(),
                            'endereco': enderecoController.text.trim(),
                            'telefone': telefoneController.text.trim(),
                            'whatsapp': whatsappController.text.trim(),
                            'instagram': instagramController.text.trim(),
                            'descricao': descricaoController.text.trim(),
                            'logomarca_url': logomarcaController.text.trim(),
                            'plano': plano,
                            'status': status,
                            'horarios': est?.horarios ?? {},
                          };

                          try {
                            final response = est == null
                                ? await _apiService.post('/v1/estabelecimentos', body)
                                : await _apiService.put('/v1/estabelecimentos/${est.id}', body);

                            if (response.statusCode == 200 || response.statusCode == 201) {
                              Navigator.pop(context);
                              _fetchInitialData();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Estabelecimento salvo com sucesso.')),
                              );
                            } else {
                              final err = jsonDecode(response.body)['error'] ?? 'Erro ao salvar.';
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(err)),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight;
    final secondaryColor = isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight;
    final borderColor = isDark ? AppTheme.borderDark : AppTheme.borderLight;
    final cardBg = isDark ? AppTheme.surfaceDark : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Topo / Título & Ação de Novo
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gestão de Estabelecimentos',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryColor),
                ),
                const SizedBox(height: 6),
                Text(
                  'Aprove cadastros, gerencie planos e modere os lojistas do Tô Na Rota.',
                  style: TextStyle(fontSize: 14, color: secondaryColor),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: () => _showFormModal(),
              icon: const Icon(Icons.add_business_rounded, size: 20),
              label: const Text('Adicionar Lojista'),
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final useVerticalLayout = constraints.maxWidth < 850;

                final searchField = TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar por nome fantasia ou CNPJ/CPF...',
                    prefixIcon: const Icon(Icons.search, color: AppTheme.primaryTeal),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (val) => setState(() {}),
                );

                final balnearioDropdown = DropdownButtonFormField<String>(
                  value: _selectedBalnearioId,
                  decoration: InputDecoration(
                    labelText: 'Balneário',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  items: [
                    const DropdownMenuItem(value: 'Todos', child: Text('Todos')),
                    ..._balnearios.map((b) => DropdownMenuItem(value: b.id, child: Text(b.nome))),
                  ],
                  onChanged: (val) => setState(() => _selectedBalnearioId = val ?? 'Todos'),
                );

                final planoDropdown = DropdownButtonFormField<String>(
                  value: _selectedPlano,
                  decoration: InputDecoration(
                    labelText: 'Plano',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Todos', child: Text('Todos')),
                    DropdownMenuItem(value: 'gratuito', child: Text('Gratuito')),
                    DropdownMenuItem(value: 'premium', child: Text('Premium')),
                  ],
                  onChanged: (val) => setState(() => _selectedPlano = val ?? 'Todos'),
                );

                final statusDropdown = DropdownButtonFormField<String>(
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
                    DropdownMenuItem(value: 'pendente', child: Text('Pendente')),
                    DropdownMenuItem(value: 'ativo', child: Text('Ativo')),
                    DropdownMenuItem(value: 'suspenso', child: Text('Suspenso')),
                  ],
                  onChanged: (val) => setState(() => _selectedStatus = val ?? 'Todos'),
                );

                if (useVerticalLayout) {
                  return Column(
                    children: [
                      searchField,
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: balnearioDropdown),
                          const SizedBox(width: 12),
                          Expanded(child: planoDropdown),
                          const SizedBox(width: 12),
                          Expanded(child: statusDropdown),
                        ],
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: searchField,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: balnearioDropdown,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: planoDropdown,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: statusDropdown,
                    ),
                  ],
                );
              },
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
                          ElevatedButton(onPressed: _fetchInitialData, child: const Text('Tentar Novamente')),
                        ],
                      ),
                    )
                  : _estabelecimentos.isEmpty
                      ? Center(
                          child: Text('Nenhum lojista cadastrado.', style: TextStyle(color: secondaryColor)),
                        )
                      : _filteredEstabelecimentos.isEmpty
                          ? Center(
                              child: Text('Nenhum estabelecimento corresponde aos filtros.', style: TextStyle(color: secondaryColor)),
                            )
                          : Card(
                              color: cardBg,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: borderColor),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: ListView.separated(
                                  itemCount: _filteredEstabelecimentos.length,
                                  separatorBuilder: (context, index) => Divider(color: borderColor, height: 1),
                                  itemBuilder: (context, index) {
                                    final item = _filteredEstabelecimentos[index];
                                    
                                    // Visualização de Cores conforme Status e Plano
                                    final isPremium = item.plano.toLowerCase() == 'premium';
                                    final statusLower = item.status.toLowerCase();
                                    
                                    Color statusColor = Colors.grey;
                                    if (statusLower == 'ativo') statusColor = Colors.green;
                                    if (statusLower == 'pendente') statusColor = Colors.orange;
                                    if (statusLower == 'suspenso') statusColor = Colors.red;

                                    return ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                      leading: Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryTeal.withOpacity(0.05),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: borderColor),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: item.logomarcaUrl.isNotEmpty
                                              ? Image.network(
                                                  item.logomarcaUrl,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.storefront, color: AppTheme.primaryTeal),
                                                )
                                              : const Icon(Icons.storefront, color: AppTheme.primaryTeal),
                                        ),
                                      ),
                                      title: Row(
                                        children: [
                                          Text(
                                            item.nomeFantasia,
                                            style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 15),
                                          ),
                                          const SizedBox(width: 12),
                                          // Plano Pill
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: isPremium ? AppTheme.secondaryAmber.withOpacity(0.15) : Colors.grey.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: isPremium ? AppTheme.secondaryAmber : Colors.transparent,
                                                width: 1,
                                              ),
                                            ),
                                            child: Text(
                                              item.plano.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: isPremium ? AppTheme.secondaryAmber : secondaryColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      subtitle: Padding(
                                        padding: const EdgeInsets.only(top: 4.0),
                                        child: Text(
                                          '🏝️ ${_getBalnearioName(item.balnearioId)} • 🏷️ ${_getCategoriaName(item.categoriaId)} • 📞 ${item.telefone.isNotEmpty ? item.telefone : "Sem Telefone"}',
                                          style: TextStyle(color: secondaryColor, fontSize: 13),
                                        ),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Status Pill
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: statusColor.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              item.status.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: statusColor,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          
                                          // Ações Rápidas (Aprovar / Suspender / Plano)
                                          if (statusLower == 'pendente')
                                            Tooltip(
                                              message: 'Aprovar Estabelecimento',
                                              child: IconButton(
                                                icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.green),
                                                onPressed: () => _updateStatus(item, 'ativo'),
                                              ),
                                            ),
                                          if (statusLower == 'ativo')
                                            Tooltip(
                                              message: 'Suspender Estabelecimento',
                                              child: IconButton(
                                                icon: const Icon(Icons.block_rounded, color: Colors.orange),
                                                onPressed: () => _updateStatus(item, 'suspenso'),
                                              ),
                                            ),
                                          if (statusLower == 'suspenso')
                                            Tooltip(
                                              message: 'Reativar Estabelecimento',
                                              child: IconButton(
                                                icon: const Icon(Icons.play_circle_outline_rounded, color: Colors.green),
                                                onPressed: () => _updateStatus(item, 'ativo'),
                                              ),
                                            ),
                                            
                                          // Alternar Plano rápido
                                          Tooltip(
                                            message: isPremium ? 'Alterar para Gratuito' : 'Alterar para Premium',
                                            child: IconButton(
                                              icon: Icon(
                                                isPremium ? Icons.star_rounded : Icons.star_border_rounded,
                                                color: AppTheme.secondaryAmber,
                                              ),
                                              onPressed: () => _updatePlano(item, isPremium ? 'gratuito' : 'premium'),
                                            ),
                                          ),
                                          
                                          const SizedBox(width: 8),
                                          const VerticalDivider(width: 1, indent: 10, endIndent: 10),
                                          const SizedBox(width: 8),

                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryTeal),
                                            onPressed: () => _showFormModal(est: item),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                                            onPressed: () => _deleteEstabelecimento(item.id),
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
