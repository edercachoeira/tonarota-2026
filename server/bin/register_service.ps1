# Script para registrar o backend do Tô Na Rota como um serviço em segundo plano no Windows
# IMPORTANTE: Deve ser executado em um terminal PowerShell como Administrador.

$taskName = "TonarotaBackend"
$workingDir = "e:\xampp\htdocs\tonarota-2026\server"
$dartPath = "dart.exe"

# 1. Define a ação de execução (chama o dart run apontando para o diretório correto)
$action = New-ScheduledTaskAction -Execute $dartPath -Argument "run bin/server.dart" -WorkingDirectory $workingDir

# 2. Define o gatilho para iniciar automaticamente com o Windows (AtStartup)
$trigger = New-ScheduledTaskTrigger -AtStartup

# 3. Configurações de resiliência e energia
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

# 4. Registra a tarefa para rodar como SYSTEM (roda invisível em segundo plano)
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Description "Servidor API Dart Shelf do To Na Rota" -User "NT AUTHORITY\SYSTEM" -Force

Write-Host "--------------------------------------------------------" -ForegroundColor Green
Write-Host "Serviço '$taskName' registrado com sucesso no Windows!" -ForegroundColor Green
Write-Host "Use o control_service.ps1 para iniciar, parar ou reiniciar." -ForegroundColor Yellow
Write-Host "--------------------------------------------------------" -ForegroundColor Green
