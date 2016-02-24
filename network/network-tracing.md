
Network tracing
===============

Traces available in .NET applications
-------------------------------------

All classes from `System.Net`, if configured properly, may provide a lot of interesting logs through the default System.Diagnostics mechanisms.

### Available trace sources ###

The below table is copied from <http://msdn.microsoft.com/en-us/library/ty48b824.aspx>

Name|Output from
----|-----------
`System.Net.Sockets`|Some public methods of the Socket, TcpListener, TcpClient, and Dns classes
`System.Net`|Some public methods of the HttpWebREquest, HttpWebResponse, FtpWebRequest and FtpWebResponse classes, and SSL debug information (invalid certificates, missing issuers list and client certificate errors).
`System.Net.HttpListener`|Some public methods of the HttpListener, HttpListenerRequest and HttpListenerResponse
`System.Net.Cache`|Some private and internal methods in System.Net.Cache
`System.Net.Http`|Some public methods of the HttpClient, DelegatingHandler, HttpClientHandler, HttpMessageHandler, MessageProcessingHandler, and WebRequestHandler classes
`System.Net.WebSockets`|Some public methods of the ClientWebSocket and WebSocket classes

Following attributes might be applied to sources to control their output:

Attribute name|Attribute value
--------------|---------------
`maxdatasize`|number that defines the maximum number of bytes of network data included in each line trace. The default value is 1024
`tracemode`|Set to **includehex** (default) to show protocol traces in hexadecimal and text format. Set to **protocolonly** to show only text.

### Example configuration ###

This is a configuration sample which writes network traces to a file:

```xml
<system.diagnostics>
    <trace autoflush="true" />
    <sharedListeners>
      <add name="file" initializeData="C:\logs\network.log" type="System.Diagnostics.TextWriterTraceListener" />
    </sharedListeners>
    <sources>
      <source name="System.Net.Http" switchValue="Verbose">
        <listeners>
          <add name="file" />
        </listeners>
      </source>
      <source name="System.Net.HttpListener" switchValue="Verbose">
        <listeners>
          <add name="file" />
        </listeners>
      </source>
      <source name="System.Net" switchValue="Verbose">
        <listeners>
          <add name="file" />
        </listeners>
      </source>
      <source name="System.Net.Sockets" switchValue="Verbose">
        <listeners>
          <add name="file" />
        </listeners>
      </source>
    </sources>
</system.diagnostics>
```

If you are using NLog in your application you may redirect the System.Net trace output to the `NLogTraceListener` with the following settings:

```xml
<system.diagnostics>
    <trace autoflush="true" />
    <sharedListeners>
      <add name="nlog" type="NLog.NLogTraceListener, NLog" />
    </sharedListeners>
    <sources>
      <source name="System.Net.Http" switchValue="Verbose">
        <listeners>
          <add name="nlog" />
        </listeners>
      </source>
      <source name="System.Net.HttpListener" switchValue="Verbose">
        <listeners>
          <add name="nlog" />
        </listeners>
      </source>
      <source name="System.Net" switchValue="Verbose">
        <listeners>
          <add name="nlog" />
        </listeners>
      </source>
      <source name="System.Net.Sockets" switchValue="Verbose">
        <listeners>
          <add name="nlog" />
        </listeners>
      </source>
    </sources>
</system.diagnostics>
```

Logging application requests in a proxy
---------------------------------------

When you make a request in code you should remember to configure its proxy according to the system settings, eg.:

```csharp
var request = WebRequest.Create(url);
request.Proxy = WebRequest.GetSystemWebProxy();
request.Method = "POST";
request.ContentType = "application/json; charset=utf-8";
...
```

or in the configuration file:

```xml
  <system.net>
    <defaultProxy>
      <proxy autoDetect="False" proxyaddress="http://127.0.0.1:8888" bypassonlocal="False" usesystemdefault="False" />
    </defaultProxy>
  </system.net>
```

Then run [Fiddler](http://www.telerik.com/fiddler) (or any other proxy) and requests data should be logged in the sessions window. Unfortunately this approach won't work for requests to applications served on the local server. A workaround is to use one of the Fiddler's localhost alternatives in the url: `ipv4.fiddler`, `ipv6.fiddler` or `localhost.fiddler` (more [here](http://docs.telerik.com/fiddler/Configure-Fiddler/Tasks/MonitorLocalTraffic)).

**NOTE for WCF clients**: WCF has its own proxy settings, to use the default proxy add an `useDefaultWebProxy=true` attribute to your binding.

ETW network traces
------------------

### Using perfview ###

FIXME

### Using netsh ###

Starting from Windows 7 (2008 Server) you don't need to install anything (such as WinPcap or Network Monitor) on the server to collect network traces. You can simply use `netsh trace {start|stop}` command which will create an ETW session with the interesting ETW providers enabled. Few diagnostics scenarios are available and you may list them using `netsh trace show scenarios`:

```
PS Temp> netsh trace show scenarios

Available scenarios (18):
-------------------------------------------------------------------
AddressAcquisition       : Troubleshoot address acquisition-related issues
DirectAccess             : Troubleshoot DirectAccess related issues
FileSharing              : Troubleshoot common file and printer sharing problems
InternetClient           : Diagnose web connectivity issues
InternetServer           : Set of HTTP service counters
L2SEC                    : Troubleshoot layer 2 authentication related issues
LAN                      : Troubleshoot wired LAN related issues
Layer2                   : Troubleshoot layer 2 connectivity related issues
MBN                      : Troubleshoot mobile broadband related issues
NDIS                     : Troubleshoot network adapter related issues
NetConnection            : Troubleshoot issues with network connections
P2P-Grouping             : Troubleshoot Peer-to-Peer Grouping related issues
P2P-PNRP                 : Troubleshoot Peer Name Resolution Protocol (PNRP) related issues
RemoteAssistance         : Troubleshoot Windows Remote Assistance related issues
Virtualization           : Troubleshoot network connectivity issues in virtualization environment
WCN                      : Troubleshoot Windows Connect Now related issues
WFP-IPsec                : Troubleshoot Windows Filtering Platform and IPsec related issues
WLAN                     : Troubleshoot wireless LAN related issues
```

*NOTE: For DHCP traces you may check `netsh dhcpclient trace ...` commands. Also LAN and WLAN modes have some tracing capabilities which you may enable with a command `netsh (w)lan set tracing mode=yes` and stop with a command `netsh (w)lan set tracing mode=no`*

To know exactly which providers are enabled in each scenario use `netsh trace show scenario {scenarioname}`. After choosing the right scenario for your diagnosing case start the trace with a command:

```batchfile
netsh trace start scenario={yourscenario} capture=yes correlation=no report=no tracefile={the-output-etl-file}

Example:
    netsh trace start scenario=internetclient capture=yes correlation=no report=no tracefile=d:\temp\net.etl
```

After some time (or after performing the faulty network operation) stop the trace with a command:

```batchfile
netsh trace stop
```

A new .etl file should be created in the output directory (as well as a .cab file with some interesting system logs). Some ETW providers do not generate information about the processes related to the specific events (for instance WFP provider) - keep this in mind when choosing your own set.

Many interesting capture filters are available, you may use `netsh trace show CaptureFilterHelp` to list them. Most interesting include `CaptureInterface`, `Protocol`, `Ethernet.`, `IPv4.` and `IPv6.` options set, example:

    netsh trace start scenario=InternetClient capture=yes CaptureInterface="Local Area Connection 2" Protocol=TCP Ethernet.Type=IPv4 IPv4.Address=157.59.136.1 maxSize=250 fileMode=circular overwrite=yes traceFile=c:\temp\nettrace.etl

    netsh trace stop

### Analyze ###

When we have an .etl file with network trace it's time to analyze it. You can open it in [Message Analyzer](http://blogs.technet.com/b/messageanalyzer/), though Message Analyzer consumes a lot of memory to process the .etl file and it just won't work for bigger trace files. That's why I usually prefer to **convert the .etl file to the .cap format** and perform all analysis in [Wireshark](https://www.wireshark.org/). Message Analyzer comes with a very interesting Powershell module named PEF which is a command line interface for this application. To create the .cap file from the .etl file call:

```powershell
New-PefTraceSession -Path {full-path-to-the-cap-file} -SaveOnStop | Add-PefMessageProvider -Source {full-path-to-the-etl-file} | Start-PefTraceSession
```

I created also a function which you may add to your Powershell profile:

```powershell
function ConvertFrom-EtlToCap([Parameter(Mandatory=$True)][String]$EtlFilePath, [String]$CapFilePath) {
    $EtlFilePath = Resolve-Path $EtlFilePath
    if ([String]::IsNullOrEmpty($CapFilePath)) {
        $CapFilePath = $EtlFilePath.Substring(0, $EtlFilePath.Length - 3) + 'cap'
    }
    New-PefTraceSession -Path $CapFilePath -SaveOnStop | Add-PefMessageProvider -Source $EtlFilePath | Start-PefTraceSession
}
```

Procmon network tracing
-----------------------

Procmon network tracing does not collect data sent or received but it will reveal all the network connections opened by processes in the system.

Links
-----

- [Using .NET HttpClient to capture partial Responses](http://weblog.west-wind.com/posts/2014/Jan/29/Using-NET-HttpClient-to-capture-partial-Responses?utm_source=feedburner&utm_medium=feed&utm_campaign=Feed%3A+RickStrahl+%28Rick+Strahl%27s+WebLog%29)
- [Tracing System.Net to debug HTTP Clients](http://mikehadlow.blogspot.co.uk/2012/07/tracing-systemnet-to-debug-http-clients.html)
- [Network Tracing](http://msdn.microsoft.com/en-us/library/hyb3xww8)
- [Event Tracing for Windows and Network Monitor](http://blogs.technet.com/b/netmon/archive/2009/05/13/event-tracing-for-windows-and-network-monitor.aspx)
- [Windows Filtering Platform](http://www.windowsnetworking.com/articles_tutorials/new-netsh-commands-windows-7-server-2008-r2.html)
- [Using HTTP ETW tracing to troubleshoot HTTP issues](http://blogs.msdn.com/b/benjaminperkins/archive/2014/03/10/using-http-etw-tracing-to-troubleshoot-http-issues.aspx)

