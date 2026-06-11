---
name: Feature Development Flow - Tô Na Rota
description: Fluxo de trabalho padronizado para o desenvolvimento de novas funcionalidades no monorepo.
---

# Workflow: Desenvolvimento de Nova Feature

Este fluxo garante que todas as novas funcionalidades no projeto **Tô Na Rota** sejam desenvolvidas de forma estruturada, mantendo a arquitetura limpa e segura.

Sempre que você, agente, for solicitado a criar uma "nova feature", siga obrigatoriamente estes passos:

## Fase 1: Análise e Planejamento (Project Manager)
1. **Verificação do PRD**: Leia o `docs/PRD.md` para garantir que a feature está no escopo da fase atual. Se for uma feature complexa não mapeada, solicite um *Understanding Lock* e aprove a modelagem com o usuário.
2. **Definição de Entregáveis**: Quebre a feature em (a) Banco de Dados, (b) Backend, (c) Shared Models e (d) Frontend.

## Fase 2: Banco de Dados e Modelagem (Data Tier)
1. **Criação do Modelo**: Crie ou atualize as classes no pacote `shared/lib/src/models/` com os métodos `.fromJson()` e `.toJson()`.
2. **Atualização do DDL**: Se houver mudanças no banco, atualize ou crie o script de migração correspondente em `server/lib/database/` e aplique no PostgreSQL local (`tonarota_dev`).

## Fase 3: Backend e API (Server Tier)
1. **Lógica de Acesso a Dados**: Implemente o DAO/Repository no `server/lib/database/` usando PostgreSQL.
2. **Rotas e Controladores**: Crie as rotas necessárias em `server/lib/routes/`.
3. **Auditoria Previa**: Acione mentalmente a skill de `Security Audit` para revisar se a nova rota está protegida via JWT e contra SQL Injection.

## Fase 4: Frontend (Web-First)
1. **Integração de Serviços**: Crie as chamadas HTTP em `lib/core/services/` utilizando os modelos do pacote `shared`.
2. **Implementação de UI**: Crie a interface no Flutter garantindo a adesão ao padrão estético.
3. **Revisão de Design**: Acione a skill de `UX & UI Review` para validar se a interface possui estética premium e boa usabilidade.

## Fase 5: QA e Testes Automatizados (QA Engineer)
1. **Criação de Testes**: Escreva os testes unitários (`_test.dart`) para qualquer nova lógica criada na Fase 2 e 3.
2. **Execução**: Rode a skill `Test Execution Flow` para certificar de que as modificações não causaram regressões em rotas existentes ou na UI.

## Fase 6: Entrega (Deploy)
- Escreva o resumo das mudanças no `walkthrough.md` e aguarde validação manual antes de qualquer push em massa (seguindo o Nível 1 de Autonomia das regras globais).
