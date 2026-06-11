# Guia de Preparação de Ambiente: Flutter (Local & VPS Hostinger)

Este documento detalha o passo a passo para configurar o ambiente de desenvolvimento local no Windows e preparar a futura hospedagem e deploy da aplicação em uma VPS Linux na Hostinger.

---

## 1. Configuração do Ambiente Local (Windows)

Como o computador atual já está totalmente configurado e possui o Flutter instalado (compartilhado com o projeto `app_mffq_2026`), esta seção serve como referência.

### Passo 1.1: Instalar o Flutter SDK
1. Caso precise atualizar ou reinstalar, baixe o Flutter SDK estável mais recente do [site oficial do Flutter](https://docs.flutter.dev/get-started/install/windows/desktop).
2. Extraia o arquivo zip em um diretório apropriado (ex: `C:\src\flutter`).
   > [!WARNING]
   > Evite instalar o Flutter em caminhos que exijam privilégios elevados como `C:\Program Files\`.
3. Adicione o caminho do Flutter ao seu PATH de usuário:
   - No menu iniciar, busque por "Editar as variáveis de ambiente do sistema".
   - Clique em **Variáveis de Ambiente**.
   - Em **Variáveis de usuário**, selecione `Path` e clique em **Editar**.
   - Clique em **Novo** e adicione: `C:\src\flutter\bin` (ajuste se extraiu em outro local).
   - Clique em **OK** em todas as janelas.

### Passo 1.2: Configurar o Android Studio & SDK
1. Baixe e instale o [Android Studio](https://developer.android.com/studio).
2. Abra o Android Studio e conclua o assistente de configuração (Setup Wizard), instalando o **Android SDK**, **Android SDK Command-line Tools** e o **Android Virtual Device (Emulator)**.
3. No Android Studio, vá em **SDK Manager** > **SDK Tools** > Marque **Android SDK Command-line Tools (latest)** e clique em Aplicar para instalar.
4. Aceite as licenças do Android executando no terminal:
   ```powershell
   flutter doctor --android-licenses
   ```
   *Responda `y` (yes) para todos os termos.*

### Passo 1.3: Validar a Instalação
Abra o PowerShell no diretório do projeto e execute:
```powershell
flutter doctor
```
Certifique-se de que o Flutter, Android toolchain e VS Code/Android Studio estejam marcados com sucesso `[✓]`.

---

## 2. Inicialização do Projeto Flutter no Repositório

O projeto já foi inicializado com sucesso neste diretório usando o seguinte comando:
```powershell
flutter create --project-name=tonarota_2026 --platforms=android,ios,web .
```

O arquivo [`.gitignore`](file:///e:/xampp/htdocs/tonarota-2026/.gitignore) e o [`.antigravityignore`](file:///e:/xampp/htdocs/tonarota-2026/.antigravityignore) já foram configurados para omitir os arquivos temporários e binários de build.

---

## 3. Preparação para Deploy na VPS Hostinger

Como o Flutter gera aplicações nativas para celulares (Android/iOS) e também web (Flutter Web), existem duas formas de utilizá-lo com uma VPS Hostinger:
- **Cenário A: Hospedar a versão Web do Flutter** na VPS (acessível via navegador).
- **Cenário B: Hospedar a API Backend** (Node.js, Python ou Dart Shelf) na VPS para servir os aplicativos Android/iOS instalados nos celulares.

### Cenário A: Hospedagem da Versão Flutter Web na VPS
Para servir a versão web do Flutter usando o servidor web de alta performance **Nginx**:

#### Passo 3.1: Compilar o projeto localmente
Gere os arquivos estáticos de produção otimizados:
```powershell
flutter build web --release
```
Isso criará uma pasta contendo os arquivos finais em `build/web/`.

#### Passo 3.2: Configurar o Servidor VPS (Debian/Ubuntu)
1. Conecte-se à sua VPS via SSH:
   ```bash
   ssh root@ip_da_vps
   ```
2. Instale e inicie o Nginx:
   ```bash
   sudo apt update
   ```
   ```bash
   sudo apt install nginx -y
   ```
3. Crie uma pasta para a aplicação:
   ```bash
   sudo mkdir -p /var/www/tonarota
   sudo chown -R $USER:$USER /var/www/tonarota
   ```
4. Transfira os arquivos do seu computador local (pasta `build/web/*`) para a VPS via SCP, SFTP (ex: FileZilla) ou Git:
   ```powershell
   scp -r build/web/* root@ip_da_vps:/var/www/tonarota/
   ```

#### Passo 3.3: Configurar o Bloco de Servidor Nginx
1. Crie uma configuração dedicada para o site:
   ```bash
   sudo nano /etc/nginx/sites-available/tonarota
   ```
2. Cole a configuração básica abaixo:
   ```nginx
   server {
       listen 80;
       server_name seu-dominio.com.br www.seu-dominio.com.br;

       root /var/www/tonarota;
       index index.html;

       location / {
           try_files $uri $uri/ /index.html;
       }

       # Cache de assets estáticos
       location ~* \.(?:css|js|jpg|jpeg|gif|png|ico|cur|gz|svg|svgz|mp4|ogg|ogv|webm|htc|woff|woff2)$ {
           expires 1M;
           access_log off;
           add_header Cache-Control "public";
       }
   }
   ```
3. Ative a configuração e reinicie o Nginx:
   ```bash
   sudo ln -s /etc/nginx/sites-available/tonarota /etc/nginx/sites-enabled/
   sudo nginx -t
   sudo systemctl restart nginx
   ```
4. *(Opcional)* Instale o Certbot para configurar SSL gratuito (HTTPS):
   ```bash
   sudo apt install certbot python3-certbot-nginx -y
   sudo certbot --nginx -d seu-dominio.com.br -d www.seu-dominio.com.br
   ```
