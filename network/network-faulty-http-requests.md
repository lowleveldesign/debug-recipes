
Diagnosing HTTP requests
========================

### Find a faulty web server in a farm ###

Let's assume that we have a web farm composed of four IIS servers which serve requests to our application hosted under the address: http://test.example.com. One day customers start complaining that sometimes a request to http://test.example.com/test-request is failing. Our immediate assumption is that one of our servers is failing. The script below may be used to sent a request to all the servers at once and find the faulty one:

```powershell
@("192.168.1.10", "192.168.1.11", "192.168.1.12", "192.168.1.13") | % {
  $srv = $_; Write-Host "Connecting with $srv"; try {
    $resp = Invoke-WebRequest -UseBasicParsing -Headers @{ Host="test.example.com" } -Method GET http://$srv/;
    Write-Host -ForegroundColor Green "Request successful ($($resp.StatusCode) $($resp.StatusDescription))"
  } catch [System.Net.WebException] { Write-Host -ForegroundColor Red $_.Exception.Message } }
```

Example output may look as follows:

```
Connecting with 192.168.1.10
The remote server returned an error: (403) Forbidden.
Connecting with 194.168.1.11
Request successful (200 OK)
Connecting with 194.168.1.12
Request successful (200 OK)
Connecting with 194.168.1.13
Request successful (200 OK)
```
