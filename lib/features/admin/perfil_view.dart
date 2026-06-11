import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tonarota_shared/tonarota_shared.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/auth_provider.dart';

class PerfilView extends StatefulWidget {
  const PerfilView({super.key});

  @override
  State<PerfilView> createState() => _PerfilViewState();
}

class _PerfilViewState extends State<PerfilView> {
  final ApiService _apiService = ApiService();
  final _profileFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  late TextEditingController _nomeController;
  late TextEditingController _emailController;
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isSavingProfile = false;
  bool _isSavingPassword = false;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _nomeController = TextEditingController(text: auth.currentUser?.nome ?? '');
    _emailController = TextEditingController(text: auth.currentUser?.email ?? '');
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_profileFormKey.currentState!.validate()) return;

    setState(() {
      _isSavingProfile = true;
    });

    try {
      final res = await _apiService.put('/v1/auth/me', {
        'nome': _nomeController.text,
        'email': _emailController.text,
      });

      if (res.statusCode == 200) {
        final updatedUser = Usuario.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
        await Provider.of<AuthProvider>(context, listen: false).updateCurrentUser(updatedUser);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dados cadastrais atualizados com sucesso.')),
        );
      } else {
        final errBody = jsonDecode(res.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errBody['error'] ?? 'Erro ao atualizar dados.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro de conexão ao servidor.')),
      );
    } finally {
      setState(() {
        _isSavingProfile = false;
      });
    }
  }

  Future<void> _updatePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    setState(() {
      _isSavingPassword = true;
    });

    try {
      final res = await _apiService.put('/v1/auth/me', {
        'nome': _nomeController.text,
        'email': _emailController.text,
        'old_password': _oldPasswordController.text,
        'new_password': _newPasswordController.text,
      });

      if (res.statusCode == 200) {
        _oldPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Senha atualizada com sucesso.')),
        );
      } else {
        final errBody = jsonDecode(res.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errBody['error'] ?? 'Erro ao atualizar senha.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro de conexão ao servidor.')),
      );
    } finally {
      setState(() {
        _isSavingPassword = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight;
    final secondaryColor = isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight;
    final cardBg = isDark ? AppTheme.surfaceDark : Colors.white;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Título da página
          Text(
            'Minha Conta',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryColor),
          ),
          const SizedBox(height: 6),
          Text(
            'Altere seus dados pessoais e senha com segurança.',
            style: TextStyle(fontSize: 14, color: secondaryColor),
          ),
          const SizedBox(height: 24),

          LayoutBuilder(
            builder: (context, constraints) {
              final isWrap = constraints.maxWidth < 900;

              final children = [
                // Formulário de Dados Cadastrais
                Card(
                  color: cardBg,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _profileFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.person_outline_rounded, color: AppTheme.primaryTeal),
                              const SizedBox(width: 8),
                              Text(
                                'Dados Cadastrais',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _nomeController,
                            decoration: const InputDecoration(labelText: 'Nome'),
                            validator: (val) => val == null || val.trim().isEmpty ? 'Insira seu nome.' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(labelText: 'E-mail'),
                            keyboardType: TextInputType.emailAddress,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Insira seu e-mail.';
                              if (!val.contains('@')) return 'E-mail inválido.';
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isSavingProfile ? null : _updateProfile,
                              child: _isSavingProfile
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text('Salvar Alterações'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Formulário de Segurança/Senha
                Card(
                  color: cardBg,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _passwordFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.shield_outlined, color: AppTheme.secondaryAmber),
                              const SizedBox(width: 8),
                              Text(
                                'Segurança e Senha',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _oldPasswordController,
                            decoration: const InputDecoration(labelText: 'Senha Atual'),
                            obscureText: true,
                            validator: (val) => val == null || val.isEmpty ? 'Insira sua senha atual.' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _newPasswordController,
                            decoration: const InputDecoration(labelText: 'Nova Senha (mín. 6 caracteres)'),
                            obscureText: true,
                            validator: (val) => val == null || val.length < 6 ? 'Insira a nova senha.' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _confirmPasswordController,
                            decoration: const InputDecoration(labelText: 'Confirmar Nova Senha'),
                            obscureText: true,
                            validator: (val) {
                              if (val != _newPasswordController.text) {
                                return 'As senhas não coincidem.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondaryAmber),
                              onPressed: _isSavingPassword ? null : _updatePassword,
                              child: _isSavingPassword
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text('Atualizar Senha'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ];

              if (isWrap) {
                return Column(children: children);
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: children[0]),
                  const SizedBox(width: 24),
                  Expanded(child: children[2]), // children[1] is SizedBox(height: 24)
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
