import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';

class RecuperacaoSenhaView extends StatefulWidget {
  final bool isReset;
  final String token;

  const RecuperacaoSenhaView({
    super.key,
    required this.isReset,
    this.token = '',
  });

  @override
  State<RecuperacaoSenhaView> createState() => _RecuperacaoSenhaViewState();
}

class _RecuperacaoSenhaViewState extends State<RecuperacaoSenhaView> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _successMessage;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _requestRecovery() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final res = await _apiService.post('/v1/auth/forgot-password', {
        'email': _emailController.text,
      });

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _successMessage = data['message'] ?? 'Link de recuperação enviado!';
          _isLoading = false;
        });
      } else {
        final data = jsonDecode(res.body);
        setState(() {
          _errorMessage = data['error'] ?? 'Erro ao processar solicitação.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao se conectar ao servidor.';
        _isLoading = false;
      });
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final res = await _apiService.post('/v1/auth/reset-password', {
        'token': widget.token,
        'new_password': _newPasswordController.text,
      });

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _successMessage = data['message'] ?? 'Senha redefinida com sucesso!';
          _isLoading = false;
        });
      } else {
        final data = jsonDecode(res.body);
        setState(() {
          _errorMessage = data['error'] ?? 'Token inválido ou expirado.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao se conectar ao servidor.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight;
    final secondaryColor = isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight;
    final containerColor = isDark ? AppTheme.surfaceDark : Colors.white;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 450),
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: containerColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '🏝️',
                    style: TextStyle(fontSize: 36),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Tô Na Rota',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryTeal,
                      letterSpacing: -1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              if (_successMessage != null) ...[
                const CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.green,
                  child: Icon(Icons.check_rounded, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 24),
                Text(
                  widget.isReset ? 'Senha Redefinida!' : 'E-mail Enviado!',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryColor),
                ),
                const SizedBox(height: 12),
                Text(
                  _successMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: secondaryColor, fontSize: 14),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Ir para o Login'),
                  ),
                ),
              ] else ...[
                Text(
                  widget.isReset ? 'Redefinir Senha' : 'Recuperar Senha',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryColor),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.isReset
                      ? 'Preencha os campos abaixo para criar sua nova senha de acesso.'
                      : 'Digite seu e-mail cadastrado. Enviaremos um link seguro para alteração.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: secondaryColor, fontSize: 14),
                ),
                const SizedBox(height: 24),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      if (!widget.isReset)
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Seu E-mail',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Insira seu e-mail.';
                            if (!val.contains('@')) return 'E-mail inválido.';
                            return null;
                          },
                        )
                      else ...[
                        TextFormField(
                          controller: _newPasswordController,
                          decoration: const InputDecoration(
                            labelText: 'Nova Senha (mín. 6 caracteres)',
                            prefixIcon: Icon(Icons.lock_outline_rounded),
                          ),
                          obscureText: true,
                          validator: (val) => val == null || val.length < 6 ? 'Mínimo de 6 caracteres.' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmPasswordController,
                          decoration: const InputDecoration(
                            labelText: 'Confirmar Nova Senha',
                            prefixIcon: Icon(Icons.lock_outline_rounded),
                          ),
                          obscureText: true,
                          validator: (val) {
                            if (val != _newPasswordController.text) {
                              return 'As senhas não coincidem.';
                            }
                            return null;
                          },
                        ),
                      ],
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : (widget.isReset ? _resetPassword : _requestRecovery),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text(widget.isReset ? 'Alterar Senha' : 'Enviar Link de Recuperação'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: const Text('Voltar ao Login'),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
