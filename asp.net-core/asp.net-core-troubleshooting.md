
# ASP.NET Core troubleshooting

In this recipe:

- [Collecting ASP.NET Core logs](#collecting-aspnet-core-logs)
  - [`ILogger` logs](#ilogger-logs)
  - [`DiagnosticSource` logs](#diagnosticsource-logs)
- [Collecting ASP.NET Core performance counters](#collecting-aspnet-core-performance-counters)

## Collecting ASP.NET Core logs

For low-level network traces, you may enable [.NET network providers](../network/network-tracing.md). ASP.NET Core framework logs events either through `DiagnosticSource` using `Microsoft.AspNetCore` as the source name or through the `ILogger` interface.

### `ILogger` logs

The `CreateDefaultBuilder` method adds `LoggingEventSource` (named `Microsoft-Extensions-Logging`) as one of the log outputs. The `FilterSpecs` argument makes it possible to filter the events by logger name and level, for example:

```
Microsoft-Extensions-Logging:5:5:FilterSpecs=webapp.Pages.IndexModel:0
```

We may define the log message format with keywords (pick one):

- `0x1` - enable meta events
- `0x2` - enable events with raw arguments
- `0x4` - enable events with formatted message (the most readable)
- `0x8` - enable events with data seriazlied to JSON

For example, to collect `ILogger` info messages: `dotnet-trace collect -p PID --providers "Microsoft-Extensions-Logging:0x4:0x4"`

### `DiagnosticSource` logs 

To listen to `DiagnosticSource` events, we should enable the `Microsoft-Diagnostics-DiagnosticSource` event source. `DiagnosticSource` events often contain complex types and we need to use [parser specifications](https://github.com/dotnet/runtime/blob/main/src/libraries/System.Diagnostics.DiagnosticSource/src/System/Diagnostics/DiagnosticSourceEventSource.cs) to extract the interesting properties.

The `Microsoft-Diagnostics-DiagnosticSource` event source some special keywords:

- `0x1` - enable diagnostic messages
- `0x2` - enable regular events
- `0x0800` - disable the shortcuts keywords, listed below
- `0x1000` - enable activity tracking and basic hosting events (ASP.NET Core)
- `0x2000` - enable activity tracking and basic command events (EF Core)

Also, we should enable the minimal logging from the `System.Threading.Tasks.TplEventSource` provider to profit from the [activity tracking](https://docs.microsoft.com/en-us/archive/blogs/vancem/exploring-eventsource-activity-correlation-and-causation-features).

When our application is hosted on the Kestrel server, we may enable the `Microsoft-AspNetCore-Server-Kestrel` provider to get Kestrel events.

An example command that enables all ASP.NET Core event traces and some other useful network event providers. It also adds activity tracking for `HttpClient` requests:

```
> dotnet-trace collect --providers "Private.InternalDiagnostics.System.Net.Security,Private.InternalDiagnostics.System.Net.Sockets,Microsoft-AspNetCore-Server-Kestrel,Microsoft-Diagnostics-DiagnosticSource:0x1003:5:FilterAndPayloadSpecs=\"Microsoft.AspNetCore\nHttpHandlerDiagnosticListener\nHttpHandlerDiagnosticListener/System.Net.Http.Request@Activity2Start:Request.RequestUri\nHttpHandlerDiagnosticListener/System.Net.Http.Response@Activity2Stop:Response.StatusCode\",System.Threading.Tasks.TplEventSource:0x80:4,Microsoft-Extensions-Logging:4:5" -n webapp
```

## Collecting ASP.NET Core performance counters

ASP.NET Core provides some basic performance counters through the `Microsoft.AspNetCore.Hosting` event source. If we are also using Kestrel, we may add some interesting counters by enabling `Microsoft-AspNetCore-Server-Kestrel`:

```
> dotnet-counters monitor "Microsoft.AspNetCore.Hosting" "Microsoft-AspNetCore-Server-Kestrel" -n testapp

Press p to pause, r to resume, q to quit.
    Status: Running

[Microsoft.AspNetCore.Hosting]
    Current Requests                                                0
    Failed Requests                                                 0
    Request Rate (Count / 1 sec)                                    0
    Total Requests                                                  0
[Microsoft-AspNetCore-Server-Kestrel]
    Connection Queue Length                                        0
    Connection Rate (Count / 1 sec)                                0
    Current Connections                                            1
    Current TLS Handshakes                                         0
    Current Upgraded Requests (WebSockets)                         0
    Failed TLS Handshakes                                          2
    Request Queue Length                                           0
    TLS Handshake Rate (Count / 1 sec)                             0
    Total Connections                                              7
    Total TLS Handshakes                                           7
```