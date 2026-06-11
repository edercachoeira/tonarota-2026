---
name: Security Audit - Tô Na Rota
description: Realiza uma auditoria de segurança no backend (Dart Shelf) e nas integrações de banco de dados do projeto.
---

# Skill: Auditoria de Segurança (Security Audit)

Você ativou a skill de auditoria de segurança para o projeto **Tô Na Rota**. Siga as etapas abaixo rigorosamente para validar qualquer nova rota de API ou classe de acesso a dados (DAO/Repository).

## Como Executar a Auditoria

### Passo 1: Revisão de Proteção de Rotas (Authentication)
Verifique o arquivo da rota (`server/lib/routes/...`):
- O endpoint exige autenticação? Se sim, ele está utilizando o middleware de JWT (`authMiddleware`)?
- A role exigida pelo endpoint corresponde ao que está sendo acessado? (Ex: Rotas do painel admin devem exigir `role == 'gestor'`).

### Passo 2: Validação de Entrada e SQL Injection
Verifique onde os dados recebidos pelo endpoint (body, query params) estão sendo injetados na query PostgreSQL (`server/lib/database/...`):
- O código usa parâmetros nomeados (`@paramName`) ou posicionais (`$1`, `$2`) em vez de interpolação de strings (ex: NUNCA use `SELECT * FROM tbl WHERE id = ${req.id}`)?
- Os dados do usuário (especialmente `id` do lojista) estão sendo extraídos da requisição e **comparados** com o `usuarioId` presente no token JWT autenticado (Prevenção contra Insecure Direct Object Reference - IDOR)?

### Passo 3: Rate Limiting e Prevenção XSS/CSRF
- A nova rota tem rate limiting configurado? (Padrão: 100 req/min/IP para públicas).
- Se a rota retorna HTML ou conteúdo visual, os cabeçalhos de segurança estão sendo enviados pelo servidor?
- Dados textuais recebidos (como `descricao` do estabelecimento) estão sendo sanitizados no momento em que são gravados (escapar HTML/JS)?

### Passo 4: Feedback da Auditoria
Caso encontre qualquer violação, pare o que estiver fazendo e notifique o desenvolvedor (ou aplique a correção você mesmo, se tiver autonomia para tal). Nunca aceite compromissos na segurança. Documente a falha encontrada apontando para o arquivo e a linha problemática.
