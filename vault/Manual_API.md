# 📖 Manual Interativo da API (Endpoints)

Abaixo estão listadas as principais rotas da API backend construída em Dart Shelf. O prefixo padrão das rotas é `/api`.

---

## 🔑 Autenticação (`/api/v1/auth`)

### 1. Criar Conta (POST `/register`)
* **Acesso:** Público.
* **Corpo da Requisição (JSON):**
```json
{
  "email": "user@example.com",
  "password": "my_password",
  "nome": "Meu Nome",
  "role": "estabelecimento"
}
```

### 2. Login (POST `/login`)
* **Acesso:** Público.
* **Corpo da Requisição (JSON):**
```json
{
  "email": "user@example.com",
  "password": "my_password"
}
```
* **Resposta de Sucesso (200 OK):** Retorna o token JWT e dados do perfil.
```json
{
  "token": "eyJhbGciOi...",
  "user": {
    "id": "uuid-aqui",
    "email": "user@example.com",
    "nome": "Meu Nome",
    "role": "estabelecimento",
    "ativo": true
  }
}
```

### 3. Consultar Meu Perfil (GET `/me`)
* **Acesso:** Autenticado (Requer `Authorization: Bearer <token>`).

---

## 🏖️ Balneários (`/api/v1/balnearios`)

* **Listar Todos (GET `/`):** Público. *Filtro opcional:* `GET /?ativos=true`.
* **Obter Único (GET `/<id>`):** Público.
* **Criar Balneário (POST `/`):** Restrito (Requer `role: gestor`).
```json
{
  "nome": "Praia Grande",
  "municipio": "Ubatuba",
  "estado": "SP",
  "descricao": "Bela praia central",
  "imagem_capa_url": "http://link.com/foto.jpg"
}
```
* **Atualizar (PUT `/<id>`):** Restrito (Requer `role: gestor`).
* **Deletar (DELETE `/<id>`):** Restrito (Requer `role: gestor`).

---

## 🛍️ Estabelecimentos (`/api/v1/estabelecimentos`)

* **Listar Todos (GET `/`):** Público. *Filtros de Query:* `balneario_id`, `categoria_id`, `plano`, `status`.
* **Criar Estabelecimento (POST `/`):** Restrito (Requer `role: estabelecimento` ou `gestor`).
* **Atualizar (PUT `/<id>`):** Restrito. AppSec: Somente o **usuário proprietário** (vinculado ao `usuario_id`) ou um **gestor** pode editar.
* **Deletar (DELETE `/<id>`):** Restrito (Somente o proprietário ou gestor).
