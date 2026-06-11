---
name: Automação de Testes (QA) - Tô Na Rota
description: Regras e padrões para criação de testes automatizados unitários, de integração e de widgets no ecossistema Dart/Flutter.
---

# Skill: Automação de Testes (Test Automation)

Você ativou a skill de automação de testes do **Tô Na Rota**. Siga as etapas abaixo para criar arquivos de teste `*_test.dart` adequados a cada camada do monorepo.

## Diretrizes por Camada

### 1. Pacote `shared/` (Modelos e Lógica de Negócio Pura)
- **O que testar**: Serialização `fromJson`/`toJson` para garantir que campos nulos não quebrem a aplicação; Validadores (ex: validar CNPJ, e-mails); Regras numéricas puras.
- **Ferramentas**: Pacote `test` do Dart.
- **Exemplo de Escopo**: Testar se instanciar `Estabelecimento.fromJson` com um JSON contendo atributos extras ignora esses atributos com segurança ou se falta um atributo obrigatório gera exceção adequada.

### 2. Pacote `server/` (Backend e API)
- **O que testar**: Controladores e rotas (Testes de Integração usando pacotes como `http` ou enviando `Request` falsas diretamente para o handler principal do Shelf); Testar Repositórios em Banco de Dados isolado de testes ou mockando conexões.
- **Ferramentas**: Pacote `test` do Dart, `mocktail` para simular banco de dados, caso integração completa seja pesada.
- **Exemplo de Escopo**: Testar se `POST /api/login` retorna HTTP 401 para senhas erradas e HTTP 200 com o JWT na resposta para credenciais válidas.

### 3. App Frontend (`lib/` - UI)
- **O que testar**: Renderização correta do estado da tela, resposta a cliques de botões, e verificação se os alertas corretos aparecem para o usuário (Widget Tests).
- **Ferramentas**: Pacote `flutter_test`.
- **Exemplo de Escopo**: Fazer um `tester.pumpWidget` e verificar se `find.byType(CircularProgressIndicator)` some após o estado de *loading* passar, dando lugar à lista final.

## Check-list Final do Desenvolvedor
1. Cada teste deve ter a cláusula `setUp` limpa, evitando efeitos colaterais (side effects) entre os blocos `test()`.
2. Use grupos lógicos `group('Descricao', () { ... })` para melhor legibilidade no console.
3. Se o teste envolver requisição de rede ou assincronia pesada em UI, faça sempre *mock* do Client HTTP no frontend. Não gere custo real em APIs externas.
