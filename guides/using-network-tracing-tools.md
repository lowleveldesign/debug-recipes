---
layout: page
title: Using network tracing tools
---

WIP

FIXME: it could be better to group those commands by scenarios maybe than by tools

<!-- MarkdownTOC -->

- [Logging application requests in a proxy](#logging-application-requests-in-a-proxy)
- [Troubleshooting network on Windows](#troubleshooting-network-on-windows)
    - [Wireshark \(network tracing and more\)](#wireshark-network-tracing-and-more)
    - [PsPing \(connectivity issues\)](#psping-connectivity-issues)
        - [Measuring latency](#measuring-latency)
        - [Measuring bandwidth](#measuring-bandwidth)
    - [pktmon \(network tracing\)](#pktmon-network-tracing)
    - [netsh/PerfView \(network tracing\)](#netshperfview-network-tracing)
- [Troubleshooting network on Linux](#troubleshooting-network-on-linux)
    - [tcpdump \(network tracing\)](#tcpdump-network-tracing)
    - [nc \(connectivity issues\)](#nc-connectivity-issues)
- [iperf \(connectivity issues\)](#iperf-connectivity-issues)
    - [Measuring bandwidth](#measuring-bandwidth_1)

<!-- /MarkdownTOC -->


## Logging application requests in a proxy

If you are on Windows, use the system settings to change the system proxy. On Linux, set the **HTTP_PROXY** and **HTTPS_PROXY** variables, for example:

```bash
export HTTP_PROXY="http://localhost:8080"
export HTTPS_PROXY="http://localhost:8080"
```

When you make a request in code you should remember to configure its proxy according to the system settings, eg.:

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

Then run [Fiddler](http://www.telerik.com/fiddler) (or [Burp Suite](https://portswigger.net/burp/) or any other proxy) and requests data should be logged in the sessions window. Unfortunately this approach won't work for requests to applications served on the local server. A workaround is to use one of the Fiddler's localhost alternatives in the url: `ipv4.fiddler`, `ipv6.fiddler` or `localhost.fiddler` (more [here](http://docs.telerik.com/fiddler/Configure-Fiddler/Tasks/MonitorLocalTraffic)).

**NOTE for WCF clients**: WCF has its own proxy settings, to use the default proxy add an `useDefaultWebProxy=true` attribute to your binding.

If you want to trace HTTPS traffic you probably also need to **install the Root CA** of your proxy. On Windows, install the certificate to the Third-Party Root Certification Authorities. On Ubuntu Linux, run the following commands:

```bash
sudo mkdir /usr/share/ca-certificates/extra
sudo cp mitmproxy.crt /usr/share/ca-certificates/extra/mitmproxy.crt
sudo dpkg-reconfigure ca-certificates
```

*NOTE for Python*: if there is Python code that you need to trace, use `export REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt` to force Python to validate TLS certs with your system cert store.

## Troubleshooting network on Windows

### Wireshark (network tracing and more)

In my opinion, the best tool to analyze network traffic on Windows is [Wireshark](https://www.wireshark.org/). There are only two problems with it:

- requires a driver - this could be a problem on servers
- does not log the process ID in the trace

We can easily solve the second issue by [combining the Wireshark trace with the Process Monitor logs](https://lowleveldesign.org/2018/05/11/correlate-pids-with-network-packets-in-wireshark/).

### PsPing (connectivity issues)

PsPing (a part of [Sysinternals toolkit](https://technet.microsoft.com/en-us/sysinternals)) has few interesting options when it comes to diagnosing network connectivity issues. The simplest usage is just a replacement for a ping.exe tool (performs ICMP ping):

    > psping www.google.com

By adding a port number at the end of the host we will measure a TCP handshake (or discover a closed port on the remote host):

    > psping www.google.com:80

To test UDP add **-u** option on the command line.

#### Measuring latency

We need to run a PsPing in a server mode on the other side (-f for creating a temporary exception in the Windows Firewall, -s to enable server listening mode):

    > psping -f -s 192.168.1.3:4000

Then we start the client and perform the test:

    > psping -l 16k -n 100 192.168.1.3:4000

#### Measuring bandwidth

We need to run a PsPing in a server mode on the other side (-f for creating a temporary exception in the Windows Firewall, -s to enable server listening mode):

    > psping -f -s 192.168.1.3:4000

Then we start the client and perform the test:

    > psping -b -l 16k -n 100 192.168.1.3:4000

### pktmon (network tracing)

Starting with Window 10 (Server 2019), we have a new tool in our arsenal. Pktmon groups packets per components in the network stack, which is especially helpful in monitoring virtualized applications.

```powershell
# List active components in the network stack
pktmon component list

# Create a filter for TCP traffic for the 172.29.235.111 IP and the 8080 port
pktmon filter add -t tcp -i 172.29.235.111 -p 8080

# Show the configured filters
pktmon filter list

# Start the capturing session (-c) for all the components (--comp)
pktmon start -c --comp all && timeout -1 && pktmon stop

# Start the capture session (-c) for all NICs only (--comp), logging the entire packets (--pkt-size 0), overwriting the older packets when the output file reaches 512MB (-m circular -s 512)
pktmon start -c --comp nics --pkt-size 0 -m circular -s 512 -f c:\network-trace.etl && timeout -1 && pktmon stop
```

We may later convert the etl file to pcapng and open it in, for example, WireShar: `pktmon etl2pcap C:\network-trace.etl --out C:\network-trace.pcap`.

### netsh/PerfView (network tracing)

Starting with Windows 7 (Server 2008) you don't need to install anything (such as WinPcap or Network Monitor) on the server to collect network traces. You can simply use `netsh trace {start|stop}` command which will create an ETW session with the interesting ETW providers enabled. Few diagnostics scenarios are available and you may list them using `netsh trace show scenarios`:

```
PS Temp> netsh trace show scenarios

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

*NOTE: For DHCP traces you may check `netsh dhcpclient trace ...` commands. Also LAN and WLAN modes have some tracing capabilities which you may enable with a command `netsh (w)lan set tracing mode=yes` and stop with a command `netsh (w)lan set tracing mode=no`*

To know exactly which providers are enabled in each scenario use `netsh trace show scenario {scenarioname}`. After choosing the right scenario for your diagnosing case start the trace with a command:

```batchfile
netsh trace start scenario={yourscenario} capture=yes correlation=no report=no tracefile={the-output-etl-file}

Example:
    netsh trace start scenario=internetclient capture=yes correlation=no report=no tracefile=d:\temp\net.etl
```

Old way: `netsh trace start scenario=InternetClient capture=yes && timeout -1 && netsh trace stop`

After some time (or after performing the faulty network operation) stop the trace with a command:

```batchfile
netsh trace stop
```

A new .etl file should be created in the output directory (as well as a .cab file with some interesting system logs). Some ETW providers do not generate information about the processes related to the specific events (for instance WFP provider) - keep this in mind when choosing your own set.

Many interesting capture filters are available, you may use `netsh trace show CaptureFilterHelp` to list them. Most interesting include `CaptureInterface`, `Protocol`, `Ethernet.`, `IPv4.` and `IPv6.` options set, example:

    netsh trace start scenario=InternetClient capture=yes CaptureInterface="Local Area Connection 2" Protocol=TCP Ethernet.Type=IPv4 IPv4.Address=157.59.136.1 maxSize=250 fileMode=circular overwrite=yes traceFile=c:\temp\nettrace.etl

    netsh trace stop

We can then **convert the .etl file to .pcapng** with the [etl2pcapng](https://github.com/microsoft/etl2pcapng) tool, and open them in Wireshark.

**PerfView** also provides a way to collect network trace (under the hood it uses netsh command). There are two options to collect network traces in PerfView: **NetMon** and **Net Capture**.

I recommend checking the NetMon option as it will generate a seperate .etl file containing just the network traces. We may later open this file in [Message Analyzer](https://www.microsoft.com/en-us/download/details.aspx?id=44226) and analyze the collected data.

## Troubleshooting network on Linux

### tcpdump (network tracing)

Most commonly used tool to collect network traces on Linux is **tcpdump**. The BPF language is quite complex and allows various filtering options. A great explanation of its syntax can be found [here](http://www.biot.com/capstats/bpf.html). Below, you may find example session configurations.

View traffic only between two hosts:

```
tcpdump host 192.168.0.1 && host 192.168.0.2
```

View traffic in a particular network:

```
tcpdump net 192.168.0.1/24
```

Dump traffic to a file and rotate it every 1KB:

```
tcpdump -C 1024 -w test.pcap
```

### nc (connectivity issues)

To check if there is anything listening on a TCP port 80 on a remote host, run:

```
nc -vnz 192.168.0.20 80
```

## iperf (connectivity issues)

### Measuring bandwidth

**iperf** tests TCP bandwidth on Linux

We need to start the iperf server (-s) (the -e option is to enable enhanced output and -l sets the TCP read buffer size):

    $ iperf -s -l 128k -p 8080 -e

Then we run the client for 30s (-t) using two parallel threads (-P) and showing interval summaries every 2s (-i):

    $ iperf -c 172.30.102.167 -p 8080 -l 128k -P 2 -i 2 -t 30
