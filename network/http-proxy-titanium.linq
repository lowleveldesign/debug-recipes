<Query Kind="Program">
  <NuGetReference>Titanium.Web.Proxy</NuGetReference>
  <Namespace>Org.BouncyCastle.OpenSsl</Namespace>
  <Namespace>Org.BouncyCastle.Pkcs</Namespace>
  <Namespace>Org.BouncyCastle.Security</Namespace>
  <Namespace>System.Net</Namespace>
  <Namespace>System.Net.Sockets</Namespace>
  <Namespace>System.Security.Cryptography.X509Certificates</Namespace>
  <Namespace>System.Threading.Tasks</Namespace>
  <Namespace>Titanium.Web.Proxy</Namespace>
  <Namespace>Titanium.Web.Proxy.EventArguments</Namespace>
  <Namespace>Titanium.Web.Proxy.Http</Namespace>
  <Namespace>Titanium.Web.Proxy.Models</Namespace>
  <Namespace>Titanium.Web.Proxy.Network</Namespace>
</Query>

ProxyServer proxyServer;

void Main()
{
    proxyServer = new ProxyServer(userTrustRootCertificate: false);

    proxyServer.OnServerConnectionCreate += OnConnect;
    proxyServer.BeforeRequest += OnBeforeRequest;
    proxyServer.BeforeResponse += OnBeforeResponse;
    proxyServer.AfterResponse += OnAfterResponse;

    var httpProxy = new ExplicitProxyEndPoint(IPAddress.Any, 8080, decryptSsl: true);

    proxyServer.AddEndPoint(httpProxy);
    proxyServer.Start();

    foreach (var endPoint in proxyServer.ProxyEndPoints)
        Console.WriteLine("Listening on '{0}' endpoint at Ip {1} and port: {2} ",
            endPoint.GetType().Name, endPoint.IpAddress, endPoint.Port);

    string command;
    while ((command = Console.ReadLine()) != "quit") {
        if (command == "clear") {
            Util.ClearResults();
        }
    }

    // Unsubscribe & Quit
    proxyServer.OnServerConnectionCreate -= OnConnect;
    proxyServer.BeforeRequest -= OnBeforeRequest;
    proxyServer.BeforeResponse -= OnBeforeResponse;
    proxyServer.AfterResponse -= OnAfterResponse;

    proxyServer.Stop();
}

// Define other methods and classes here

public async Task OnConnect(object sender, Socket e)
{
    Console.WriteLine($"Connect: {e.LocalEndPoint} -> {e.RemoteEndPoint}");

    await Task.CompletedTask;
}

public async Task OnBeforeRequest(object sender, SessionEventArgs ev)
{
    // Before the request to the remote server
    var request = ev.HttpClient.Request;
    if (!ev.IsHttps && request.Host == "titanium") {
        if (request.RequestUri.AbsolutePath.Equals("/cert/pem", StringComparison.OrdinalIgnoreCase)) {
            // send the certificate
            var headers = new Dictionary<string, HttpHeader>() {
                ["Content-Type"] = new HttpHeader("Content-Type", "application/x-x509-ca-cert"),
                ["Content-Disposition"] = new HttpHeader("Content-Disposition", "inline; filename=titanium-ca-cert.pem")
            };
            ev.Ok(GetRootCertBytes(), headers, true);
        } else {
            var headers = new Dictionary<string, HttpHeader>() {
                ["Content-Type"] = new HttpHeader("Content-Type", "text/html"),
            };
            ev.Ok("<html><body><h1><a href=\"/cert/pem\">PEM</a></h1></body></html>");
        }
    }
    await Task.CompletedTask;
}

private byte[] GetRootCertBytes()
{
    return proxyServer.CertificateManager.RootCertificate.Export(X509ContentType.Cert);
}

public async Task OnBeforeResponse(object sender, SessionEventArgs ev)
{
    // Before the response from the remote server is sent to the 
    // local client. You may read body here: ev.GetRequestBody()

    var request = ev.HttpClient.Request;
    var response = ev.HttpClient.Response;

    Util.Highlight(request.Url).Dump();
    Util.RawHtml("<pre style=\"font-family: Consolas\">" + request.HeaderText + "</pre>").Dump();
//    if (request.HasBody) {
//        (await ev.GetRequestBodyAsString()).Dump();
//    }
    Util.RawHtml("<pre style=\"font-family: Consolas\">" + response.HeaderText + "</pre>").Dump();
//    try {
//        if (response.HasBody) {
//            var resp = (await ev.GetResponseBodyAsString());
//            $"Response to request: {request.RequestUri}".Dump();
//            resp.Dump();
//        }
//    } catch (Exception ex) {
//        ex.ToString().Dump();
//    }
    await Task.CompletedTask;
}

public async Task OnAfterResponse(object sender, SessionEventArgs ev)
{
    // After the response from the remote server was sent to the 
    // local client
    await Task.CompletedTask;
}