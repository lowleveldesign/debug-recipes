
Network tracing in .NET
=======================

System.Net traces
-----------------

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

Then run [Fiddler](http://www.telerik.com/fiddler) (or any other proxy) and requests data should be logged in the sessions window. Unfortunately this approach won't work for requests to applications served on the local server. A workaround is to use one of the Fiddler's localhost alternatives in the url: `ipv4.fiddler`, `ipv6.fiddler` or `localhost.fiddler` (more [here](http://docs.telerik.com/fiddler/Configure-Fiddler/Tasks/MonitorLocalTraffic)).

Links
-----

- [To Log or NLog - my post describing the NLog library and its configuration](https://lowleveldesign.wordpress.com/2012/10/28/to-log-or-nlog/)
- [Tracing System.Net to debug HTTP Clients](http://mikehadlow.blogspot.co.uk/2012/07/tracing-systemnet-to-debug-http-clients.html)
- [Network Tracing](http://msdn.microsoft.com/en-us/library/hyb3xww8)

