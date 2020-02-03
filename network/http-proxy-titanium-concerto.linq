<Query Kind="Program">
  <NuGetReference>Concerto</NuGetReference>
  <NuGetReference>Titanium.Web.Proxy</NuGetReference>
  <Namespace>LowLevelDesign.Concerto</Namespace>
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

private ConcertoCertificateCache concertoCerts = new ConcertoCertificateCache();

void Main()
{
    var proxyServer = new ProxyServer(userTrustRootCertificate: false);

    proxyServer.CertificateManager.SaveFakeCertificates = true;
    proxyServer.CertificateManager.CertificateStorage = concertoCerts;

    proxyServer.OnServerConnectionCreate += OnConnect;
    proxyServer.BeforeRequest += OnBeforeRequest;
    proxyServer.BeforeResponse += OnBeforeResponse;
    proxyServer.AfterResponse += OnAfterResponse;

    var httpProxy = new ExplicitProxyEndPoint(IPAddress.Any, 8080, true);

    proxyServer.AddEndPoint(httpProxy);
    proxyServer.Start();

    foreach (var endPoint in proxyServer.ProxyEndPoints)
        Console.WriteLine("Listening on '{0}' endpoint at Ip {1} and port: {2} ",
            endPoint.GetType().Name, endPoint.IpAddress, endPoint.Port);

    // wait here (You can use something else as a wait function, I am using this as a demo)
    Console.Read();

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
            ev.Ok(File.ReadAllBytes(concertoCerts.RootCertPath), headers, true);
        } else {
            var headers = new Dictionary<string, HttpHeader>() {
                ["Content-Type"] = new HttpHeader("Content-Type", "text/html"),
            };
            ev.Ok("<html><body><h1><a href=\"/cert/pem\">PEM</a></h1></body></html>");
        }
    }
    await Task.CompletedTask;
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

internal sealed class ConcertoCertificateCache : ICertificateCache
{
    private readonly CertificateChainWithPrivateKey rootCert;
    private readonly string rootCertPath;

    public ConcertoCertificateCache()
    {
        rootCertPath = GetCertificatePath("RootCA");
        if (File.Exists(rootCertPath)) {
            rootCert = CertificateFileStore.LoadCertificate(rootCertPath);
        } else {
            rootCert = CertificateCreator.CreateCACertificate(name: "Titanium");
            CertificateFileStore.SaveCertificate(rootCert, rootCertPath);
        }
    }

    public CertificateChainWithPrivateKey RootCert => rootCert;

    public string RootCertPath => rootCertPath;

    public X509Certificate2 LoadCertificate(string subjectName, X509KeyStorageFlags storageFlags)
    {
        Console.WriteLine($"Loading cert for {subjectName}");
        subjectName = subjectName.Replace("$x$", "*");
        var cert = CertificateCreator.CreateCertificate(new[] { subjectName }, rootCert);

        return ConvertConcertoCertToWindows(cert);
    }

    public X509Certificate2 LoadRootCertificate(string pathOrName, string password, X509KeyStorageFlags storageFlags)
    {
        return ConvertConcertoCertToWindows(rootCert);
    }

    private X509Certificate2 ConvertConcertoCertToWindows(CertificateChainWithPrivateKey certificateChain)
    {
        const string password = "password";
        var store = new Pkcs12Store();

        var rootCert = certificateChain.PrimaryCertificate;
        var entry = new X509CertificateEntry(rootCert);
        store.SetCertificateEntry(rootCert.SubjectDN.ToString(), entry);

        var keyEntry = new AsymmetricKeyEntry(certificateChain.PrivateKey);
        store.SetKeyEntry(rootCert.SubjectDN.ToString(), keyEntry, new[] { entry });
        using (var ms = new MemoryStream()) {
            store.Save(ms, password.ToCharArray(), new SecureRandom());

            return new X509Certificate2(ms.ToArray(), password, X509KeyStorageFlags.Exportable);
        }
    }

    private string GetCertificatePath(string subjectName)
    {
        return Path.Combine(Path.GetDirectoryName(Util.CurrentQueryPath), "certs", subjectName + ".pem");
    }

    public void SaveCertificate(string subjectName, X509Certificate2 certificate)
    {
        // we are not implementing it on purpose
    }

    public void SaveRootCertificate(string pathOrName, string password, X509Certificate2 certificate)
    {
        // we are not implementing it on purpose
    }

    public void Clear()
    {
        // we are not implementing it on purpose
    }
}