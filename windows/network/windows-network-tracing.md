
Windows network tracing
=======================

Collect traces
--------------

Starting from Windows 7 (2008 Server) you don't need to install anything (such as WinPcap or Network Monitor) on the server to collect network traces. You can simply use `netsh trace {start|stop}` command which will create an ETW session with the interesting ETW providers enabled. Few diagnostics scenarios are available and you may list them using `netsh trace show scenarios`:

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

After some time (or after performing the faulty network operation) stop the trace with a command:

```batchfile
netsh trace stop
```

A new .etl file should be created in the output directory (as well as a .cab file with some interesting system logs).

Analyze traces
--------------

When we have an .etl file with network trace it's time to analyze it. You can open it in [Message Analyzer](http://blogs.technet.com/b/messageanalyzer/), though Message Analyzer consumes a lot of memory to process the .etl file and it just won't work for bigger trace files. That's why I usually prefer to **convert the .etl file to the .cap format** and perform all analysis in [Wireshark](https://www.wireshark.org/). Message Analyzer comes with a very interesting Powershell module named PEF which is a command line interface for this application. To create the .cap file from the .etl file call:

```powershell
New-PefTraceSession -Path {full-path-to-the-cap-file} -SaveOnStop | Add-PefMessageProvider -Source {full-path-to-the-etl-file} | Start-PefTraceSession
```

I created also a function which you may add to your Powershell profile:

```powershell
function ConvertFrom-EtlToCap([Parameter(Mandatory=$True)][String]$EtlFilePath, [String]$CapFilePath) {
    $EtlFilePath = Resolve-Path $EtlFilePath
    if ([String]::IsNullOrEmpty($CapFilePath)) {
        $CapFilePath = $EtlFilePath.Substring(0, $EtlFilePath.Length - 3) + 'cap'
    }
    New-PefTraceSession -Path $CapFilePath -SaveOnStop | Add-PefMessageProvider -Source $EtlFilePath | Start-PefTraceSession
}
```

Links
-----

- [Event Tracing for Windows and Network Monitor](http://blogs.technet.com/b/netmon/archive/2009/05/13/event-tracing-for-windows-and-network-monitor.aspx)
- [Windows Filtering Platform](http://www.windowsnetworking.com/articles_tutorials/new-netsh-commands-windows-7-server-2008-r2.html)
- [Using HTTP ETW tracing to troubleshoot HTTP issues](http://blogs.msdn.com/b/benjaminperkins/archive/2014/03/10/using-http-etw-tracing-to-troubleshoot-http-issues.aspx)
