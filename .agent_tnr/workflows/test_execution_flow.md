---
name: Test Execution Flow - Tô Na Rota
description: Fluxo obrigatório de execução de suítes de teste antes da entrega de features e deploy.
---

# Workflow: Execução de Testes (Test Execution)

Antes de realizar merge de código, commit final ou aprovar uma feature para deploy, execute este fluxo assumindo a persona do **QA Engineer**.

## Fase 1: Validação do Pacote Shared
1. Entre na pasta `shared/`: `cd shared/`
2. Execute: `dart test`
3. Se falhar, retorne o erro ao desenvolvedor e proíba a transição para a próxima fase. O pacote `shared` deve ser o componente mais sólido do ecossistema.

## Fase 2: Validação da API e Backend
1. Entre na pasta `server/`: `cd server/`
2. Garanta que o banco de dados de teste (se houver) esteja rodando.
3. Execute: `dart test`
4. Se houver falha, especialmente nas rotas ou manipulação de banco de dados, interrompa a entrega.

## Fase 3: Validação do App Frontend
1. Na raiz do projeto Flutter (`tonarota-2026/`), execute: `flutter test`
2. Avalie os testes de Widgets.
3. Certifique-se de que nenhum Widget essencial quebrou visualmente ou lógicamente devido a atualizações na lógica de negócio importada do `shared/`.

## Fase 4: Parecer de QA
Se e somente se as Fases 1, 2 e 3 retornarem sucesso ("All tests passed"), registre no documento de log (`walkthrough.md` ou equivalente): *"Rotina de QA Finalizada com Sucesso. Cobertura de teste mantida."*
