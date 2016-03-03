
IIS6 Usage notes
================

General info
------------

The installation path: `c:\Windows\System32\inetsrv` contains main IIS excecutables: w3wp.exe, inetpub.exe as well as the administration console snippet.

In `C:\Windows\system32` we can find scripts to administer IIS services:

    iisapp.vbs
    iisback.vbs
    IIsCnfg.vbs
    iisext.vbs
    IIsFtp.vbs
    IIsFtpdr.vbs
    iismap.dll
    iismui.dll
    iisreset.exe
    iisrstap.dll
    iisRtl.dll
    IIsScHlp.wsc
    iissuba.dll
    iisvdir.vbs
    iisweb.vbs

In case you have problems executing the above commands, set the default script engine to cscript:

    cscript //h:cscript //s

### Metabase ###

Metabase.xml is stored in `C:\WINDOWS\system32\inetsrv`

Tracing
-------

Based on <http://www.microsoft.com/technet/prodtechnol/WindowsServer2003/Library/IIS/5f5bd256-7d1f-4239-9a7f-8eea4072fcb3.mspx?mfr=true>.

To create a useful trace session it's best to prepare a providers configuration file that will be useful in your situation. There are numerous providers that you can use (description in other file):

    Provider                                 GUID
    -------------------------------------------------------------------------------
    IIS: WWW Global                          {d55d3bc9-cba9-44df-827e-132d3a4596c2}
    IIS: WWW Server                          {3a2a4e84-4c21-4981-ae10-3fda0d9b0f83}
    IIS: Request Monitor                     {3b7b0b4b-4b01-44b4-a95e-3c755719aebf}
    IIS: Active Server Pages (ASP)           {06b94d9a-b15e-456e-a4ef-37c984a2cb4b}
    IIS: WWW Isapi Extension                 {a1c2040e-8840-4c31-ba11-9871031a19ea}
    ASP.NET Events                           {AFF081FE-0247-4275-9C4E-021F3DC1DA35}
    IIS: IISADMIN Global                     {DC1271C2-A0AF-400f-850C-4E42FE16BE1C}
    IIS: SSL Filter                          {1fbecc45-c060-4e7c-8a0e-0dbd6116181b}
    HTTP Service Trace                       {dd5ef90a-6398-47a4-ad34-4dcecdef795f}

### Starting/stopping trace session ###

The steps described below are included in a script file: `collect-iis-trace.bat`.

Start sample tracing session (<http://www.microsoft.com/technet/prodtechnol/WindowsServer2003/Library/IIS/b0f48764-9df2-4d4f-9746-2601e336f0ad.mspx?mfr=true>):

    C:\temp>logman start iiss -pf providers.guids -o C:\temp\iiss.etl -ets

    Name:                      iiss
    Age Limit:                 15
    Buffer Size:               8
    Buffers Written:           1
    Clock Type:                System
    Events Lost:               0
    Flush Timer:               0
    Buffers Free:              2
    Buffers Lost:              0
    File Mode:                 Sequential
    File Name:                 C:\temp\iiss.etl
    Logger Id:                 3
    Logger Thread Id:          2792
    Maximum Buffers:           25
    Maximum File Size:         0
    Minimum Buffers:           3
    Number of buffers:         3
    Real Time Buffers Lost:    0

    Provider                                  Flags                     Level
    -------------------------------------------------------------------------------
    * "IIS: WWW Server"                       (IISAuthentication,IISSecurity,IISFilter,IISStaticFile,IIS
    CGI,IISCompression,IISCache,IISAll)  0x05
      {3A2A4E84-4C21-4981-AE10-3FDA0D9B0F83}  0xfffffffe                0x05

    * "IIS: WWW Isapi Extension"              0x00000000                0x05
      {A1C2040E-8840-4C31-BA11-9871031A19EA}  0x00000000                0x05

    * "ASP.NET Events"                        (Infrastructure,Module,Page,AppServices)  0x05
      {AFF081FE-0247-4275-9C4E-021F3DC1DA35}  0x0000000f                0x05


    The command completed successfully.

providers.guid:

    "IIS: WWW Server" 0xFFFFFFFE 5
    "IIS: Active Server Pages (ASP)" 0 5
    "IIS: WWW Isapi Extension" 0 5
    "ASP.NET Events" 0xF 5

And stop trace session:

    C:\temp>logman stop iiss -ets
    The command completed successfully.


#### Using Performance and Alerts MMC ####

<http://www.microsoft.com/technet/prodtechnol/WindowsServer2003/Library/IIS/d3dc70ba-63b8-4671-be9f-b90c50210d4d.mspx?mfr=true>

### Trace for specific URL ###

<http://www.microsoft.com/technet/prodtechnol/WindowsServer2003/Library/IIS/c56d19af-b3d1-4be9-8a6f-4aa86bacac3f.mspx?mfr=true>

To trace only requests for a specific URL you need to first navigate to the `%windir%\Inetpub\AdminScripts` directory and issue:

     adsutil.vbs set w3svc/n/TraceUriPrefix=path

 where **n** is a page number and **path** represents a physical path to the requested file, eg.

    C:\Inetpub\AdminScripts>iisweb /query
    Connecting to server ...Done.
    Site Name (Metabase Path)                     Status  IP              Port

    ============================================================================
    Default Web Site (W3SVC/1)                    STARTED ALL             80
    security test (W3SVC/1716510118)              STARTED ALL             8090
    Elmahr (W3SVC/893604675)                      STARTED ALL             8080

    C:\Inetpub\AdminScripts>cscript adsutil.vbs set W3SVC/1716510118/TraceUriPrefix "c:\websites\sectest\Test.aspx"
    Microsoft (R) Windows Script Host Version 5.6
    Copyright (C) Microsoft Corporation 1996-2001. All rights reserved.

    TraceUriPrefix                  : (LIST) "c:\websites\sectest\Test.aspx"

Now we need to modify the providers file to use just the URL filtering:

    "IIS: WWW Server" UseUrlFilter 5

or 0xFF to enable all flags.

### How to Trace All Requests Currently Executing in IIS Worker Processes (IIS 6.0) ###

<http://www.microsoft.com/technet/prodtechnol/WindowsServer2003/Library/IIS/a67292e1-41e5-40d1-934f-04aa48d17d54.mspx?mfr=true>

### IIS tracing events ###

All events enlisted <http://www.microsoft.com/technet/prodtechnol/WindowsServer2003/Library/IIS/757a3990-d8ae-4d72-94af-70fa46edc985.mspx?mfr=true>

IIS 6 Logging
-------------

Events are logged by HTTP.sys.

### Links ###

- Troubleshooting IIS 6.0: <http://technet.microsoft.com/en-us/library/cc737109(v=ws.10).aspx>
- Analyzing Log Files: <http://technet.microsoft.com/en-us/library/cc779746(v=ws.10).aspx>
- Error logging in HTTP APIs: <http://support.microsoft.com/?id=820729>
- IISRESET Internals <http://blogs.msdn.com/b/friis/archive/2013/10/08/iisreset-internals.aspx>

Administation
-------------

### Configuration ###

You can configure multiple sites to listen on the same TCP port, but in that case you need to specify the host header value. Server based on this setting will serve the valid page for a request. To test this setting you may use `wget`, ex.:

    > wget -d --spider -S --header "Host: test.diagnostyka.pl" http://172.20.11.110/

You can place `app_offline.htm` file in the application folder and when it becomes offline this page will be preseneted to the user (more [here](http://blogs.msdn.com/b/amb/archive/2012/02/03/easiest-way-to-take-your-web-site-offline-iis-6-0-or-iis-7-5-with-net-4-0.aspx)).

### Managing application pools ###

Listening currently running pools (with their PIDs):

    C:\WINDOWS\system32>iisapp
    W3WP.exe PID: 68372   AppPoolId: DefaultAppPool

Recycling a pool:

    C:\WINDOWS\system32>iisapp /p 109048 /r
    Connecting to server ...Done.
    Application pool 'Default .Net4' recycled successfully.

### Querying websites ###

Listening configured websites:

    iisweb /query | findstr test

    > iisweb /query
    Connecting to server ...Done.
    Site Name (Metabase Path)                     Status  IP              Port  Host
    ==============================================================================
    Default Web Site (W3SVC/1)                    STARTED ALL             80    N/A
    Developers Community (W3SVC/100122359)        STARTED ALL             80    test.pl

### Managing virtual directories ###

List virtual directories defined for a site:

    C:\>iisvdir /query "test"
    Connecting to server ...Done.
    Alias                              Physical Root
    ==============================================================================
    /pictures                          \\test\test1
    /writeenableddir                   \\test\test2
    riteenableddir

### Configure ASP.NET website by modifying the import file ###

Export configuration to a xml file. Then replace all website ids that exist in the file:

    PS temp> New-WebSiteFromConfigurationFile -ComputerName test-server -ConfigFile C:\temp\test.xml -NewWebsiteId 446926682 -ServerBinding "172.20.0.2:80:" -ApplicationName "test.pl" -ErrorAction Stop -AppPoolId test-pool

### ASP.NET routing in IIS6 ###

based on <http://blog.codeville.net/2008/07/04/options-for-deploying-aspnet-mvc-to-iis-6/>
