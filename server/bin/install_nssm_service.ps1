# Script para instalar o backend do Tô Na Rota como serviço oficial do Windows no services.msc
# IMPORTANTE: Executar no PowerShell como ADMINISTRADOR.

$workingDir = "e:\xampp\htdocs\tonarota-2026\server"
$binDir = "$workingDir\bin"
$nssmExe = "$binDir\nssm.exe"
$serverExe = "$binDir\server.exe"

# 1. Remove a tarefa agendada anterior (se existir)
Write-Host "Removendo tarefa agendada anterior..." -ForegroundColor Yellow
Unregister-ScheduledTask -TaskName "TonarotaBackend" -Confirm:$false -ErrorAction SilentlyContinue

# 2. Para e remove o serviço antigo (se já existir para reinstalação limpa)
Write-Host "Parando serviço antigo (se houver)..." -ForegroundColor Yellow
Stop-Service -Name "TonarotaBackend" -ErrorAction SilentlyContinue
sc.exe delete TonarotaBackend | Out-Null

# 3. Baixa e extrai o NSSM se não estiver presente
if (!(Test-Path $nssmExe)) {
    Write-Host "Baixando o NSSM..." -ForegroundColor Cyan
    $zipPath = "$binDir\nssm.zip"
    Invoke-WebRequest -Uri "https://nssm.cc/release/nssm-2.24.zip" -OutFile $zipPath

    Write-Host "Extraindo nssm.exe..." -ForegroundColor Cyan
    Expand-Archive -Path $zipPath -DestinationPath "$binDir\temp_nssm" -Force
    
    # Move o executável 64 bits para o local final
    Move-Item -Path "$binDir\temp_nssm\nssm-2.24\win64\nssm.exe" -Destination $nssmExe -Force
    
    # Limpa arquivos temporários
    Remove-Item -Path $zipPath -Force
    Remove-Item -Path "$binDir\temp_nssm" -Recurse -Force
}

# 4. Compila o servidor Dart para um executável autônomo (server.exe)
Write-Host "Compilando o servidor Dart para executável..." -ForegroundColor Cyan
Push-Location $workingDir
dart compile exe bin/server.dart -o bin/server.exe
Pop-Location

if (!(Test-Path $serverExe)) {
    Write-Host "Erro: Falha ao compilar o servidor Dart em $serverExe." -ForegroundColor Red
    return;
}
Write-Host "Servidor compilado com sucesso em: $serverExe" -ForegroundColor Gray

# 5. Instala o serviço oficial usando o NSSM apontando diretamente para o executável compilado
Write-Host "Instalando serviço oficial no Windows..." -ForegroundColor Cyan
cd $binDir
# Garante que o console use codificacao adequada se suportado
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
& .\nssm.exe install TonarotaBackend $serverExe
& .\nssm.exe set TonarotaBackend AppDirectory $workingDir
& .\nssm.exe set TonarotaBackend DisplayName "To Na Rota Backend"
& .\nssm.exe set TonarotaBackend Description "Servidor API Dart Shelf do To Na Rota"
& .\nssm.exe set TonarotaBackend AppStdout $workingDir\bin\service.log
& .\nssm.exe set TonarotaBackend AppStderr $workingDir\bin\service.log
& .\nssm.exe set TonarotaBackend Start SERVICE_AUTO_START

# 6. Inicia o serviço recém-criado
Write-Host "Iniciando o serviço no Windows..." -ForegroundColor Cyan
Start-Service -Name "TonarotaBackend"

Write-Host "--------------------------------------------------------" -ForegroundColor Green
Write-Host "Sucesso! O serviço 'To Na Rota Backend' foi instalado." -ForegroundColor Green
Write-Host "Você pode vê-lo agora abrindo o painel services.msc." -ForegroundColor Green
Write-Host "--------------------------------------------------------" -ForegroundColor Green
