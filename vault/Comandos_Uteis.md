# 💻 Comandos Úteis do Projeto

Coleção de comandos rápidos para rodar e testar os componentes do Tô Na Rota a partir do terminal.

---

## ⚙️ Backend (API Shelf)

> [!NOTE]
> Todos os comandos abaixo devem ser rodados a partir do diretório `server/`.

### 1. Iniciar Servidor de Desenvolvimento
```powershell
dart run bin/server.dart
```

### 2. Executar Migração do Banco de Dados
Lê e aplica o arquivo `lib/database/schema.sql` no PostgreSQL:
```powershell
dart run bin/migrate.dart
```

### 3. Rodar Testes de API Backend
```powershell
dart test
```

---

## 🖥️ Frontend (Flutter Web / App)

> [!NOTE]
> Todos os comandos abaixo devem ser rodados a partir da **raiz do repositório** (`tonarota-2026/`).

### 1. Iniciar Painel no Navegador (Chrome)
```powershell
flutter run -d chrome
```

### 2. Rodar Testes de Widget
```powershell
flutter test
```

---

## 📦 Pacote Compartilhado (`shared`)

> [!NOTE]
> Comandos a serem executados dentro da pasta `shared/`.

### 1. Baixar Dependências
```powershell
dart pub get
```

### 2. Rodar Testes de Serialização
```powershell
dart test
```
