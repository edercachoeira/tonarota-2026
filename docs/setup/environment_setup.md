# Guia de Preparação de Ambiente — Tô Na Rota

| Campo | Valor |
|---|---|
| **Documento** | Configuração do Ambiente de Desenvolvimento e Produção |
| **Versão** | 1.0 |
| **Data** | 11 de Junho de 2026 |
| **Plataforma Local** | Windows 10/11 |
| **Plataforma de Produção** | VPS Linux (Hostinger) — Ubuntu 22.04 LTS |

---

## 1. Ambiente de Desenvolvimento Local (Windows)

> [!NOTE]
> O ambiente Flutter já está configurado nesta máquina (compartilhado com o projeto `app_mffq_2026`). Esta seção serve como referência para onboarding de novos desenvolvedores ou reinstalação.

### 1.1 Pré-requisitos de Software

| Software | Versão Mínima | Finalidade | Download |
|---|---|---|---|
| **Flutter SDK** | 3.x (canal stable) | Framework de UI para Mobile e Web | [flutter.dev/install](https://docs.flutter.dev/get-started/install/windows/desktop) |
| **Dart SDK** | 3.x (incluído no Flutter) | Linguagem unificada (frontend + backend) | Incluído no Flutter SDK |
| **Android Studio** | Latest | SDK Android, emulador AVD, ferramentas de build | [developer.android.com/studio](https://developer.android.com/studio) |
| **VS Code** | Latest | Editor de código recomendado (com extensões Flutter e Dart) | [code.visualstudio.com](https://code.visualstudio.com/) |
| **PostgreSQL** | 15+ | Banco de dados local para desenvolvimento | [postgresql.org/download](https://www.postgresql.org/download/windows/) |
| **Git** | 2.x | Controle de versão | [git-scm.com](https://git-scm.com/downloads) |

### 1.2 Instalação do Flutter SDK

1. Baixe o Flutter SDK estável mais recente do [site oficial](https://docs.flutter.dev/get-started/install/windows/desktop).
2. Extraia o arquivo zip em um diretório sem espaços e sem privilégios elevados:
   ```
   C:\src\flutter
   ```
   > [!WARNING]
   > **Não instale** em `C:\Program Files\` ou caminhos com espaços. Isso causa falhas nas ferramentas de build.

3. Adicione o Flutter ao PATH do sistema:
   - Pressione `Win + S` → busque "Variáveis de Ambiente".
   - Em **Variáveis de usuário** → selecione `Path` → clique em **Editar**.
   - Adicione uma nova entrada: `C:\src\flutter\bin`.
   - Clique em **OK** em todas as janelas.

4. Abra um novo terminal PowerShell e valide:
   ```powershell
   flutter --version
   dart --version
   ```

### 1.3 Configuração do Android Studio & SDK

1. Instale o [Android Studio](https://developer.android.com/studio) e conclua o **Setup Wizard**.
2. No Setup Wizard, instale:
   - Android SDK (API Level 34 ou mais recente)
   - Android SDK Command-line Tools (latest)
   - Android Emulator
3. Aceite as licenças do Android:
   ```powershell
   flutter doctor --android-licenses
   ```
   Responda `y` para todos os termos.

### 1.4 Configuração do PostgreSQL Local

1. Instale o [PostgreSQL para Windows](https://www.postgresql.org/download/windows/) via instalador interativo.
2. Durante a instalação, defina a senha do superusuário `postgres`.
3. Após a instalação, crie o banco de dados do projeto:
   ```powershell
   psql -U postgres -c "CREATE DATABASE tonarota_dev;"
   ```
4. Crie um usuário dedicado para a aplicação (opcional, mas recomendado):
   ```sql
   CREATE USER tonarota_app WITH PASSWORD 'sua_senha_segura';
   GRANT ALL PRIVILEGES ON DATABASE tonarota_dev TO tonarota_app;
   ```

### 1.5 Validação Completa do Ambiente

Execute o diagnóstico completo do Flutter e certifique-se de que todos os itens estejam com `[✓]`:

```powershell
flutter doctor -v
```

Itens esperados:
- ✓ Flutter (channel stable)
- ✓ Android toolchain (API 34+)
- ✓ Chrome (para Flutter Web)
- ✓ Android Studio
- ✓ VS Code (com extensão Flutter)

### 1.6 Inicialização do Projeto

O projeto já foi inicializado neste repositório com o seguinte comando:
```powershell
flutter create --project-name=tonarota_2026 --platforms=android,ios,web .
```

Para executar o projeto localmente:
```powershell
# App mobile no emulador Android
flutter run

# App web no Chrome
flutter run -d chrome

# Servidor backend (após criação da pasta server/)
cd server
dart run bin/server.dart
```

---

## 2. Ambiente de Produção — VPS Hostinger (Linux)

### 2.1 Requisitos Mínimos da VPS

| Recurso | Mínimo Recomendado | Justificativa |
|---|---|---|
| **RAM** | 2 GB | ~50MB para o binário Dart + ~200MB para PostgreSQL + ~100MB para Nginx + margem. |
| **CPU** | 1 vCPU | Suficiente para a carga inicial. Escalar conforme demanda. |
| **Armazenamento** | 20 GB SSD | Sistema operacional + banco de dados + imagens de upload dos lojistas. |
| **Sistema Operacional** | Ubuntu 22.04 LTS | Suporte de longo prazo, ampla documentação, compatível com Dart AOT. |
| **Banda** | 1 TB/mês | Suficiente para servir imagens comprimidas e dados JSON da API. |

### 2.2 Provisionamento Inicial do Servidor

Conecte-se à VPS via SSH e execute os passos abaixo em sequência.

#### Passo 1: Atualização do Sistema
```bash
sudo apt update && sudo apt upgrade -y
```

#### Passo 2: Instalar PostgreSQL
```bash
sudo apt install postgresql postgresql-contrib -y
sudo systemctl enable postgresql
sudo systemctl start postgresql
```

Criar o banco de produção e o usuário:
```bash
sudo -u postgres psql <<EOF
CREATE USER tonarota_app WITH PASSWORD 'SENHA_FORTE_AQUI';
CREATE DATABASE tonarota_prod OWNER tonarota_app;
GRANT ALL PRIVILEGES ON DATABASE tonarota_prod TO tonarota_app;
EOF
```

> [!IMPORTANT]
> Substitua `SENHA_FORTE_AQUI` por uma senha segura gerada com `openssl rand -base64 32`.

#### Passo 3: Instalar Nginx
```bash
sudo apt install nginx -y
sudo systemctl enable nginx
```

#### Passo 4: Criar Diretórios da Aplicação
```bash
# Diretório para o build estático do Flutter Web
sudo mkdir -p /var/www/tonarota

# Diretório para uploads de imagens dos lojistas
sudo mkdir -p /var/data/tonarota/uploads

# Diretório para o binário do servidor Dart
sudo mkdir -p /opt/tonarota

# Ajustar permissões
sudo chown -R $USER:$USER /var/www/tonarota
sudo chown -R $USER:$USER /var/data/tonarota
sudo chown -R $USER:$USER /opt/tonarota
```

### 2.3 Deploy do Servidor Dart (API)

#### Compilação Local (no Windows)

Compile o servidor Dart para um binário nativo Linux. Se estiver desenvolvendo no Windows, use o Docker para cross-compilar, ou compile diretamente na VPS:

**Opção A: Compilar diretamente na VPS** (recomendado para o MVP)
```bash
# Na VPS: instalar Dart SDK
sudo apt install apt-transport-https
sudo sh -c 'wget -qO- https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -'
sudo sh -c 'wget -qO- https://storage.googleapis.com/download.dartlang.org/linux/debian/dart_stable.list > /etc/apt/sources.list.d/dart_stable.list'
sudo apt update
sudo apt install dart -y

# Clonar o repositório e compilar
cd /opt/tonarota
git clone https://github.com/edercachoeira/tonarota-2026.git .
cd server
dart pub get
dart compile exe bin/server.dart -o /opt/tonarota/server
```

#### Configurar como Serviço systemd

Crie o arquivo de serviço:
```bash
sudo nano /etc/systemd/system/tonarota-api.service
```

Cole o conteúdo:
```ini
[Unit]
Description=Tô Na Rota - API Dart Shelf
After=network.target postgresql.service

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=/opt/tonarota
ExecStart=/opt/tonarota/server
Restart=always
RestartSec=5
Environment=PORT=8080
Environment=DATABASE_URL=postgresql://tonarota_app:SENHA_FORTE_AQUI@localhost:5432/tonarota_prod
Environment=JWT_SECRET=CHAVE_JWT_SECRETA_AQUI
Environment=UPLOAD_DIR=/var/data/tonarota/uploads

[Install]
WantedBy=multi-user.target
```

Ativar e iniciar:
```bash
sudo systemctl daemon-reload
sudo systemctl enable tonarota-api
sudo systemctl start tonarota-api
sudo systemctl status tonarota-api
```

### 2.4 Deploy do Flutter Web (Painel + Portal)

#### Compilar localmente (no Windows)
```powershell
flutter build web --release
```

#### Transferir para a VPS
```powershell
scp -r build/web/* usuario@ip_da_vps:/var/www/tonarota/
```

### 2.5 Configuração do Nginx

Crie a configuração do site:
```bash
sudo nano /etc/nginx/sites-available/tonarota
```

Cole o bloco completo:
```nginx
# Redirecionar HTTP para HTTPS
server {
    listen 80;
    server_name seu-dominio.com.br www.seu-dominio.com.br;
    return 301 https://$server_name$request_uri;
}

# Servidor HTTPS principal
server {
    listen 443 ssl http2;
    server_name seu-dominio.com.br www.seu-dominio.com.br;

    # Certificados SSL (gerenciados pelo Certbot)
    ssl_certificate /etc/letsencrypt/live/seu-dominio.com.br/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/seu-dominio.com.br/privkey.pem;

    # ═══════════════════════════════════════════
    # Flutter Web (Painel Admin + Portal Lojista)
    # ═══════════════════════════════════════════
    root /var/www/tonarota;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    # ═══════════════════════════════════════════
    # API Dart Shelf (Proxy Reverso)
    # ═══════════════════════════════════════════
    location /api/ {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Timeout de 60s para uploads de imagens
        proxy_read_timeout 60s;
        proxy_send_timeout 60s;
        client_max_body_size 10M;
    }

    # ═══════════════════════════════════════════
    # Uploads de imagens (servidos diretamente)
    # ═══════════════════════════════════════════
    location /uploads/ {
        alias /var/data/tonarota/uploads/;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    # ═══════════════════════════════════════════
    # Cache de assets estáticos do Flutter Web
    # ═══════════════════════════════════════════
    location ~* \.(?:css|js|jpg|jpeg|gif|png|ico|svg|woff|woff2|ttf|webp)$ {
        expires 1M;
        access_log off;
        add_header Cache-Control "public";
    }

    # Segurança: headers de proteção
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
}
```

Ativar o site e testar:
```bash
sudo ln -s /etc/nginx/sites-available/tonarota /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default   # remover site padrão
sudo nginx -t                               # validar configuração
sudo systemctl restart nginx
```

### 2.6 Configurar SSL Gratuito (HTTPS)

```bash
sudo apt install certbot python3-certbot-nginx -y
sudo certbot --nginx -d seu-dominio.com.br -d www.seu-dominio.com.br
```

> [!TIP]
> O Certbot configura a renovação automática dos certificados. Verifique com: `sudo certbot renew --dry-run`.

### 2.7 Configurar Backups Automáticos

Crie um script de backup:
```bash
sudo nano /opt/tonarota/backup.sh
```

```bash
#!/bin/bash
BACKUP_DIR="/var/backups/tonarota"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Backup do banco de dados
pg_dump -U tonarota_app tonarota_prod | gzip > "$BACKUP_DIR/db_$TIMESTAMP.sql.gz"

# Remover backups com mais de 7 dias
find $BACKUP_DIR -type f -mtime +7 -delete

echo "Backup concluído: $TIMESTAMP"
```

Agendar execução diária às 3h da manhã:
```bash
chmod +x /opt/tonarota/backup.sh
sudo crontab -e
```

Adicionar a linha:
```
0 3 * * * /opt/tonarota/backup.sh >> /var/log/tonarota-backup.log 2>&1
```

---

## 3. Checklist de Verificação

### 3.1 Ambiente Local (Desenvolvimento)

- [ ] `flutter doctor -v` sem erros críticos
- [ ] PostgreSQL rodando localmente com banco `tonarota_dev` criado
- [ ] `flutter run -d chrome` abre o app no navegador
- [ ] `flutter run` abre o app no emulador Android
- [ ] Servidor Dart Shelf responde em `http://localhost:8080/api/health`

### 3.2 Ambiente de Produção (VPS Hostinger)

- [ ] PostgreSQL instalado, rodando e com banco `tonarota_prod` criado
- [ ] Binário do servidor Dart compilado e salvo em `/opt/tonarota/server`
- [ ] Serviço systemd `tonarota-api` ativo e configurado com `Restart=always`
- [ ] Nginx configurado como proxy reverso e servindo arquivos estáticos
- [ ] SSL ativo via Certbot (HTTPS funcionando)
- [ ] Backup automático do banco configurado via cron
- [ ] `curl https://seu-dominio.com.br/api/health` retorna status 200
- [ ] Flutter Web carregando corretamente em `https://seu-dominio.com.br`
