<Query Kind="Program">
  <NuGetReference>Titanium.Web.Proxy</NuGetReference>
  <Namespace>System.Net</Namespace>
  <Namespace>System.Net.Sockets</Namespace>
  <Namespace>System.Threading.Tasks</Namespace>
  <Namespace>Titanium.Web.Proxy</Namespace>
  <Namespace>Titanium.Web.Proxy.EventArguments</Namespace>
  <Namespace>Titanium.Web.Proxy.Http</Namespace>
  <Namespace>Titanium.Web.Proxy.Models</Namespace>
</Query>

void Main()
{
    var proxyServer = new ProxyServer();
    
    proxyServer.OnClientConnectionCreate += OnConnect;
    
    var socksProxy = new SocksProxyEndPoint(IPAddress.Loopback, 1080, false);
    
    proxyServer.AddEndPoint(socksProxy);
    proxyServer.Start();
    
    foreach (var endPoint in proxyServer.ProxyEndPoints)
        Console.WriteLine("Listening on '{0}' endpoint at Ip {1} and port: {2} ",
            endPoint.GetType().Name, endPoint.IpAddress, endPoint.Port);
    
    // wait here (You can use something else as a wait function, I am using this as a demo)
    Console.Read();
    
    // Unsubscribe & Quit
    proxyServer.OnClientConnectionCreate -= OnConnect;
    
    proxyServer.Stop();
    
}

// Define other methods and classes here

public Task OnConnect(object sender, Socket e)
{
    Console.WriteLine($"Connect: {e.LocalEndPoint} -> {e.RemoteEndPoint}");
    return Task.CompletedTask;
}