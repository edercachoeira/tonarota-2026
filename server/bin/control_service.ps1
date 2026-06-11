param (
    [Parameter(Mandatory=$true)]
    [ValidateSet("start", "stop", "restart", "status")]
    [string]$action
)

$taskName = "TonarotaBackend"

switch ($action) {
    "start" {
        Write-Host "Iniciando o serviço $taskName..." -ForegroundColor Cyan
        Start-ScheduledTask -TaskName $taskName
        Write-Host "Serviço iniciado com sucesso." -ForegroundColor Green
    }
    "stop" {
        Write-Host "Parando o serviço $taskName..." -ForegroundColor Yellow
        Stop-ScheduledTask -TaskName $taskName
        Write-Host "Serviço parado com sucesso." -ForegroundColor Green
    }
    "restart" {
        Write-Host "Reiniciando o serviço $taskName..." -ForegroundColor Cyan
        Stop-ScheduledTask -TaskName $taskName
        Start-ScheduledTask -TaskName $taskName
        Write-Host "Serviço reiniciado com sucesso." -ForegroundColor Green
    }
    "status" {
        $task = Get-ScheduledTask -TaskName $taskName
        Write-Host "Nome da Tarefa: $($task.TaskName)" -ForegroundColor White
        Write-Host "Status Atual:   $($task.State)" -ForegroundColor (if ($task.State -eq "Running") { "Green" } else { "Red" })
    }
}
