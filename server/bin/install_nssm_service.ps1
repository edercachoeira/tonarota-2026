# Script para instalar o backend do Tô Na Rota como serviço oficial do Windows no services.msc
# IMPORTANTE: Executar no PowerShell como ADMINISTRADOR.

$workingDir = "e:\xampp\htdocs\tonarota-2026\server"
$binDir = "$workingDir\bin"

# 1. Remove a tarefa agendada anterior (se existir)
Write-Host "Removendo tarefa agendada anterior..." -ForegroundColor Yellow
Unregister-ScheduledTask -TaskName "TonarotaBackend" -Confirm:$false -ErrorAction SilentlyContinue

# 2. Para e remove o serviço antigo (se já existir para reinstalação limpa)
Write-Host "Parando serviço antigo (se houver)..." -ForegroundColor Yellow
Stop-Service -Name "TonarotaBackend" -ErrorAction SilentlyContinue
sc.exe delete TonarotaBackend | Out-Null

# 3. Baixa e extrai o NSSM se não estiver presente
$nssmExe = "$binDir\nssm.exe"
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

# 4. Localiza o executavel do Dart no sistema
$dartCmd = Get-Command dart -ErrorAction SilentlyContinue
if (!$dartCmd) {
    Write-Host "Erro: Executavel do Dart nao localizado no PATH." -ForegroundColor Red
    return;
}
$dartPath = $dartCmd.Source
if ($dartPath -like "*.bat" -or $dartPath -like "*.cmd") {
    # Se for o bat do Flutter, busca o executavel nativo no cache do SDK
    $sdkDart = Join-Path (Split-Path $dartPath -Parent) "cache\dart-sdk\bin\dart.exe"
    if (Test-Path $sdkDart) {
        $dartPath = $sdkDart
    }
}
Write-Host "Dart localizado em: $dartPath" -ForegroundColor Gray

# 5. Instala o servico oficial usando o NSSM
Write-Host "Instalando servico oficial no Windows..." -ForegroundColor Cyan
cd $binDir
# Garante que o console use codificacao adequada se suportado
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
& .\nssm.exe install TonarotaBackend "`"$dartPath`"" "run bin/server.dart"
& .\nssm.exe set TonarotaBackend AppDirectory "`"$workingDir`""
& .\nssm.exe set TonarotaBackend DisplayName "To Na Rota Backend"
& .\nssm.exe set TonarotaBackend Description "Servidor API Dart Shelf do To Na Rota"
& .\nssm.exe set TonarotaBackend AppStdout "$workingDir\bin\service.log"
& .\nssm.exe set TonarotaBackend AppStderr "$workingDir\bin\service.log"
& .\nssm.exe set TonarotaBackend Start SERVICE_AUTO_START

# 6. Inicia o servico recem-criado
Write-Host "Iniciando o servico no Windows..." -ForegroundColor Cyan
Start-Service -Name "TonarotaBackend"

Write-Host "--------------------------------------------------------" -ForegroundColor Green
Write-Host "Sucesso! O servico 'To Na Rota Backend' foi instalado." -ForegroundColor Green
Write-Host "Voce pode ve-lo agora abrindo o painel services.msc." -ForegroundColor Green
Write-Host "--------------------------------------------------------" -ForegroundColor Green
