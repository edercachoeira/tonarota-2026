# 🗄️ Configuração do Banco de Dados PostgreSQL

O banco de dados relacional armazena a estrutura multi-tenant do aplicativo, onde cada balneário atua como um segmento independente de dados.

---

## 🔌 Configurações de Conexão Local

* **Host:** `localhost`
* **Porta:** `5432`
* **Nome do Banco:** `tonarota_dev`
* **Usuário:** `tonarota_app`
* **Senha:** `tonarota_app`

*As configurações podem ser sobrescritas criando um arquivo `.env` na raiz do diretório `server/`.*

---

## 📊 Listagem de Tabelas (DDL)

O script completo DDL está localizado em `server/lib/database/schema.sql`.

| Tabela | Chave Primária | Relacionamentos Chave | Finalidade |
|---|---|---|---|
| `balneario` | UUID (`id`) | - | Cadastro de praias/municípios |
| `categoria` | UUID (`id`) | `parent_id` (auto-relacionamento) | Ramos de negócios |
| `usuario` | UUID (`id`) | - | Credenciais e roles (turista/lojista/gestor) |
| `estabelecimento` | UUID (`id`) | `usuario_id`, `balneario_id`, `categoria_id` | Perfis comerciais (Lojas) |
| `produto` | UUID (`id`) | `estabelecimento_id` | Catálogo de produtos (vitrine) |
| `camera` | UUID (`id`) | `balneario_id` | Câmeras de streaming (HLS/RTSP) |
| `evento` | UUID (`id`) | `balneario_id` | Agenda cultural local |
| `avaliacao` | UUID (`id`) | `estabelecimento_id` | Comentários e notas (1 a 5 estrelas) |
| `banner` | UUID (`id`) | - | Banners de anunciantes |
| `emergencia` | UUID (`id`) | `balneario_id` | Telefones úteis essenciais |
| `notificacao` | UUID (`id`) | `balneario_id` (nullable) | Histórico de push notifications |
| `banner_balneario` | Composta | `banner_id`, `balneario_id` | Tabela pivô N-N de anúncios |
