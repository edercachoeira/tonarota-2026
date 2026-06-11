---
name: Security Review Flow - Tô Na Rota
description: Fluxo de auditoria contínua a ser acionado ao final de ciclos de implementação de backend.
---

# Workflow: Revisão de Segurança (Security Review)

Este fluxo é obrigatório antes da aprovação de qualquer Pull Request (PR) ou *Merge* que afete autenticação, banco de dados ou lógica de negócios crítica no **Tô Na Rota**. Deve ser executado assumindo a persona do `Security Specialist`.

## Fases da Auditoria

### 1. Auditoria Estática (Code Review)
- Invoque a skill `Security Audit`.
- Revise as consultas SQL em todo o pacote `server/lib/database/`. Bloqueie a entrega se houver interpolação direta de strings em SQL.
- Revise a geração de hash. Confirme se as senhas estão sendo passadas por um algoritmo forte (Argon2id/BCrypt) e NUNCA retornadas ao cliente nas rotas de `GET`.

### 2. Validação de Middleware
- Inspecione a `server/bin/server.dart` e os roteadores.
- O rate limiting está ativo?
- O CORS está configurado para origens específicas (no ambiente de produção)?
- O JWT Middleware está validando a assinatura e rejeitando tokens expirados (`401 Unauthorized`)?

### 3. Validação de Uploads
- Revise as rotas responsáveis por uploads de imagens (como logomarcas ou banners).
- Verifique se a validação se baseia em magic bytes (MIME Type real) ou apenas na extensão do arquivo. (Bloqueie se for apenas extensão).
- Verifique se o limite de tamanho do request (Body Limit) não permite uploads maiores que 5-10MB, protegendo o servidor contra ataques de esgotamento de disco/memória.

### 4. Relatório de Veto ou Aprovação
- Ao terminar, produza um documento `security_report.md` ou adicione uma sessão no `walkthrough.md` atestando que os 3 passos foram cumpridos com sucesso ou listando as vulnerabilidades bloqueantes.
