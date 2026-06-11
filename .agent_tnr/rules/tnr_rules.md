# Regras de Ouro do Workspace: Tô Na Rota

Este documento estabelece as regras fundamentais e inegociáveis para qualquer desenvolvimento dentro deste repositório. O não cumprimento destas regras resultará em falha na aprovação do código.

## 1. Arquitetura Monorepo e Código Compartilhado
- **NUNCA duplique modelos de dados**: Entidades (ex: Usuario, Estabelecimento) devem sempre ser criadas e mantidas dentro de `shared/lib/src/models/`. Tanto o backend (`server`) quanto o frontend (`lib`) devem importar o pacote `tonarota_shared`.
- **Validações Centralizadas**: Qualquer validação de formulário ou regra de negócio que se aplique tanto ao cliente quanto ao servidor deve existir no pacote `shared`.

## 2. Estratégia Web-First
- O foco atual do projeto (Fase 2) é o **Flutter Web** (Painel Admin e Portal do Lojista).
- **Mobile Fica para Depois**: Nenhuma funcionalidade exclusiva do App Mobile (como integração nativa de GPS ou permissões complexas de Android/iOS) deve ser desenvolvida ou priorizada antes que o fluxo Web esteja 100% concluído e homologado.

## 3. Padrão Estético e Design Premium
- O produto é um SaaS. A interface não pode parecer um "trabalho de faculdade". 
- Use cores da marca (a definir), gradientes sutis, cantos arredondados (Radius 12-16) e micro-interações.
- Sempre que criar um novo widget visual, valide-o usando a skill de `UX & UI Review`.

## 4. Segurança by Design
- Toda rota do backend (Dart Shelf) deve validar o JWT, a não ser que seja explicitamente pública (ex: login, listagem pública de balneários).
- Todos os inputs que interagem com o banco PostgreSQL devem ser estritamente sanitizados (sem concatenação de strings em SQL).
- Toda nova rota ou alteração de banco deve passar pela skill de `Security Audit`.

## 5. Idioma e Nomenclatura
- Commits, comentários de código estrutural e documentação devem ser feitos em **Português (pt-BR)**.
- O nome do produto é **"Tô Na Rota"** (evite "Tô Na Rota 2026" na UI ou em textos públicos, o 2026 é apenas o nome do repositório).
