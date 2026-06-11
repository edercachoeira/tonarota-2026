import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tonarota_shared/tonarota_shared.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/image_crop_dialog.dart';

class MerchantCatalogoView extends StatefulWidget {
  const MerchantCatalogoView({super.key});

  @override
  State<MerchantCatalogoView> createState() => _MerchantCatalogoViewState();
}

class _MerchantCatalogoViewState extends State<MerchantCatalogoView> {
  final ApiService _api = ApiService();
  List<Produto> _produtos = [];
  bool _loading = true;
  String? _errorMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final est = Provider.of<Estabelecimento?>(context);
    if (est != null && est.plano == 'premium') {
      _loadProdutos(est.id);
    } else {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _loadProdutos(String estId) async {
    try {
      final response = await _api.get('/v1/produtos/estabelecimento/$estId');
      if (response.statusCode == 200) {
        final list = (jsonDecode(response.body) as List)
            .map((e) => Produto.fromJson(e as Map<String, dynamic>))
            .toList();

        setState(() {
          _produtos = list;
          _loading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Erro ao carregar catálogo de produtos.';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao conectar ao servidor: $e';
        _loading = false;
      });
    }
  }

  Future<void> _deleteProduto(String id) async {
    final est = Provider.of<Estabelecimento?>(context, listen: false);
    if (est == null) return;

    try {
      final response = await _api.delete('/v1/produtos/$id');
      if (response.statusCode == 200) {
        _loadProdutos(est.id);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao deletar produto.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    }
  }

  void _showFormDialog([Produto? produto]) {
    final est = Provider.of<Estabelecimento?>(context, listen: false);
    if (est == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ProdutoFormDialog(
        estabelecimentoId: est.id,
        produto: produto,
        onSaveSuccess: () {
          _loadProdutos(est.id);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final est = Provider.of<Estabelecimento?>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight;
    final secondaryColor = isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight;
    final borderColor = isDark ? AppTheme.borderDark : AppTheme.borderLight;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    if (est == null) {
      return const Center(child: Text('Nenhum estabelecimento cadastrado para sua conta.'));
    }

    // Se o plano for gratuito, mostra uma interface de bloqueio (Wow factor)
    if (est.plano != 'premium') {
      return _buildLockedView(primaryColor, secondaryColor, isDark);
    }

    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryTeal));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Catálogo de Produtos',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryColor, letterSpacing: -0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  'Gerencie os produtos da sua vitrine digital (${_produtos.length}/30 itens)',
                  style: TextStyle(fontSize: 14, color: secondaryColor),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: () => _showFormDialog(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Adicionar Item'),
            ),
          ],
        ),
        const SizedBox(height: 24),

        if (_errorMessage != null) ...[
          Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent))),
        ] else if (_produtos.isEmpty) ...[
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant_menu_rounded, size: 64, color: secondaryColor.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text(
                    'Seu catálogo está vazio.',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Adicione pratos, produtos ou serviços para seus clientes visualizarem no app.',
                    style: TextStyle(color: secondaryColor, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () => _showFormDialog(),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Cadastrar Primeiro Item'),
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width < 700 ? 1 : (MediaQuery.of(context).size.width < 1200 ? 3 : 4),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: _produtos.length,
              itemBuilder: (context, index) {
                final p = _produtos[index];
                return Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Product Image
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                          child: p.fotoUrl.isNotEmpty
                              ? Image.network(p.fotoUrl, fit: BoxFit.cover)
                              : Container(
                                  color: isDark ? Colors.black26 : Colors.grey[200],
                                  child: const Icon(Icons.photo_outlined, size: 48, color: Colors.grey),
                                ),
                        ),
                      ),
                      // Details
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    p.titulo,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: p.ativo ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    p.ativo ? 'Ativo' : 'Pausado',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: p.ativo ? Colors.green : Colors.grey,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              p.descricao.isNotEmpty ? p.descricao : 'Sem descrição.',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 13, color: secondaryColor),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'R\$ ${p.preco.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.primaryTeal,
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 20),
                                      tooltip: 'Editar',
                                      onPressed: () => _showFormDialog(p),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
                                      tooltip: 'Excluir',
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Excluir Produto'),
                                            content: Text('Tem certeza que deseja excluir "${p.titulo}"?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text('Cancelar'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  _deleteProduto(p.id);
                                                },
                                                style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                                                child: const Text('Excluir'),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLockedView(Color primaryColor, Color secondaryColor, bool isDark) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppTheme.secondaryAmber.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 30,
              offset: const Offset(0, 15),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.secondaryAmber.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_rounded, color: AppTheme.secondaryAmber, size: 48),
            ),
            const SizedBox(height: 24),
            Text(
              'Área Exclusiva Premium',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryColor, letterSpacing: -0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'O Catálogo Digital de Produtos é um recurso reservado para parceiros do Plano Premium.',
              textAlign: TextAlign.center,
              style: TextStyle(color: secondaryColor, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 24),
            // Benefits List
            _buildBenefit('Vitrine com até 30 produtos cadastrados'),
            const SizedBox(height: 8),
            _buildBenefit('Destaque nos resultados de busca'),
            const SizedBox(height: 8),
            _buildBenefit('Carrossel de banners patrocinados na Home'),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // simulated upgrade pitch
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Fazer Upgrade de Plano'),
                    content: const Text(
                      'Para ativar seu catálogo digital e habilitar o plano Premium, '
                      'entre em contato com o gestor do Tô Na Rota via WhatsApp no número (47) 99999-9999.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Entendido'),
                      ),
                    ],
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryAmber,
                foregroundColor: Colors.white,
                shadowColor: AppTheme.secondaryAmber.withOpacity(0.4),
              ),
              child: const Text('Solicitar Upgrade Premium'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefit(String text) {
    return Row(
      children: [
        const Icon(Icons.check_circle_rounded, color: AppTheme.primaryTeal, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}

class _ProdutoFormDialog extends StatefulWidget {
  final String estabelecimentoId;
  final Produto? produto;
  final VoidCallback onSaveSuccess;

  const _ProdutoFormDialog({
    required this.estabelecimentoId,
    this.produto,
    required this.onSaveSuccess,
  });

  @override
  State<_ProdutoFormDialog> createState() => _ProdutoFormDialogState();
}

class _ProdutoFormDialogState extends State<_ProdutoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _api = ApiService();

  late TextEditingController _tituloController;
  late TextEditingController _descricaoController;
  late TextEditingController _precoController;
  late TextEditingController _fotoController;
  late TextEditingController _ordemController;
  bool _ativo = true;

  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tituloController = TextEditingController(text: widget.produto?.titulo ?? '');
    _descricaoController = TextEditingController(text: widget.produto?.descricao ?? '');
    _precoController = TextEditingController(text: widget.produto?.preco.toString() ?? '');
    _fotoController = TextEditingController(text: widget.produto?.fotoUrl ?? '');
    _ordemController = TextEditingController(text: widget.produto?.ordem.toString() ?? '0');
    _ativo = widget.produto?.ativo ?? true;
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _precoController.dispose();
    _fotoController.dispose();
    _ordemController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    final titulo = _tituloController.text.trim();
    final descricao = _descricaoController.text.trim();
    final preco = double.tryParse(_precoController.text.trim()) ?? 0.0;
    final fotoUrl = _fotoController.text.trim();
    final ordem = int.tryParse(_ordemController.text.trim()) ?? 0;

    try {
      final isNew = widget.produto == null;
      final response = isNew
          ? await _api.post('/v1/produtos', {
              'estabelecimento_id': widget.estabelecimentoId,
              'titulo': titulo,
              'descricao': descricao,
              'preco': preco,
              'foto_url': fotoUrl,
              'ordem': ordem,
              'ativo': _ativo,
            })
          : await _api.put('/v1/produtos/${widget.produto!.id}', {
              'titulo': titulo,
              'descricao': descricao,
              'preco': preco,
              'foto_url': fotoUrl,
              'ordem': ordem,
              'ativo': _ativo,
            });

      if (response.statusCode == 201 || response.statusCode == 200) {
        widget.onSaveSuccess();
        if (mounted) Navigator.pop(context);
      } else {
        final err = jsonDecode(response.body)['error'] ?? 'Erro ao salvar produto.';
        throw Exception(err);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.produto == null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: Text(isNew ? 'Adicionar Produto' : 'Editar Produto'),
      content: SizedBox(
        width: 450,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_errorMessage != null) ...[
                  Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent)),
                  const SizedBox(height: 12),
                ],

                // Foto Upload Box
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => ImageCropDialog(
                        title: 'Foto do Produto (1:1)',
                        aspectRatio: 1.0,
                        onUploadSuccess: (url) {
                          setState(() {
                            _fotoController.text = url;
                          });
                        },
                      ),
                    );
                  },
                  child: Container(
                    height: 160,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black26 : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.5)),
                      image: _fotoController.text.isNotEmpty
                          ? DecorationImage(image: NetworkImage(_fotoController.text), fit: BoxFit.cover)
                          : null,
                    ),
                    child: _fotoController.text.isEmpty
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined, size: 48, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('Adicionar Foto do Produto', style: TextStyle(color: Colors.grey, fontSize: 13)),
                            ],
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _tituloController,
                  decoration: const InputDecoration(labelText: 'Título do Produto'),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Insira um título.' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _descricaoController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Descrição (opcional)'),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _precoController,
                        decoration: const InputDecoration(labelText: 'Preço (R\$)', prefixText: 'R\$ '),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (val) => val == null || double.tryParse(val) == null ? 'Insira um preço válido.' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _ordemController,
                        decoration: const InputDecoration(labelText: 'Ordem de Exibição'),
                        keyboardType: TextInputType.number,
                        validator: (val) => val == null || int.tryParse(val) == null ? 'Insira um número.' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                SwitchListTile(
                  title: const Text('Disponível / Ativo'),
                  subtitle: const Text('O produto aparecerá no catálogo se estiver ativo'),
                  value: _ativo,
                  activeColor: AppTheme.primaryTeal,
                  onChanged: (val) {
                    setState(() {
                      _ativo = val;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                )
              : const Text('Salvar'),
        ),
      ],
    );
  }
}
