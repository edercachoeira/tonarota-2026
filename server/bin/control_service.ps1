param (
    [Parameter(Mandatory=$true)]
    [ValidateSet("start", "stop", "restart", "status")]
    [string]$action
)

$serviceName = "TonarotaBackend"

# Verifica privilégios de Administrador
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (!$isAdmin) {
    Write-Warning "Este script deve ser executado como ADMINISTRADOR para controlar serviços."
    if ($action -ne "status") {
        return
    }
}

switch ($action) {
    "start" {
        Write-Host "Iniciando o serviço $serviceName..." -ForegroundColor Cyan
        Start-Service -Name $serviceName
        Write-Host "Serviço iniciado com sucesso." -ForegroundColor Green
    }
    "stop" {
        Write-Host "Parando o serviço $serviceName..." -ForegroundColor Yellow
        Stop-Service -Name $serviceName
        Write-Host "Serviço parado com sucesso." -ForegroundColor Green
    }
    "restart" {
        Write-Host "Reiniciando o serviço $serviceName..." -ForegroundColor Cyan
        Restart-Service -Name $serviceName
        Write-Host "Serviço reiniciado com sucesso." -ForegroundColor Green
    }
    "status" {
        $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
        if ($service) {
            Write-Host "Nome do Serviço:   $($service.DisplayName)" -ForegroundColor White
            Write-Host "Status Atual:      $($service.Status)" -ForegroundColor (if ($service.Status -eq "Running") { "Green" } else { "Red" })
        } else {
            Write-Host "Serviço '$serviceName' não encontrado. Certifique-se de que foi instalado." -ForegroundColor Red
        }
    }
}

