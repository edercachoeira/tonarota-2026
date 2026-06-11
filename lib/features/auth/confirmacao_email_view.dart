import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';

class ConfirmacaoEmailView extends StatefulWidget {
  final String token;

  const ConfirmacaoEmailView({super.key, required this.token});

  @override
  State<ConfirmacaoEmailView> createState() => _ConfirmacaoEmailViewState();
}

class _ConfirmacaoEmailViewState extends State<ConfirmacaoEmailView> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _successMessage;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _confirmEmail();
  }

  Future<void> _confirmEmail() async {
    if (widget.token.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Token de ativação ausente na URL.';
      });
      return;
    }

    try {
      final res = await _apiService.post('/v1/auth/confirm-email', {
        'token': widget.token,
      });

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _successMessage = data['message'] ?? 'E-mail confirmado com sucesso!';
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
        _errorMessage = 'Erro ao conectar ao servidor.';
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
              if (_isLoading) ...[
                const CircularProgressIndicator(color: AppTheme.primaryTeal),
                const SizedBox(height: 24),
                Text(
                  'Confirmando seu e-mail...',
                  style: TextStyle(color: primaryColor, fontSize: 16),
                ),
              ] else if (_successMessage != null) ...[
                const CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.green,
                  child: Icon(Icons.check_rounded, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 24),
                Text(
                  'Conta Ativada!',
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
                const CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.redAccent,
                  child: Icon(Icons.close_rounded, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 24),
                Text(
                  'Falha na Ativação',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryColor),
                ),
                const SizedBox(height: 12),
                Text(
                  _errorMessage ?? 'Ocorreu um erro ao ativar a sua conta.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: secondaryColor, fontSize: 14),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryTeal),
                    onPressed: () => context.go('/'),
                    child: const Text('Voltar ao Site'),
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
