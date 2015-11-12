
function Start-NancyRequestTracing(
        [Parameter(Mandatory=$True)][string]$BaseAppUrl,
        [Parameter(Mandatory=$True)][string]$Password) {
    $ErrorActionPreference = "Stop"
    Invoke-WebRequest -Uri $($BaseAppUrl + "/_Nancy") -Method "POST" -Body "Password=$Password" `
        -SessionVariable nancySession -UseBasicParsing | Out-Null
    Invoke-WebRequest -Uri $($BaseAppUrl + "/_Nancy/settings") -Method "POST" `
        -Body "Name=EnableRequestTracing&Value=true" -WebSession $nancySession -UseBasicParsing | Out-Null
}

function Stop-NancyRequestTracing(
        [Parameter(Mandatory=$True)][string]$BaseAppUrl,
        [Parameter(Mandatory=$True)][string]$Password) {
    $ErrorActionPreference = "Stop"
    Invoke-WebRequest -Uri $($BaseAppUrl + "/_Nancy") -Method "POST" -Body "Password=$Password" `
        -SessionVariable nancySession -UseBasicParsing | Out-Null
    Invoke-WebRequest -Uri $($BaseAppUrl + "/_Nancy/settings") -Method "POST" `
        -Body "Name=EnableRequestTracing&Value=false" -WebSession $nancySession -UseBasicParsing | Out-Null
}

function Read-NancyCollectedRequests(
        [Parameter(Mandatory=$True)][string]$BaseAppUrl,
        [Parameter(Mandatory=$True)][string]$Password,
        [switch]$ShowLogs = $false,
        [string]$SessionId = $null) {
    $ErrorActionPreference = "Stop"
    Invoke-WebRequest -Uri $($BaseAppUrl + "/_Nancy") -Method "POST" -Body "Password=$Password" `
        -SessionVariable nancySession -UseBasicParsing | Out-Null

    if ([string]::IsNullOrEmpty($SessionId)) {
        $resp = Invoke-WebRequest -Uri $($BaseAppUrl + "/_Nancy/trace/sessions") -Method "GET" `
            -WebSession $nancySession -UseBasicParsing
        $sessionIds = ConvertFrom-Json $resp.Content
    } else {
        $sessionIds = @($SessionId)
    }

    $sessionIds | % {
        Write-Host -ForegroundColor Yellow $("+Session: '" + $_.id + "'")
        $resp = Invoke-WebRequest -Uri $($BaseAppUrl + "/_Nancy/trace/sessions/" + $_.id) -Method "GET" `
            -WebSession $nancySession -UseBasicParsing
        $requests = ConvertFrom-Json $resp.Content
        $requests | % { printRequest $_ $ShowLogs }
    }
}

function printRequest($req, [bool]$showLog) {
    Write-Host "|-==============================================="
    Write-Host -ForegroundColor Cyan "|+>>> $($req.method) $($req.requestUrl.sitebase)$($req.requestUrl.path)$($req.requestUrl.query)"
    $req.requestHeaders | % {
        Write-Host $(" |-{0,20} : {1}" -f $_.key,[String]::Join(", ", $_.value))
    }
    $color = [ConsoleColor]::Yellow
    if ($req.statusCode -ge 200 -and $req.statusCode -lt 300) {
        $color = [ConsoleColor]::Green
    } elseif ($req.statusCode -ge 500) {
        $color = [ConsoleColor]::Red
    }

    if ($showLog) {
        Write-Host -ForegroundColor Magenta "|+<<< LOGS:"
        $req.log | % {
            Write-Host " |-$_"
        }
    }

    Write-Host -ForegroundColor $color "|+<<< HTTP: $($req.statusCode) $($req.responseContenType)"
    $req.responseHeaders | % {
        Write-Host " |-$_"
    }
}
