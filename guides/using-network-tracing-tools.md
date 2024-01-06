---
layout: page
title: Using network tracing tools
date: 2024-01-01 08:00:00 +0200
---

<!-- MarkdownTOC -->

- [Testing connectivity](#testing-connectivity)
- [Collecting network traces](#collecting-network-traces)
    - [pktmon \(Windows\)](#pktmon-windows)
    - [netsh \(Windows\)](#netsh-windows)
    - [tcpdump \(Linux\)](#tcpdump-linux)
- [Measuring network latency](#measuring-network-latency)
- [Measuring network bandwidth](#measuring-network-bandwidth)
- [Logging HTTP\(S\) requests in a proxy](#logging-https-requests-in-a-proxy)

<!-- /MarkdownTOC -->

## Testing connectivity

It is a common mistake to rely on ping when testing TCP connections. Ping uses a different protocol (ICMP) and although it is a fine tool to check if there is connectivity between two hosts (assuming ICMP traffic is not blocked), it will not tell us anything about opened TCP ports.

On **Linux**, to check if there is anything listening on a TCP port 80 on a remote host, you may use **netcat**:

```shell
nc -vnz 192.168.0.20 80
```

On **Windows**, PsPing (a part of the [Sysinternals toolkit](https://technet.microsoft.com/en-us/sysinternals)) has few interesting options when it comes to diagnosing network connectivity issues. The simplest usage is just a replacement for a ping.exe tool (performs ICMP ping):

```shell
psping www.google.com
```

By adding a port number at the end of the host we will test a TCP handshake (or discover a closed port on the remote host):

```shell
psping www.google.com:80
```

To test UDP add **-u** option on the command line.

## Collecting network traces

Probably the best tool to analyze network traffic is **[Wireshark](https://www.wireshark.org/)**. Of course, Wireshark may also collect network traffic. However, as it's a GUI application, you may have problems running it on servers. On Windows, Wireshark requires an npcap driver which might also generate problems. Therefore, a better choice might be to use command line tools that I discuss later in this ection.

Another problem in network traces is that they lack the ID of the process owning the network connection. We might get this information with the help of other tracing tools. For example, in [this blog post](https://lowleveldesign.org/2018/05/11/correlate-pids-with-network-packets-in-wireshark/), I present how to use Process Monitor logs for this purpose.

### pktmon (Windows)

Switching to the command line tools, starting with **Window 10 (Server 2019)**, we have a new network tracing tool in our arsenal: **pktmon**. It groups packets per components in the network stack, which is especially helpful when monitoring virtualized applications. Here are some usage examples:

```shell
# List active components in the network stack
pktmon component list

# Create a filter for TCP traffic for the 172.29.235.111 IP and the 8080 port
pktmon filter add -t tcp -i 172.29.235.111 -p 8080

# Show the configured filters
pktmon filter list

# Start the capturing session (-c) for all the components (--comp)
pktmon start -c --comp all && timeout -1 && pktmon stop

# Start the capture session (-c) for all NICs only (--comp), logging the entire 
# packets (--pkt-size 0), overwriting the older packets when the output file 
# reaches 512MB (-m circular -s 512)
pktmon start -c --comp nics --pkt-size 0 -m circular -s 512 -f c:\network-trace.etl && timeout -1 && pktmon stop
```

We may later convert the etl file to open it in Wireshark: 

```shell
pktmon etl2pcap C:\network-trace.etl --out C:\network-trace.pcap`
```

### netsh (Windows)

Netsh is another tool we could use for this purpose on Windows (even on **older Windows versions**). The **netsh trace {start|stop}** command will create an ETW-based network trace, allowing us to choose from a variety of diagnostics scenarios:

```
> netsh trace show scenarios

Available scenarios (18):
-------------------------------------------------------------------
AddressAcquisition       : Troubleshoot address acquisition-related issues
DirectAccess             : Troubleshoot DirectAccess related issues
FileSharing              : Troubleshoot common file and printer sharing problems
InternetClient           : Diagnose web connectivity issues
InternetServer           : Set of HTTP service counters
L2SEC                    : Troubleshoot layer 2 authentication related issues
LAN                      : Troubleshoot wired LAN related issues
Layer2                   : Troubleshoot layer 2 connectivity related issues
MBN                      : Troubleshoot mobile broadband related issues
NDIS                     : Troubleshoot network adapter related issues
NetConnection            : Troubleshoot issues with network connections
P2P-Grouping             : Troubleshoot Peer-to-Peer Grouping related issues
P2P-PNRP                 : Troubleshoot Peer Name Resolution Protocol (PNRP) related issues
RemoteAssistance         : Troubleshoot Windows Remote Assistance related issues
Virtualization           : Troubleshoot network connectivity issues in virtualization environment
WCN                      : Troubleshoot Windows Connect Now related issues
WFP-IPsec                : Troubleshoot Windows Filtering Platform and IPsec related issues
WLAN                     : Troubleshoot wireless LAN related issues
```

*NOTE: For DHCP traces you may check netsh dhcpclient trace ... commands. Also LAN and WLAN modes have some tracing capabilities which you may enable with a command netsh (w)lan set tracing mode=yes and stop with a command netsh (w)lan set tracing mode=no*

To know exactly which providers are enabled in each scenario use **netsh trace show scenario {scenarioname}**. After choosing the right scenario for your diagnosing case start the trace, for example:

```shell
netsh trace start scenario=InternetClient capture=yes && timeout -1 && netsh trace stop
```
 
A new .etl file should be created in the output directory (as well as a .cab file with some interesting system logs). If you only need a trace file, you may add **report=no tracefile=d:\temp\net.etl** paramters. Some ETW providers do not generate information about the processes related to the specific events (for instance WFP provider) - keep this in mind when choosing your own set.

Many interesting capture filters are available, you may use **netsh trace show CaptureFilterHelp** to list them. Most interesting include CaptureInterface, Protocol, Ethernet, IPv4, and IPv6 options set, for example:

```shell
netsh trace start scenario=InternetClient capture=yes CaptureInterface="Local Area Connection 2" Protocol=TCP Ethernet.Type=IPv4 IPv4.Address=157.59.136.1 maxSize=250 fileMode=circular overwrite=yes traceFile=c:\temp\nettrace.etl
```

We can **convert the generated .etl file to .pcapng** with the [etl2pcapng](https://github.com/microsoft/etl2pcapng) tool, and open them in Wireshark.

### tcpdump (Linux)

Most commonly used tool to collect network traces on Linux is **tcpdump**. The BPF language is quite complex and allows various filtering options. A great explanation of its syntax can be found [here](http://www.biot.com/capstats/bpf.html). Below, you may find example session configurations.

```shell
# View traffic only between two hosts:
tcpdump host 192.168.0.1 && host 192.168.0.2

# View traffic in a particular network:
tcpdump net 192.168.0.1/24

# Dump traffic to a file and rotate it every 1KB:
tcpdump -C 1024 -w test.pcap
```

## Measuring network latency

On **Windows**, we may use **psping**. We need to run it in a server mode on the connection target (-f for creating a temporary exception in the Windows Firewall, -s to enable server listening mode):

```shell
psping -f -s 192.168.1.3:4000
```

Then start the client and perform the test:

```shell
psping -l 16k -n 100 192.168.1.3:4000
```

## Measuring network bandwidth

**iperf** is a tool that can measure bandwidth on Windows and Linux. We need to start the iperf server (-s) (the -e option is to enable enhanced output and -l sets the TCP read buffer size):

```shell
iperf -s -l 128k -p 8080 -e
```

Then, for an example test, we may run the client for 30s (-t) using two parallel threads (-P) and showing interval summaries every 2s (-i):

```shell
iperf -c 172.30.102.167 -p 8080 -l 128k -P 2 -i 2 -t 30
```

On **Windows**, we may alternatively use **psping**. Again, we need to run it in a server mode on the connection target (-f for creating a temporary exception in the Windows Firewall, -s to enable server listening mode):

```shell
psping -f -s 192.168.1.3:4000
```

Then start the client and perform the test:

```shell
psping -b -l 16k -n 100 192.168.1.3:4000
```

## Logging HTTP(S) requests in a proxy

If you are on Windows, use the system settings to change the system proxy. On Linux, set the **HTTP_PROXY** and **HTTPS_PROXY** variables, for example:

```bash
export HTTP_PROXY="http://localhost:8080"
export HTTPS_PROXY="http://localhost:8080"
```

When you make a request in code you should remember to configure its proxy according to the system settings, for exampe in C#:

```csharp
var request = WebRequest.Create(url);
request.Proxy = WebRequest.GetSystemWebProxy();
request.Method = "POST";
request.ContentType = "application/json; charset=utf-8";
...
```

or in the configuration file:

```xml
  <system.net>
    <defaultProxy>
      <proxy autoDetect="False" proxyaddress="http://127.0.0.1:8080" bypassonlocal="False" usesystemdefault="False" />
    </defaultProxy>
  </system.net>
```

Then run [Fiddler](http://www.telerik.com/fiddler) (or [Burp Suite](https://portswigger.net/burp/) or any other proxy) and requests data should appear in the sessions window. Unfortunately, this approach won't work for requests to applications served on the local server. A workaround is to use one of the Fiddler's localhost alternatives in the url: `ipv4.fiddler`, `ipv6.fiddler` or `localhost.fiddler` (more [here](http://docs.telerik.com/fiddler/Configure-Fiddler/Tasks/MonitorLocalTraffic)).

**NOTE for WCF clients**: WCF has its own proxy settings, to use the default proxy add an `useDefaultWebProxy=true` attribute to your binding.

If you want to trace HTTPS traffic you probably also need to **install the Root CA** of your proxy. On Windows, install the certificate to the Third-Party Root Certification Authorities. On Ubuntu Linux, run the following commands:

```bash
sudo mkdir /usr/share/ca-certificates/extra
sudo cp mitmproxy.crt /usr/share/ca-certificates/extra/mitmproxy.crt
sudo dpkg-reconfigure ca-certificates
```

*NOTE for Python*: if there is Python code that you need to trace, use `export REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt` to force Python to validate TLS certs with your system cert store.

If you would like to apply custom modifications to the proxied requests, you should consider implementing your own network proxy. I present several C# examples of such proxies in [a blog post](https://lowleveldesign.wordpress.com/2020/02/03/writing-network-proxies-for-development-purposes-in-c/) on my blog.
