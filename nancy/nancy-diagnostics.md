
Diagnosing Nancy
================

Nancy has a decent Diagnostics console which you can access under the `/_Nancy` route. The dashboard is automatically enabled for you, but in order to use it you need to configure a password:

```csharp
public class CustomBootstrapper : DefaultNancyBootstrapper
{
    protected override DiagnosticsConfiguration DiagnosticsConfiguration
    {
        get { return new DiagnosticsConfiguration { Password = @"A2\6mVtH/XRT\p,B"}; }
    }
}
```

The console allows you to examine Nancy settings, configure diagnostics parameters and run some test requests. However, I find the request tracing console not very intuitive so I wrote a simple Powershell module which might help you manage request tracing and parse the collected requests. Three commands are available in the **NancyModule**:

- `Start-NancyRequestTracing -BaseAppUrl ... -Password ...`
- `Stop-NancyRequestTracing -BaseAppUrl ... -Password ...`
- `Read-NancyCollectedRequests -BaseAppUrl ... -Password ... [-ShowLogs] [-SessionId ...]`

Additionally I created a script which wraps all those commands into one wrapper. Example output might look as follows:


