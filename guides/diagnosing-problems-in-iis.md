---
layout: page
title: Diagnosing problems in IIS
---

WIP

**Table of contents:**

<!-- MarkdownTOC -->

- [Server Configuration](#server-configuration)
    - [List Worker Processes with their PIDs](#list-worker-processes-with-their-pids)
    - [Querying sites configuration](#querying-sites-configuration)
    - [Starting/Stopping sites](#startingstopping-sites)
- [Application pools](#application-pools)
    - [Security](#security)
- [Diagnostics cases](#diagnostics-cases)
    - [Hanging requests](#hanging-requests)
    - [Leaking handles](#leaking-handles)
    - [Creating a dump on a failed request](#creating-a-dump-on-a-failed-request)
    - [Diagnosing 401 Unauthorized: Access denied \(FREB\)](#diagnosing-401-unauthorized-access-denied-freb)
    - [Debugging w3wp process start](#debugging-w3wp-process-start)
- [Notes on IIS Express](#notes-on-iis-express)
    - [Configuration](#configuration)
    - [Running iisexpress on a reserved port \(lower than 1024\)](#running-iisexpress-on-a-reserved-port-lower-than-1024)
    - [Enabling SSH \(https\)](#enabling-ssh-https)
    - [Logging](#logging)

<!-- /MarkdownTOC -->

## Server Configuration

IIS7 is located in the `%systemroot%\system32\inetsrv` directory.

You can choose the framework version and type of pipe for an appdomain.

### List Worker Processes with their PIDs

    > appcmd list wp

    WP "11172" (applicationPool:DPRP)

### Querying sites configuration

    C:\Windows\system32>appcmd list site
    SITE "Default Web Site" (id:1,bindings:http/*:80:,state:Started)

    C:\Windows\system32>appcmd list site -id:3
    SITE "local-site" (id:3,bindings:http/*:8002,state:Stopped)

### Starting/Stopping sites

    C:\Windows\system32>appcmd start site "Default Web Site"
    "Default Web Site" successfully started.

## Application pools

### Security

Based on (<http://learn.iis.net/page.aspx/624/application-pool-identities/>)

Each application pool has different authentication settings (account name are in the form of `IIS APPPOOL\apppoolname`). To configure access for a folder you need to specify valid security settings for a user: "IIS AppPool\DefaultAppPool".

## Diagnostics cases

### Hanging requests

After <http://mvolo.com/troubleshoot-iis-hanging-requests/>

You can start diagnosis by looking at requests which last longer than 1s:

```
%windir%\system32\inetsrv\appcmd list requests /elapsed:1000

REQUEST "7000000780000548" (url:GET /test.aspx, time:30465 msec, client:localhost, stage:ExecuteRequestHandler, module:ManagedPipelineHandler)
REQUEST "f200000280000777" (url:GET /test.aspx, time:29071 msec, client:localhost, stage:ExecuteRequestHandler, module:ManagedPipelineHandler)
...
REQUEST "6f00000780000567" (url:GET /, time:1279 msec, client:localhost, stage:AuthenticateRequest, module:WindowsAuthentication)
REQUEST "7500020080000648" (url:GET /login, time:764 msec, client:localhost, stage:AuthenticateRequest, module:WindowsAuthentication)
```

Then check **Http Service Request Queues\\CurrentQueueSize** and **W3WP\_W3SVC\\Active Threads** counters - normally, they should be small numbers.

**Run tracing for selected requests**:

```
%windir%\system32\inetsrv\appcmd configure trace "Default Web Site" /enablesite
%windir%\system32\inetsrv\appcmd configure trace "Default Web Site" /enable /path:test.aspx /timeTaken:00:00:30
```

Then, after a while find collected traces:

    appcmd list traces | findstr "test.aspx"

After having found the trace it's time to see it:

    appcmd list traces "Default Web Site/fr000003.xml" /text:path > temp.bat && temp.bat

### Leaking handles

Based on <http://blogs.msdn.com/b/friis/archive/2013/01/14/iis-7-7-5-et-la-g-233-n-233-ration-d-un-log-handle-suite-224-une-erreur-500-provoqu-233-e-par-un-lock-que-personne-ne-semble-d-233-tenir.aspx>

Get settings configured in freb-handle-leaking\web.config. Then enable customActions in applicationhost.config:

    appcmd.exe set config -section:system.applicationHost/sites "/[name='NomDeVotreSite'].traceFailedRequestsLogging.customActionsEnabled:"true"" /commit:apphost

In order to run handle you need to set ApplicationPook identity to Local System. You also need to set rights for the Local System account to Load and unload device drivers (gpedit.msc -> Computer Configuration -> Windows Settings -> Security Settings -> Local Policies -> User Rights Assignments).

### Creating a dump on a failed request

Based on <http://blogs.msdn.com/b/benjaminperkins/archive/2013/12/02/using-procdump-and-failed-request-tracing-to-capture-a-memory-dump.aspx>

After having configured Failed Request Tracing for a given web site we may configure procdump to make a dump when request fails. The following settings configure this behavior:

- customActionExe: c:\windows\system32\procdump.exe
- customActionParams: -accepteula –ma %1% c:\dump
- customActionTriggerLimit: 50
- path: *

### Diagnosing 401 Unauthorized: Access denied (FREB)

To enable tracing for 401 error use the following code in web.config:

```xml
<system.webServer>
    <tracing>
        <traceFailedRequests>
            <remove path="*.asp" />
            <add path="*">
                <traceAreas>
                    <add provider="ASP" verbosity="Verbose" />
                    <add provider="ASPNET" areas="Infrastructure,Module,Page,AppServices" verbosity="Verbose" />
                    <add provider="ISAPI Extension" verbosity="Verbose" />
                    <add provider="WWW Server" areas="Authentication,Security,Filter,StaticFile,CGI,Compression,Cache,RequestNotifications,Module,FastCGI" verbosity="Verbose" />
                </traceAreas>
                <failureDefinitions statusCodes="401" />
            </add>
        </traceFailedRequests>
    </tracing>
</system.webServer>
```

### Debugging w3wp process start

Based on <http://blogs.msdn.com/b/webdev/archive/2013/11/15/asp-net-performance-debugging-w3wp-startup.aspx>

You can achieve that by using Image Execution Options:

```
reg add "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\w3wp.exe" /v Debugger /t REG_SZ /d "cdb.exe -c \".server tcp:port=9999\"" /f
iisreset /restart
start /b tinyget5 -srv:localhost -uri:/notfound.aspx -status:404
sleep 3
windbg -remote tcp:port=9999,server=localhost
pskill cdb
pskill w3wp
reg delete "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\w3wp.exe" /f
```

## Notes on IIS Express

IIS Express runs as a SINGLE process and it's NOT POSSIBLE to host multiple virtual application with different .NET versions under the same site (only one .NET version will be loaded).

### Configuration

Global variables in IIS Express:

- `%IIS_BIN%` - referes to IIS Express folder of the currently executing IIS express instance
- `%IIS_USER_HOME%` - %userprofile%\documents\iisexpress\
- `%IIS_SITES_HOME%` - %userprofile%\documents\my web sites

### Running iisexpress on a reserved port (lower than 1024)

Allow any user to run iisexpress on the 80 port:

    netsh http add urlacl url=http://localhost:80/ user=everyone

Add binding configuration:

    <binding protocol="http" bindingInformation="*:80:localhost"/>

To remove the configuration run:

    netsh http delete urlacl url=http://localhost:80/

### Enabling SSH (https)

Based on <http://www.hanselman.com/blog/WorkingWithSSLAtDevelopmentTimeIsEasierWithIISExpress.aspx>

You may use the self-signed IIS Express certificate:

    certmgr.exe /c /s /r localMachine MY

By default IIS Express registers bindings for all the ports starting from 44301 till 44399 with its certificate. You may list them using:

    netsh http show sslcert

or create a new certificate, eg.:

    makecert -r -pe -n "CN=HANSELMAN-W500" -b 01/01/2000 -e 01/01/2036 -eku 1.3.6.1.5.5.7.3.1 -ss my -sr localMachine -sky exchange -sp "Microsoft RSA SChannel Cryptographic Provider" -sy 12

Then you need to get its SHA1 hash (thumbprint) and register it in http.sys (if in powershell remember about escaping {}):

    netsh http add sslcert ipport=0.0.0.0:443 appid={214124cd-d05b-4309-9af9-9caa44b2b74a} certhash=YOURCERTHASHHERE

To delete registration use `netsh http delete sslcert ipport=YOURIPPORT`.

If you would like to run the iisexpress on non-privileged account you may also add an urlacl:

    netsh http add urlacl url=https://localhost:443/ user=everyone

Finally you can add binding for your site to the applicationHost.config, eg.:

```xml
<site name="MvcApplication18" id="39">
  <application path="/" applicationPool="Clr4IntegratedAppPool">
     <virtualDirectory path="/" physicalPath="c:\users\scottha\documents\visual studio 2010\Projects\MvcApplication18\MvcApplication18" />
  </application>
  <bindings>
    <binding protocol="http" bindingInformation="*:15408:localhost" />
    <binding protocol="https" bindingInformation="*:44302:localhost" />
    <binding protocol="http" bindingInformation="*:80:hanselman-w500" />
    <binding protocol="https" bindingInformation="*:443:hanselman-w500" />
  </bindings>
</site>
```

### Logging

You can enable tracing by using the **/trace** switch. Following values are accepted: 'none', 'n', 'info', 'i', 'warning', 'w', 'error', and 'e'. W3C logs are stored in the `%IIS_USER_HOME%\Logs` folder and tracing logs can be found in `%IIS_USER_HOME%\TraceLogFiles`.
