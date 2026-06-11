# Ecossistema de IA — Tô Na Rota (`.agent_tnr`)

Bem-vindo ao diretório `.agent_tnr`. Este diretório funciona como o **"Cérebro de Contexto"** para qualquer Inteligência Artificial (agentes) operando no repositório do projeto **Tô Na Rota**.

Ele contém personas de especialistas, habilidades específicas de auditoria, regras inegociáveis de arquitetura e fluxos de trabalho (workflows) padronizados. O objetivo é garantir que o código gerado seja altamente seguro, visualmente impecável e perfeitamente alinhado aos objetivos de negócio descritos no PRD.

---

## 📂 Estrutura do Diretório

### 1. `agents/` (Personas / Especialistas)
Define como o agente de IA deve se comportar dependendo do contexto da solicitação.
- **[premium_designer.md](./agents/premium_designer.md)**: Foca em usabilidade (UX), acessibilidade e em garantir uma estética "Wow" (premium, moderna, responsiva).
- **[project_manager.md](./agents/project_manager.md)**: O guardião do PRD e do cronograma. Garante que entregas incrementais ocorram e que features fora do escopo (ex: funcionalidades V2) não sejam desenvolvidas antecipadamente. Impõe a filosofia "Web-First".
- **[qa_engineer.md](./agents/qa_engineer.md)**: Engenheiro rigoroso de Qualidade (QA). Exige desenvolvimento guiado a testes (TDD) para o pacote `shared`, `server` e `frontend`, rejeitando "código legado" sem cobertura.
- **[security_specialist.md](./agents/security_specialist.md)**: Especialista em AppSec. Audita implacavelmente o código em busca de injeções SQL, quebras de JWT, falta de *Rate Limiting* e falhas de CORS.

### 2. `skills/` (Habilidades Acionáveis)
Instruções "passo-a-passo" que o agente de IA deve executar para validar blocos de código.
- **[security_audit/SKILL.md](./skills/security_audit/SKILL.md)**: Checklist para auditar rotas, middleware e repositórios do Dart Shelf.
- **[test_automation/SKILL.md](./skills/test_automation/SKILL.md)**: Guia de como e o que testar nas camadas do projeto (ex: Unit Tests com mocks para banco, Widget Tests para Flutter).
- **[ux_ui_review/SKILL.md](./skills/ux_ui_review/SKILL.md)**: Checklist visual (espaçamentos, tipografia, micro-interações) para componentes Flutter.

### 3. `rules/` (Regras Globais do Projeto)
- **[tnr_rules.md](./rules/tnr_rules.md)**: As "leis universais" do repositório. Inclui a obrigação de usar o pacote `tonarota_shared`, a política de escrita de código e comentários em português, e diretrizes obrigatórias de segurança.

### 4. `workflows/` (Fluxos de Trabalho)
Guias que mapeiam o processo de desenvolvimento para evitar trabalho desordenado.
- **[feature_dev_flow.md](./workflows/feature_dev_flow.md)**: O caminho desde a leitura do PRD até o Deploy, forçando a implementação a passar pelas etapas de *Banco de Dados -> Backend -> Frontend -> Testes*.
- **[security_review_flow.md](./workflows/security_review_flow.md)**: Fluxo de auditoria exigido antes de fechar pacotes de desenvolvimento focados em API.
- **[test_execution_flow.md](./workflows/test_execution_flow.md)**: Scripts rotineiros para testar isoladamente o repositório `shared/`, `server/` e o frontend `flutter`.

---

## 🤖 Instruções para Agentes IA
Se você é um agente operando neste repositório:
1. Sempre inicie sessões complexas relendo o agente ou skill relevante dentro deste diretório.
2. Adira incondicionalmente ao `rules/tnr_rules.md`.
3. Ao construir novas lógicas, guie-se pelo `workflows/feature_dev_flow.md`.
