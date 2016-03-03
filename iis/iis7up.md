
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

Links
-----

- [Monitor activity of the web server](http://technet.microsoft.com/en-us/library/cc730608(v=ws.10).aspx)
- [IIS 7.0, ASP.NET, pipelines, modules, handlers, and preconditions](http://blogs.msdn.com/b/tmarq/archive/2007/08/30/iis-7-0-asp-net-pipelines-modules-handlers-and-preconditions.aspx)
- [Debugging your custom FTP authentication provider module](https://blogs.msdn.microsoft.com/friis/2016/01/18/debugging-your-custom-ftp-authentication-provider-module/)
- [Hardening IIS Security](http://resources.infosecinstitute.com/hardening-iis-security/)

### Failed Request Tracing ###

- <http://www.iis.net/ConfigReference/system.webServer/tracing/traceFailedRequests>
- <http://www.codeguru.com/csharp/.net/net_asp/tutorials/article.php/c16775>
- <http://learn.iis.net/page.aspx/266/troubleshooting-failed-requests-using-tracing-in-iis/>
- <http://learn.iis.net/page.aspx/488/using-failed-request-tracing-rules-to-troubleshoot-application-request-routing-arr/>

### Url rewrite module ###

- <http://blogs.iis.net/bills/archive/2008/05/31/urlrewrite-module-for-iis7.aspx>
- <http://www.iis.net/download/urlrewrite>

