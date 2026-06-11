# 🏖️ Tô Na Rota

**Guia Balneário Digital** — Plataforma integrada de guia comercial e utilidade pública para regiões litorâneas.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15+-4169E1?logo=postgresql&logoColor=white)](https://www.postgresql.org/)
[![License](https://img.shields.io/badge/License-Proprietary-red)]()

---

## 📋 Sobre o Projeto

O **Tô Na Rota** é um ecossistema digital composto por três interfaces que compartilham uma base de dados unificada:

| Interface | Plataforma | Público | Descrição |
|---|---|---|---|
| **App Mobile** | Android / iOS | Turistas e Moradores | Diretório de comércios, câmeras ao vivo, agenda cultural, clima e emergências. |
| **Portal do Lojista** | Flutter Web | Comerciantes | Painel self-service para cadastro de perfil, catálogo de produtos e métricas. |
| **Painel Admin** | Flutter Web | Gestor da Plataforma | Console centralizado de gestão de balneários, lojistas, anúncios e notificações. |

O modelo de receita opera por assinaturas comerciais (plano Gratuito vs. Premium) e venda de espaços publicitários.

---

## ⚙️ Stack Tecnológica

```
Flutter (Dart 3.x)          →  Mobile App + Web Panels
Dart Shelf                  →  API REST Backend
PostgreSQL 15+              →  Banco de Dados Relacional
Nginx                       →  Proxy Reverso + SSL
VPS Linux (Hostinger)       →  Infraestrutura de Produção
```

> **Arquitetura Unificada:** Todo o ecossistema (frontend e backend) é desenvolvido em **Dart**, permitindo compartilhamento de modelos de dados, validações e constantes entre cliente e servidor.

---

## 📁 Estrutura do Projeto

```
tonarota-2026/
├── lib/                  # Flutter App (Mobile + Web)
│   ├── core/             # Tema, rotas, serviços HTTP
│   ├── features/         # Telas organizadas por feature
│   └── shared/           # Widgets reutilizáveis
├── server/               # API Backend (Dart Shelf)
│   ├── bin/              # Ponto de entrada do servidor
│   └── lib/              # Rotas, middlewares, serviços, banco
├── shared/               # Pacote Dart compartilhado (client + server)
│   └── lib/              # Models, validators, constants, DTOs
├── docs/                 # Documentação do projeto
│   ├── PRD.md            # Product Requirement Document
│   └── setup/            # Guias de ambiente e infraestrutura
├── android/              # Configurações nativas Android
├── ios/                  # Configurações nativas iOS
├── web/                  # Shell HTML do Flutter Web
└── test/                 # Testes (widget + integração)
```

---

## 🚀 Como Executar

### Pré-requisitos

- [Flutter SDK 3.x](https://docs.flutter.dev/get-started/install) (canal stable)
- [PostgreSQL 15+](https://www.postgresql.org/download/)
- [Git](https://git-scm.com/)

### Desenvolvimento Local

```bash
# Clonar o repositório
git clone https://github.com/edercachoeira/tonarota-2026.git
cd tonarota-2026

# Instalar dependências Flutter
flutter pub get

# Rodar no navegador (Flutter Web)
flutter run -d chrome

# Rodar no emulador Android
flutter run

# Rodar o servidor backend (após configuração do server/)
cd server && dart run bin/server.dart
```

> Para instruções completas de configuração do ambiente, consulte [docs/setup/environment_setup.md](docs/setup/environment_setup.md).

---

## 📖 Documentação

| Documento | Descrição |
|---|---|
| [PRD.md](docs/PRD.md) | Requisitos do produto, personas, modelo de dados, cronograma e testes. |
| [environment_setup.md](docs/setup/environment_setup.md) | Configuração do ambiente local (Windows) e deploy na VPS Hostinger. |
| [technical_revision.md](docs/setup/technical_revision.md) | Revisão técnica: migração da stack PHP/MySQL para Dart/PostgreSQL. |

---

## 🗺️ Roadmap

- [x] Inicialização do projeto Flutter
- [x] Documentação base (PRD, Setup, Revisão Técnica)
- [x] Modelagem do banco de dados PostgreSQL
- [ ] API Dart Shelf (autenticação + CRUDs)
- [ ] Painel do Gestor (Admin Web)
- [ ] Portal do Lojista (Web SaaS)
- [ ] Deploy na VPS Hostinger
- [ ] App Mobile (interface do turista)
- [ ] Publicação nas lojas (Google Play / App Store)
