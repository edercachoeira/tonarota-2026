import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:tonarota_shared/tonarota_shared.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _api = ApiService();

  final _nomeResponsavelController = TextEditingController();
  final _nomeFantasiaController = TextEditingController();
  final _documentoController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _enderecoController = TextEditingController();

  List<Balneario> _balnearios = [];
  List<Categoria> _categorias = [];
  String? _selectedBalnearioId;
  String? _selectedCategoriaId;

  bool _loadingData = true;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSetupData();
  }

  @override
  void dispose() {
    _nomeResponsavelController.dispose();
    _nomeFantasiaController.dispose();
    _documentoController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _enderecoController.dispose();
    super.dispose();
  }

  Future<void> _loadSetupData() async {
    try {
      final balneariosRes = await _api.get('/v1/balnearios');
      final categoriasRes = await _api.get('/v1/categorias');

      if (balneariosRes.statusCode == 200 && categoriasRes.statusCode == 200) {
        final balList = (jsonDecode(balneariosRes.body) as List)
            .map((e) => Balneario.fromJson(e as Map<String, dynamic>))
            .where((element) => element.ativo)
            .toList();

        final catList = (jsonDecode(categoriasRes.body) as List)
            .map((e) => Categoria.fromJson(e as Map<String, dynamic>))
            .where((element) => element.ativo)
            .toList();

        setState(() {
          _balnearios = balList;
          _categorias = catList;
          _loadingData = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Falha ao buscar dados de configuração.';
          _loadingData = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao conectar ao servidor: $e';
        _loadingData = false;
      });
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBalnearioId == null || _selectedCategoriaId == null) {
      setState(() {
        _errorMessage = 'Selecione o balneário e a categoria do seu comércio.';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      // Step 1: Registrar o usuário com cargo 'estabelecimento'
      final registerRes = await _api.post('/v1/auth/register', {
        'email': _emailController.text.trim(),
        'password': _passwordController.text.trim(),
        'nome': _nomeResponsavelController.text.trim(),
        'role': 'estabelecimento',
      });

      if (registerRes.statusCode != 201) {
        final err = jsonDecode(registerRes.body)['error'] ?? 'Erro no cadastro da conta.';
        throw Exception(err);
      }

      // Step 2: Fazer login imediato para obter o token JWT
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final loggedIn = await auth.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!loggedIn) {
        throw Exception('Falha ao autenticar após cadastro.');
      }

      // Step 3: Criar o estabelecimento associado
      final createEstRes = await _api.post('/v1/estabelecimentos', {
        'estabelecimento_id': null, // O backend irá auto-gerar UUID
        'usuario_id': auth.currentUser?.id,
        'balneario_id': _selectedBalnearioId,
        'categoria_id': _selectedCategoriaId,
        'nome_fantasia': _nomeFantasiaController.text.trim(),
        'documento': _documentoController.text.trim(),
        'endereco': _enderecoController.text.trim(),
        'telefone': _phoneController.text.trim(),
        'whatsapp': _phoneController.text.trim(),
        'plano': 'gratuito',
        'status': 'ativo', // Começa ativo diretamente por comodidade de desenvolvimento local
      });

      if (createEstRes.statusCode != 201) {
        final err = jsonDecode(createEstRes.body)['error'] ?? 'Erro no cadastro do estabelecimento.';
        throw Exception(err);
      }

      if (mounted) {
        // Redireciona para o portal do lojista
        context.go('/merchant');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Background elegante
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                    : [const Color(0xFFF1F5F9), const Color(0xFFE2E8F0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned(
            top: -100,
            right: -100,
            child: CircleAvatar(
              radius: 200,
              backgroundColor: AppTheme.primaryTeal.withOpacity(0.1),
            ),
          ),
          
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 580),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B).withOpacity(0.85) : Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    )
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(36),
                  child: _loadingData
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 48.0),
                            child: CircularProgressIndicator(color: AppTheme.primaryTeal),
                          ),
                        )
                      : Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Header
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('🏝️', style: TextStyle(fontSize: 32)),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Parceria Lojista',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Cadastre seu comércio para aparecer no guia regional',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 32),

                              if (_errorMessage != null) ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],

                              // Form Fields Grid
                              TextFormField(
                                controller: _nomeResponsavelController,
                                decoration: const InputDecoration(
                                  labelText: 'Nome do Responsável / Lojista',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                                validator: (val) => val == null || val.trim().isEmpty ? 'Insira o nome do responsável.' : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _nomeFantasiaController,
                                decoration: const InputDecoration(
                                  labelText: 'Nome Fantasia do Comércio',
                                  prefixIcon: Icon(Icons.storefront_outlined),
                                ),
                                validator: (val) => val == null || val.trim().isEmpty ? 'Insira o nome fantasia.' : null,
                              ),
                              const SizedBox(height: 16),

                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _documentoController,
                                      decoration: const InputDecoration(
                                        labelText: 'CNPJ / CPF',
                                        prefixIcon: Icon(Icons.badge_outlined),
                                      ),
                                      validator: (val) => val == null || val.trim().isEmpty ? 'Insira o documento.' : null,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _phoneController,
                                      decoration: const InputDecoration(
                                        labelText: 'Telefone / WhatsApp',
                                        prefixIcon: Icon(Icons.phone_outlined),
                                      ),
                                      validator: (val) => val == null || val.trim().isEmpty ? 'Insira o telefone.' : null,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              TextFormField(
                                controller: _emailController,
                                decoration: const InputDecoration(
                                  labelText: 'E-mail Comercial',
                                  prefixIcon: Icon(Icons.email_outlined),
                                ),
                                validator: (val) => val == null || val.trim().isEmpty ? 'Insira o e-mail.' : null,
                              ),
                              const SizedBox(height: 16),

                              TextFormField(
                                controller: _passwordController,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: 'Senha de Acesso',
                                  prefixIcon: Icon(Icons.lock_outlined),
                                ),
                                validator: (val) => val == null || val.trim().length < 6 ? 'Senha deve ter no mínimo 6 caracteres.' : null,
                              ),
                              const SizedBox(height: 16),

                              TextFormField(
                                controller: _enderecoController,
                                decoration: const InputDecoration(
                                  labelText: 'Endereço Comercial Completo',
                                  prefixIcon: Icon(Icons.location_on_outlined),
                                ),
                                validator: (val) => val == null || val.trim().isEmpty ? 'Insira o endereço.' : null,
                              ),
                              const SizedBox(height: 20),

                              // Dropdowns
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: _selectedBalnearioId,
                                      decoration: const InputDecoration(
                                        labelText: 'Balneário',
                                        prefixIcon: Icon(Icons.beach_access_outlined),
                                      ),
                                      items: _balnearios.map((b) {
                                        return DropdownMenuItem(
                                          value: b.id,
                                          child: Text(b.nome),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        setState(() {
                                          _selectedBalnearioId = val;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: _selectedCategoriaId,
                                      decoration: const InputDecoration(
                                        labelText: 'Categoria',
                                        prefixIcon: Icon(Icons.sell_outlined),
                                      ),
                                      items: _categorias.map((c) {
                                        return DropdownMenuItem(
                                          value: c.id,
                                          child: Text(c.nome),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        setState(() {
                                          _selectedCategoriaId = val;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 36),

                              ElevatedButton(
                                onPressed: _submitting ? null : _register,
                                child: _submitting
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Text('Cadastrar Comércio'),
                              ),
                              const SizedBox(height: 20),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Já tem cadastro? ',
                                    style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 13),
                                  ),
                                  TextButton(
                                    onPressed: () => context.go('/login'),
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(0, 0),
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      'Entrar no Painel',
                                      style: TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
