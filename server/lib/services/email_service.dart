import 'dart:io';
import 'package:dotenv/dotenv.dart';

class EmailService {
  static final EmailService _instance = EmailService._internal();
  
  factory EmailService() {
    return _instance;
  }

  EmailService._internal();

  // Em ambiente local, salva os e-mails na pasta temporária para visualização visual rápida
  final String _localEmailDir = 'temp_emails';

  Future<void> sendConfirmationEmail(String toEmail, String userName, String token) async {
    final confirmationUrl = 'http://localhost:8081/#/confirm-email?token=$token';

    final htmlContent = _buildTemplate(
      title: 'Confirme seu Cadastro',
      greeting: 'Olá, $userName!',
      message: 'Obrigado por se cadastrar no **Tô Na Rota**. Estamos muito felizes em ter você conosco! Para começar a explorar todos os recursos e ativar sua conta, confirme seu e-mail clicando no botão abaixo:',
      actionText: 'Confirmar E-mail',
      actionUrl: confirmationUrl,
      helpText: 'Se o botão acima não funcionar, copie e cole o seguinte link no seu navegador:',
      buttonColor: '#0D9488', // Teal 600
    );

    await _saveLocalEmail('confirmacao_$toEmail', htmlContent);
  }

  Future<void> sendPasswordRecoveryEmail(String toEmail, String userName, String token) async {
    final resetUrl = 'http://localhost:8081/#/reset-password?token=$token';

    final htmlContent = _buildTemplate(
      title: 'Recuperação de Senha',
      greeting: 'Olá, $userName!',
      message: 'Recebemos uma solicitação para redefinir a senha da sua conta no **Tô Na Rota**. Se você não realizou esta solicitação, pode ignorar este e-mail com segurança. Para criar uma nova senha, clique no botão abaixo:',
      actionText: 'Redefinir Senha',
      actionUrl: resetUrl,
      helpText: 'O link de redefinição é válido por 1 hora. Se o botão não funcionar, utilize o link abaixo:',
      buttonColor: '#D97706', // Amber 600
    );

    await _saveLocalEmail('recuperacao_$toEmail', htmlContent);
  }

  Future<void> _saveLocalEmail(String prefix, String htmlContent) async {
    try {
      final dir = Directory(_localEmailDir);
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('$_localEmailDir/${prefix}_$timestamp.html');
      await file.writeAsString(htmlContent);
      print('E-MAIL SIMULADO: Gravado com sucesso em ${file.path}');
    } catch (e) {
      print('Erro ao salvar e-mail localmente: $e');
    }
  }

  String _buildTemplate({
    required String title,
    required String greeting,
    required String message,
    required String actionText,
    required String actionUrl,
    required String helpText,
    required String buttonColor,
  }) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>$title</title>
  <style>
    body {
      background-color: #0F172A;
      margin: 0;
      padding: 40px 20px;
      font-family: 'Segoe UI', -apple-system, BlinkMacSystemFont, Roboto, Helvetica, Arial, sans-serif;
    }
    .email-container {
      max-width: 600px;
      margin: 0 auto;
      background-color: #1E293B;
      border-radius: 16px;
      border: 1px solid #334155;
      overflow: hidden;
      box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.3);
    }
    .header {
      padding: 32px;
      text-align: center;
      background: linear-gradient(135deg, #0F172A 0%, #1E293B 100%);
      border-bottom: 1px solid #334155;
    }
    .logo {
      font-size: 28px;
      font-weight: bold;
      color: #0D9488;
      text-decoration: none;
      display: inline-block;
    }
    .content {
      padding: 40px 32px;
      color: #F8FAFC;
    }
    h1 {
      font-size: 22px;
      font-weight: 700;
      margin-top: 0;
      margin-bottom: 24px;
      color: #F8FAFC;
      letter-spacing: -0.5px;
    }
    p {
      font-size: 15px;
      line-height: 1.6;
      color: #94A3B8;
      margin-top: 0;
      margin-bottom: 24px;
    }
    .action-container {
      text-align: center;
      margin: 32px 0;
    }
    .btn {
      display: inline-block;
      background-color: $buttonColor;
      color: #FFFFFF !important;
      text-decoration: none;
      padding: 14px 32px;
      font-size: 15px;
      font-weight: bold;
      border-radius: 30px;
      box-shadow: 0 4px 12px rgba(13, 148, 136, 0.2);
      transition: all 0.2s ease-in-out;
    }
    .help-section {
      margin-top: 40px;
      padding-top: 24px;
      border-top: 1px solid #334155;
    }
    .help-title {
      font-size: 12px;
      color: #64748B;
      text-transform: uppercase;
      letter-spacing: 0.1em;
      margin-bottom: 8px;
    }
    .link-display {
      font-size: 12px;
      color: #0D9488;
      word-break: break-all;
    }
    .footer {
      padding: 32px;
      text-align: center;
      background-color: #0F172A;
      color: #64748B;
      font-size: 12px;
      border-top: 1px solid #334155;
    }
  </style>
</head>
<body>
  <div class="email-container">
    <div class="header">
      <a href="http://localhost:8081" class="logo">🏝️ Tô Na Rota</a>
    </div>
    <div class="content">
      <h1>$title</h1>
      <p style="font-weight: bold; color: #F8FAFC; font-size: 16px;">$greeting</p>
      <p>$message</p>
      
      <div class="action-container">
        <a href="$actionUrl" target="_blank" class="btn">$actionText</a>
      </div>
      
      <div class="help-section">
        <div class="help-title">$helpText</div>
        <div class="link-display">$actionUrl</div>
      </div>
    </div>
    <div class="footer">
      © 2026 Tô Na Rota. Todos os direitos reservados.<br>
      Este é um e-mail automático do ecossistema de testes do Tô Na Rota.
    </div>
  </div>
</body>
</html>
''';
  }
}
