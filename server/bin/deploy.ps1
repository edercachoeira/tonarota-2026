# ============================================================
# deploy.ps1 — Script de Deploy e Atualização do Tô Na Rota
# ============================================================
# Compila o Flutter Web, recompila o server.exe e reinicia
# o serviço Windows automaticamente.
#
# USO:  .\server\bin\deploy.ps1
#       (Executar como ADMINISTRADOR no PowerShell)
# ============================================================

param (
    [switch]$SkipFlutter,    # Pula o build do Flutter Web
    [switch]$SkipServer,     # Pula a compilação do server.exe
    [switch]$SkipRestart     # Pula o restart do serviço
)

$ErrorActionPreference = "Stop"

# ─── Paths ──────────────────────────────────────────────────
$projectRoot = "e:\xampp\htdocs\tonarota-2026"
$serverDir   = "$projectRoot\server"
$binDir      = "$serverDir\bin"
$serverExe   = "$binDir\server.exe"
$serviceName = "TonarotaBackend"

# ─── Verifica Administrador ────────────────────────────────
$identity  = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
$isAdmin   = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host ""
    Write-Warning "ATENÇÃO: Este script precisa ser executado como ADMINISTRADOR."
    Write-Warning "Clique com o botão direito no PowerShell → Executar como Administrador."
    Write-Host ""
    exit 1
}

$startTime = Get-Date
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   🚀 Tô Na Rota — Deploy & Atualização         ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# ─── Etapa 1: Build do Flutter Web ─────────────────────────
if (-not $SkipFlutter) {
    Write-Host "📦 [1/3] Compilando Flutter Web..." -ForegroundColor Yellow
    Push-Location $projectRoot
    try {
        flutter build web --release --base-href "/app/"
        if ($LASTEXITCODE -ne 0) { throw "Flutter build falhou." }
        Write-Host "   ✅ Flutter Web compilado com sucesso." -ForegroundColor Green
    } catch {
        Write-Host "   ❌ Erro no build do Flutter: $_" -ForegroundColor Red
        Pop-Location
        exit 1
    }
    Pop-Location
} else {
    Write-Host "⏭️  [1/3] Build do Flutter Web pulado (--SkipFlutter)." -ForegroundColor DarkGray
}

# ─── Etapa 2: Compilação do server.exe ─────────────────────
if (-not $SkipServer) {
    Write-Host "🔧 [2/3] Compilando server.exe..." -ForegroundColor Yellow
    Push-Location $projectRoot
    try {
        dart compile exe server/bin/server.dart -o server/bin/server.exe
        if ($LASTEXITCODE -ne 0) { throw "Compilação do server.exe falhou." }
        Write-Host "   ✅ server.exe compilado com sucesso." -ForegroundColor Green
    } catch {
        Write-Host "   ❌ Erro na compilação do servidor: $_" -ForegroundColor Red
        Pop-Location
        exit 1
    }
    Pop-Location
} else {
    Write-Host "⏭️  [2/3] Compilação do server.exe pulada (--SkipServer)." -ForegroundColor DarkGray
}

# ─── Etapa 3: Reiniciar o Serviço Windows ──────────────────
if (-not $SkipRestart) {
    Write-Host "🔄 [3/3] Reiniciando serviço Windows '$serviceName'..." -ForegroundColor Yellow

    $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
    if (-not $service) {
        Write-Host "   ⚠️  Serviço '$serviceName' não encontrado. Instalando..." -ForegroundColor DarkYellow

        # Instala via NSSM
        $nssmExe = "$binDir\nssm.exe"
        if (Test-Path $nssmExe) {
            & $nssmExe install $serviceName $serverExe
            & $nssmExe set $serviceName AppDirectory $serverDir
            & $nssmExe set $serviceName DisplayName "To Na Rota Backend"
            & $nssmExe set $serviceName Description "Servidor API Dart Shelf do To Na Rota"
            & $nssmExe set $serviceName AppStdout "$binDir\service.log"
            & $nssmExe set $serviceName AppStderr "$binDir\service.log"
            & $nssmExe set $serviceName Start SERVICE_AUTO_START
            Write-Host "   ✅ Serviço instalado via NSSM." -ForegroundColor Green
        } else {
            Write-Host "   ❌ nssm.exe não encontrado em $nssmExe. Execute install_nssm_service.ps1 primeiro." -ForegroundColor Red
            exit 1
        }
    }

    # Para o serviço (espera liberar a porta)
    $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
    if ($service.Status -eq "Running") {
        Stop-Service -Name $serviceName -Force
        Write-Host "   ⏸️  Serviço parado." -ForegroundColor DarkGray
        Start-Sleep -Seconds 3
    }

    # Mata qualquer processo residual na porta 8080
    $portProcess = netstat -ano | findstr ":8080" | findstr "LISTENING"
    if ($portProcess) {
        $pid = ($portProcess -split '\s+')[-1]
        if ($pid -and $pid -ne "0") {
            Write-Host "   🔪 Matando processo residual PID $pid na porta 8080..." -ForegroundColor DarkYellow
            taskkill /F /PID $pid 2>$null
            Start-Sleep -Seconds 2
        }
    }

    # Inicia o serviço
    Start-Service -Name $serviceName
    Start-Sleep -Seconds 2

    $service = Get-Service -Name $serviceName
    if ($service.Status -eq "Running") {
        Write-Host "   ✅ Serviço '$serviceName' rodando." -ForegroundColor Green
    } else {
        Write-Host "   ❌ Falha ao iniciar o serviço. Status: $($service.Status)" -ForegroundColor Red
        Write-Host "   📄 Verifique o log: $binDir\service.log" -ForegroundColor DarkYellow
        exit 1
    }
} else {
    Write-Host "⏭️  [3/3] Restart do serviço pulado (--SkipRestart)." -ForegroundColor DarkGray
}

# ─── Resumo ────────────────────────────────────────────────
$elapsed = (Get-Date) - $startTime
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║   ✅ Deploy concluído com sucesso!              ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "   ⏱️  Tempo total: $([math]::Round($elapsed.TotalSeconds))s" -ForegroundColor Gray
Write-Host "   🌐 Landing Page: http://localhost:8080/" -ForegroundColor Gray
Write-Host "   📱 Flutter App:  http://localhost:8080/app/" -ForegroundColor Gray
Write-Host "   🔌 API:          http://localhost:8080/api/v1/" -ForegroundColor Gray
Write-Host ""
