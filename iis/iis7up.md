
IIS (7.0 and up)
================

Server Configuration
--------------------

IIS7 is located in the `%systemroot%\system32\inetsrv` directory.

You can choose the framework version and type of pipe for an appdomain.

### List Worker Processes with their PIDs ###

    > appcmd list wp

    WP "11172" (applicationPool:DPRP)

### Querying sites configuration ###

    C:\Windows\system32>appcmd list site
    SITE "Default Web Site" (id:1,bindings:http/*:80:,state:Started)

    C:\Windows\system32>appcmd list site -id:3
    SITE "local-site" (id:3,bindings:http/*:8002,state:Stopped)

### Starting/Stopping sites ###

    C:\Windows\system32>appcmd start site "Default Web Site"
    "Default Web Site" successfully started.

Application pools
-----------------

### Security ###

Based on (<http://learn.iis.net/page.aspx/624/application-pool-identities/>)

Each application pool has different authentication settings (account name are in the form of `IIS APPPOOL\apppoolname`). To configure access for a folder you need to specify valid security settings for a user: "IIS AppPool\DefaultAppPool".

Diagnostics cases
-----------------

### Handle hangs ###

Based on: <https://www.leansentry.com/Guide/IIS-AspNet-Hangs>

You can start diagnosis by looking at requests which last longer than 1s:

    %windir%\system32\inetsrv\appcmd list requests /elapsed:10000

    REQUEST "7000000780000548" (url:GET /test.aspx, time:30465 msec, client:localhost, stage:ExecuteRequestHandler, module:ManagedPipelineHandler)
    REQUEST "f200000280000777" (url:GET /test.aspx, time:29071 msec, client:localhost, stage:ExecuteRequestHandler, module:ManagedPipelineHandler)
    ...
    REQUEST "6f00000780000567" (url:GET /, time:1279 msec, client:localhost, stage:AuthenticateRequest, module:WindowsAuthentication)
    REQUEST "7500020080000648" (url:GET /login, time:764 msec, client:localhost, stage:AuthenticateRequest, module:WindowsAuthentication)

Then check **Http Service Request Queues\\CurrentQueueSize** and **W3WP\_W3SVC\\Active Threads** counters - they should not be much greater than 0. Finally you can check thread stacks in order to find the code which is blocking.

### Hanging requests ###

After <http://mvolo.com/troubleshoot-iis-hanging-requests/>

First, **dump hanging requests**:

    %windir%\system32\inetsrv\appcmd list requests /elapsed:30000

**Run tracing for selected requests**:

    %windir%\system32\inetsrv\appcmd configure trace "Default Web Site" /enablesite
    %windir%\system32\inetsrv\appcmd configure trace "Default Web Site" /enable /path:test.aspx /timeTaken:00:00:30

Then, after a while find collected traces:

    appcmd list traces | findstr "test.aspx"

After having found the trace it's time to see it:

    appcmd list traces "Default Web Site/fr000003.xml" /text:path > temp.bat && temp.bat

### Diagnose handle leaking (FREB) ###

from <http://blogs.msdn.com/b/friis/archive/2013/01/14/iis-7-7-5-et-la-g-233-n-233-ration-d-un-log-handle-suite-224-une-erreur-500-provoqu-233-e-par-un-lock-que-personne-ne-semble-d-233-tenir.aspx>

Get settings configured in freb-handle-leaking\web.config. Then enable customActions in applicationhost.config:

    appcmd.exe set config -section:system.applicationHost/sites "/[name='NomDeVotreSite'].traceFailedRequestsLogging.customActionsEnabled:"true"" /commit:apphost

In order to run handle you need to set ApplicationPook identity to Local System. You also need to set rights for the Local System account to Load and unload device drivers (gpedit.msc -> Computer Configuration -> Windows Settings -> Security Settings -> Local Policies -> User Rights Assignments).

### Creating a dump on failed request (FREB) ###

Based on <http://blogs.msdn.com/b/benjaminperkins/archive/2013/12/02/using-procdump-and-failed-request-tracing-to-capture-a-memory-dump.aspx>

After having configured Failed Request Tracing for a given web site we may configure procdump to make a dump when request fails. The following settings configure this behavior:

- customActionExe: c:\windows\system32\procdump.exe
- customActionParams: -accepteula –ma %1% c:\dump
- customActionTriggerLimit: 50
- path: *

### Diagnose 401 Unauthorized: Access denied (FREB) ###

To enable tracing for 401 error use the following code in web.config:

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

### Debugging w3wp process start ###

Based on <http://blogs.msdn.com/b/webdev/archive/2013/11/15/asp-net-performance-debugging-w3wp-startup.aspx>

You can achieve that by using Image Execution Options:

    reg add "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\w3wp.exe" /v Debugger /t REG_SZ /d "cdb.exe -c \".server tcp:port=9999\"" /f
    iisreset /restart
    start /b tinyget5 -srv:localhost -uri:/notfound.aspx -status:404
    sleep 3
    windbg -remote tcp:port=9999,server=localhost
    pskill cdb
    pskill w3wp
    reg delete "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\w3wp.exe" /f


Common problems
---------------

### Urls containing + return 404 ###

IIS7+ does not allow + to be present in urls unless doubleescaping is enabled.

Reading IIS logs
-----------------

### Using logparser ###

    select * from logfile | <websitename>

website name requires IIS 6 Metadata to be installed on the machine. Some links how to use it:

- Troubleshooting IIS Performance Issues or Application Errors using LogParser: <http://www.iis.net/learn/troubleshoot/performance-issues/troubleshooting-iis-performance-issues-or-application-errors-using-logparser>
- API usage: IIS Logs for Performance Testing with Visual Studio <http://geekswithblogs.net/TarunArora/archive/2012/07/04/using-iis-logs-for-performance-testing-with-visual-studio.aspx>

Links
-----

- [Monitor activity of the web server](http://technet.microsoft.com/en-us/library/cc730608(v=ws.10).aspx)
- [IIS 7.0, ASP.NET, pipelines, modules, handlers, and preconditions](http://blogs.msdn.com/b/tmarq/archive/2007/08/30/iis-7-0-asp-net-pipelines-modules-handlers-and-preconditions.aspx)
- [Debugging your custom FTP authentication provider module](https://blogs.msdn.microsoft.com/friis/2016/01/18/debugging-your-custom-ftp-authentication-provider-module/)
- [Hardening IIS Security](http://resources.infosecinstitute.com/hardening-iis-security/)
- [IIS Error Codes](http://support.microsoft.com/kb/943891)
- [It’s not IIS](http://blogs.msdn.com/b/benjaminperkins/archive/2013/02/01/it-s-not-iis.aspx)
- [Becoming a Web Pro Black Belt – Mastering IIS and Other Essential Web Technologies](http://dotnetslackers.com/projects/LearnIIS7/)
- [Troubleshooting, diagnosing, debugging](http://learn.iis.net/page.aspx/1099/troubleshooters/)
- [Troubleshooting Failed Requests Using Tracing in IIS 7](http://learn.iis.net/page.aspx/266/troubleshooting-failed-requests-using-tracing-in-iis-7/)
- [IIS 7/7.5 et la génération d’un log Handle suite a une erreur 500 provoquée par un lock que personne ne semble détenir](http://blogs.msdn.com/b/friis/archive/2013/01/14/iis-7-7-5-et-la-g-233-n-233-ration-d-un-log-handle-suite-224-une-erreur-500-provoqu-233-e-par-un-lock-que-personne-ne-semble-d-233-tenir.aspx)
- [Using FREB to generate a dump on a long running request](http://blogs.msdn.com/b/friis/archive/2010/05/11/using-freb-to-generate-a-dump-on-a-long-running-request.aspx)
- <http://jeffgraves.me/2012/06/11/troubleshooting-arr-503-2-erros/>
- <http://learn.iis.net/page.aspx/1167/troubleshooting-502-errors-in-arr/>
- [Response 400 (Bad Request) on Long Url](http://blogs.msdn.com/b/amyd/archive/2014/02/06/response-400-bad-request-on-long-url.aspx)
- [Configure Debug Diagnostic 2.0 to create a memory dump when a specific exception is thrown](http://blogs.msdn.com/b/benjaminperkins/archive/2014/04/01/configure-debug-diagnostic-2-0-to-create-a-memory-dump-when-a-specific-exception-is-thrown.aspx)
- [Collecting a memory dump with ProcDump when ASP.NET ISAPI is reported unhealthy or deadlock detected in an ASP.NET application](http://blogs.msdn.com/b/amb/archive/2015/11/06/collect-dump-with-procdump-when-asp.net-unhealthy-or-deadlock-detected.aspx)
- [IIS 8.5 ETW Logging - library to collect W3VC ETW events](https://github.com/tomasr/iis-etw-tracing)
- [Description of the registry keys that are used by IIS 7.0, IIS 7.5, and IIS 8.0](https://support.microsoft.com/en-us/kb/954864)

### Tutorials and labs ###

- [IIS Debugging Labs – Information and setup instructions](https://blogs.msdn.microsoft.com/benjaminperkins/2016/07/15/iis-debugging-labs-information-and-setup-instructions/)

### Tools ###

- [FREBViewer – yet another FREB files viewer](http://blogs.msdn.com/b/rakkimk/archive/2011/09/28/frebviewer-yet-another-freb-files-viewer.aspx)
- [Troubleshooting IIS Performance Issues or Application Errors using LogParser](http://www.iis.net/learn/troubleshoot/performance-issues/troubleshooting-iis-performance-issues-or-application-errors-using-logparser)

### FTP ###

- [FTP ETW Tracing and IIS 8](http://blogs.iis.net/robert_mcmurray/archive/2014/04/08/ftp-etw-tracing-and-iis-8.aspx)
- [FTP ETW Tracing and IIS 8 - Part 2](http://blogs.iis.net/robert_mcmurray/archive/2014/04/09/ftp-etw-tracing-and-iis-8-part-2.aspx)

### Failed Request Tracing ###

- <http://www.iis.net/ConfigReference/system.webServer/tracing/traceFailedRequests>
- <http://www.codeguru.com/csharp/.net/net_asp/tutorials/article.php/c16775>
- <http://learn.iis.net/page.aspx/266/troubleshooting-failed-requests-using-tracing-in-iis/>
- <http://learn.iis.net/page.aspx/488/using-failed-request-tracing-rules-to-troubleshoot-application-request-routing-arr/>
- [Enlightening a mystery with Failed Request Tracing: does IIS not respect the minFileSizeForComp setting for static compression?](https://blogs.msdn.microsoft.com/amb/2016/05/23/iis-respects-minfilesizeforcomp-for-static-compression/)

### Url rewrite module ###

- <http://blogs.iis.net/bills/archive/2008/05/31/urlrewrite-module-for-iis7.aspx>
- <http://www.iis.net/download/urlrewrite>

