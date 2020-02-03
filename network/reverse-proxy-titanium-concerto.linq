<Query Kind="Program">
  <NuGetReference>Concerto</NuGetReference>
  <NuGetReference Prerelease="true">Titanium.Web.Proxy</NuGetReference>
  <Namespace>LowLevelDesign.Concerto</Namespace>
  <Namespace>Org.BouncyCastle.Pkcs</Namespace>
  <Namespace>Org.BouncyCastle.Security</Namespace>
  <Namespace>System.Net</Namespace>
  <Namespace>System.Net.Sockets</Namespace>
  <Namespace>System.Security.Cryptography.X509Certificates</Namespace>
  <Namespace>System.Threading.Tasks</Namespace>
  <Namespace>Titanium.Web.Proxy</Namespace>
  <Namespace>Titanium.Web.Proxy.EventArguments</Namespace>
  <Namespace>Titanium.Web.Proxy.Models</Namespace>
  <Namespace>Titanium.Web.Proxy.Network</Namespace>
</Query>

private ConcertoCertificateCache concertoCerts = new ConcertoCertificateCache();

void Main()
{
    var proxyServer = new ProxyServer();

    proxyServer.CertificateManager.SaveFakeCertificates = true;
    proxyServer.CertificateManager.CertificateStorage = concertoCerts;
    
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

public async Task OnServerCertificateValidation(object sender, CertificateValidationEventArgs ev) {
    // Our destination server has only the host name in the certificate. We might check it
    // or simply accept all.
    ev.IsValid = true;
    await Task.CompletedTask;
}

private int index = 0;

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