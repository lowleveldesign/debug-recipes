
param([Parameter(Mandatory=$True)][string]$BaseAppUrl, [Parameter(Mandatory=$True)][string]$Password)

$modulePath = Join-Path $(Split-Path $MyInvocation.MyCommand.Path) "NancyModule"

Import-Module $modulePath

Start-NancyRequestTracing -BaseAppUrl $BaseAppUrl -Password $Password
Write-Host "Request tracing is now enabled. Press any key to stop recording..."
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

Write-Host "Recoding stopped. Reading collected traces..."
Stop-NancyRequestTracing -BaseAppUrl $BaseAppUrl -Password $Password
Read-NancyCollectedRequests  -BaseAppUrl $BaseAppUrl -Password $Password -ShowLogs

Write-Host "Press any key to continue..."
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
