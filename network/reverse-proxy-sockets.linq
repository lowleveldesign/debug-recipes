<Query Kind="Program">
  <Namespace>System</Namespace>
  <Namespace>System.IO</Namespace>
  <Namespace>System.Linq</Namespace>
  <Namespace>System.Net</Namespace>
  <Namespace>System.Net.Sockets</Namespace>
  <Namespace>System.Threading.Tasks</Namespace>
</Query>

async Task Main()
{
    var listenSocket = new Socket(SocketType.Stream, ProtocolType.Tcp);
    listenSocket.Bind(new IPEndPoint(IPAddress.Loopback, 443));

    var remoteEndpoints = new[] { 
        new IPEndPoint(IPAddress.Parse("127.0.0.1"), 7880),
        new IPEndPoint(IPAddress.Parse("127.0.0.1"), 7881),
    };

    Console.WriteLine("Listening on port 443");

    listenSocket.Listen(120);
    int index = 0;

    while (true) {
        var socket = await listenSocket.AcceptAsync();
        Console.WriteLine($"[{socket.RemoteEndPoint}]: connected");

        // random remote socket
        var remoteSocket = new Socket(SocketType.Stream, ProtocolType.Tcp);
        var remoteEndpoint = remoteEndpoints[index & 0x1];
        index = ~index;
        
        Console.WriteLine($"[{remoteEndpoint}]: forwarding");

        await remoteSocket.ConnectAsync(remoteEndpoint);

        _ = ProcessRequest(socket, remoteSocket);
    }
}

// Define other methods and classes here

private static async Task ProcessRequest(Socket clientSocket, Socket remoteSocket)
{
    var cts = new CancellationTokenSource();
    var tasks = new List<Task>() { 
        FromClientToRemote(clientSocket, remoteSocket, cts.Token), 
        FromRemoteToClient(clientSocket, remoteSocket, cts.Token) 
    };

    tasks.Remove(await Task.WhenAny(tasks));

    Console.WriteLine($"[{clientSocket.RemoteEndPoint}]: disconnected");

    cts.Cancel();

    // there will be cancel exceptions thrown here, but we swallow them
    await Task.WhenAny(tasks);

    clientSocket.Dispose();
    remoteSocket.Dispose();
}

private static async Task FromClientToRemote(Socket client, Socket remote, CancellationToken ct)
{
    var buffer = new byte[1024];
    using (var clientStream = new NetworkStream(client))
    using (var remoteStream = new NetworkStream(remote)) {
        int read;
        while ((read = await clientStream.ReadAsync(buffer, 0, buffer.Length, ct)) != 0) {
            await remoteStream.WriteAsync(buffer, 0, read, ct);
        }
    }
}

private static async Task FromRemoteToClient(Socket client, Socket remote, CancellationToken ct)
{
    var buffer = new byte[1024];

    using (var clientStream = new NetworkStream(client))
    using (var remoteStream = new NetworkStream(remote)) {
        int read;
        while ((read = await remoteStream.ReadAsync(buffer, 0, buffer.Length, ct)) != 0) {
            await clientStream.WriteAsync(buffer, 0, read, ct);
        }
    }
}