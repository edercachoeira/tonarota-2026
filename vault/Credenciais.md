# 🔐 Credenciais e Perfis de Acesso

Este documento reúne os acessos criados no ambiente de desenvolvimento local (`tonarota_dev`) e as regras de segurança aplicadas aos perfis.

---

## 👥 Contas Cadastradas no Banco Local

### 1. Gestor (Super Administrador)
* **E-mail:** `admin@tonarota.com`
* **Senha:** `senha_segura`
* **Role:** `gestor`
* **Permissões:** Controle total de balneários, categorias, anunciantes, lojistas e moderação de avaliações.

### 2. Lojista de Teste (Estabelecimento)
* **E-mail:** `quiosque@tonarota.com`
* **Senha:** `senha_quiosque`
* **Role:** `estabelecimento`
* **Permissões:** Editar dados da sua loja, horários e vitrine digital (produtos).

---

## 🛡️ Políticas de Segurança e Expiração (PRD)

* **Hashing de Senhas:** As senhas nunca são gravadas em texto limpo. Elas passam pelo algoritmo **BCrypt** com salt individual.
* **Sessões JWT:**
  * Contas com perfil **Gestor**: O token expira em **8 horas** (requisito de alta segurança).
  * Contas com perfil **Estabelecimento**: O token expira em **24 horas**.
* **Proteção contra Força Bruta:**
  * O servidor possui **Rate Limiter** ativo por IP. Tentativas sucessivas em `/api/v1/auth/login` acima de **30 requisições/minuto** retornarão status `HTTP 429` (Too Many Requests).
