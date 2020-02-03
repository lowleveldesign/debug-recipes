<Query Kind="Program">
  <NuGetReference>Titanium.Web.Proxy</NuGetReference>
  <Namespace>Titanium.Web.Proxy.Models</Namespace>
  <Namespace>Titanium.Web.Proxy</Namespace>
  <Namespace>Titanium.Web.Proxy.EventArguments</Namespace>
  <Namespace>System.Threading.Tasks</Namespace>
  <Namespace>System.Net</Namespace>
</Query>


void Main()
{
    var proxyServer = new ProxyServer();

    proxyServer.ServerCertificateValidationCallback += OnServerCertificateValidation;

    proxyServer.BeforeRequest += OnBeforeRequest;

    var tcpProxy = new TransparentProxyEndPoint(IPAddress.Loopback, 443, true);

    proxyServer.AddEndPoint(tcpProxy);
    proxyServer.Start();

    string command;
    while ((command = Console.ReadLine()) != "quit") {
        if (command == "clear") {
            Util.ClearResults();
        }
    }

    // Unsubscribe & Quit
    proxyServer.ServerCertificateValidationCallback -= OnServerCertificateValidation;
    proxyServer.BeforeRequest -= OnBeforeRequest;

    proxyServer.Stop();

}

// Define other methods and classes here

async Task OnServerCertificateValidation(object sender, CertificateValidationEventArgs ev)
{
    // Our destination server has only the host name in the certificate. We might check it
    // or simply accept all.
    ev.IsValid = true;
    await Task.CompletedTask;
}

int index = 0;

async Task OnBeforeRequest(object sender, SessionEventArgs ev)
{
    var request = ev.HttpClient.Request;
    var remotePort = index == 0 ? 7880 : 7881;
    index = ~index;

    // no https
    var destRequestUriString = $"https://127.0.0.1:{remotePort}{request.RequestUri.PathAndQuery}";

    Console.WriteLine($"{request.Method} {request.Url}, redirecting to {destRequestUriString}");
    
    request.RequestUriString = destRequestUriString;
    request.Host = "example.net";
    
    await Task.CompletedTask;
}
