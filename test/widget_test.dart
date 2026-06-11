import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tonarota_2026/core/providers/auth_provider.dart';
import 'package:tonarota_2026/features/auth/login_view.dart';

void main() {
  testWidgets('LoginView validation and fields rendering test', (WidgetTester tester) async {
    // Build the LoginView widget tree
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider(
          create: (_) => AuthProvider(),
          child: const LoginView(),
        ),
      ),
    );

    // Verifica se os campos principais estão renderizados na tela
    expect(find.text('Tô Na Rota'), findsOneWidget);
    expect(find.text('E-mail'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);
    expect(find.text('Entrar no Painel'), findsOneWidget);

    // Clica no botão de entrar sem preencher nada para disparar a validação
    await tester.tap(find.text('Entrar no Painel'));
    await tester.pumpAndSettle();

    // Verifica se os feedbacks de erro de validação local apareceram na tela
    expect(find.text('Insira o e-mail cadastrado.'), findsOneWidget);
    expect(find.text('Insira sua senha.'), findsOneWidget);
  });
}
