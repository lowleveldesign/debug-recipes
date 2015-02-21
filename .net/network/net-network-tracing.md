
Network tracing in .NET
=======================

All classes from `System.Net`, if configured properly, may provide a lot of interesting logs through the default System.Diagnostics mechanisms.

## Available sources ##

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

## Example configuration ##

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

If you are using NLog in your application you may redirect the System.Net trace output to the `NLogTraceListener` with the following setting:

```xml
<sharedListeners>
  <add name="nlog" type="LowLevelDesign.NLog.NLogTraceListener, LowLevelDesign.NLog.Ext" />
</sharedListeners>
```

Links
-----

- [To Log or NLog - my post describing the NLog library and its configuration](https://lowleveldesign.wordpress.com/2012/10/28/to-log-or-nlog/)
- [Tracing System.Net to debug HTTP Clients](http://mikehadlow.blogspot.co.uk/2012/07/tracing-systemnet-to-debug-http-clients.html)
- [Network Tracing](http://msdn.microsoft.com/en-us/library/hyb3xww8)

