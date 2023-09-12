
# ETW (system and WPT tools)

<!-- MarkdownTOC -->

- [XPerf](#xperf)
    - [Tracing with xperf](#tracing-with-xperf)
    - [Collecting stack walk events](#collecting-stack-walk-events)
    - [Query provider information](#query-provider-information)
    - [Query active sessions](#query-active-sessions)
    - [Trace file postprocessing with xperf](#trace-file-postprocessing-with-xperf)
    - [Boot tracing](#boot-tracing)
    - [Example usages](#example-usages)
- [WPA and WPR](#wpa-and-wpr)
    - [Problems with symbols loading](#problems-with-symbols-loading)
    - [Get information on running profiles](#get-information-on-running-profiles)
    - [Profiling using predefined profiles](#profiling-using-predefined-profiles)
    - [Profiling using custom profiles](#profiling-using-custom-profiles)
    - [Profiling a system boot](#profiling-a-system-boot)
    - [WPR schema analysis](#wpr-schema-analysis)
    - [Reading stack](#reading-stack)
- [System tools](#system-tools)
    - [Event Keywords and Levels](#event-keywords-and-levels)
    - [Enum providers](#enum-providers)
    - [Extract details about a given provider](#extract-details-about-a-given-provider)
    - [Recording trace in logman](#recording-trace-in-logman)
    - [Convert .etl file](#convert-etl-file)
    - [Collect Windows network traces](#collect-windows-network-traces)

<!-- /MarkdownTOC -->

XPerf
-----

### Tracing with xperf

For kernel tracing you just need to specify kernel flags or a kernel group: `xperf -on DiagEasy`

In user-mode tracing you may still use kernel flags and groups, but for each user-trace provider you need to add some additional parameters: `-on (GUID|KnownProviderName)[:Flags[:Level[:0xnnnnnnnn|'stack|[,]sid|[,]tsid']]]`

To stop run: `xperf -stop [session-name] -d c:\temp\trace.etl`

The best option is to combine all the commands together, eg.:

`xperf -on latency -stackwalk profile -buffersize 2048 -MaxFile 1024 -FileMode Circular && timeout -1 && xperf stop -d C:\highCPUUsage.etl`


### Collecting stack walk events

To be able to view stack traces of the ETW events we need to enable special stack walk events collections. For kernel events there is a special **-stackwalk** switch. For user providers it's more complicated and requires a special **:::'stack'** string to be appended to the provider's name (or GUID).

To get more info on kernel stack walk settings execute `xperf -help stackwalk` command.

To be able to see stack traces remember to enable PROC\_THREAD and LOADER kernel flags as they are required to correctly decode the modules in the trace file. Otherwise you will see ?!? symbols instead of valid strings. The next thing to check is that you merged the events from your trace session with the kernel rundown information on the machine where the ETW trace capture was performed (by using the –d command-line option of Xperf).

### Query provider information

Using the -providers switch in xperf you can get a list of installed/known and registered providers, as well as all known kernel flags and groups: `xperf -providers [Installed|I] [Registered|R] [PerfTrack|PT] [KernelFlags|KF] [KernelGroups|KG] [Kernel|K]`

xperf also lists kernel flags that may be used in collection of the kernel events:

### Query active sessions

You can use `xperf -loggers`

### Trace file postprocessing with xperf

Based on http://randomascii.wordpress.com/2014/02/04/process-tree-from-an-xperf-trace/

You may generate a process tree from xperf using `xperf -i foo.etl -a process -tree` command. Other analysis command allow you to extract thread stacks, modules etc.

### Boot tracing

from http://www.fixitpc.pl/topic/11092-analiza-dlugiego-startu-systemu/

1. Make sure stackwalking is disabled: `REG ADD "HKLM\System\CurrentControlSet\Control\Session Manager\Memory Management" -v DisablePagingExecutive -d 0x1 -t REG\_DWORD -f`
2. Start tracing (best for traces use another drive then the one being analysed): `xbootmgr -trace boot -traceflags latency+dispatcher -stackwalk profile+cswitch+readythread -notraceflagsinfilename -postbootdelay 180 -resultpath d:\temp`
3. After booting your file should be created.

### Example usages

Tracing memory allocations:

```  
xperf -start -on PROC_THREAD+LOADER+HARD_FAULTS+MEMINFO+MEMINFO_WS+VIRT_ALLOC -stackwalk VirtualAlloc+VirtualFree -BufferSize 256 -MaxFile 900 -FileMode Circular
```

WPA and WPR
-----------

### Problems with symbols loading

Copy dbghelp.dll and symsrv.dll from the Debugging Tools for Windows to the WPA installation folder (remember about the correct bitness).

### Get information on running profiles

To find active WPR recording you can run: `wpr -status profiles`

### Profiling using predefined profiles

To start profiling with CPU,FileIO and DiskIO profile run: 

`wpr -start CPU -start FileIO -start DiskIO`

To save the results run: 

`wpr -stop C:\temp\result.etl`

To completely turn off wpr logging run: `wpr -cancel`.

### Profiling using custom profiles

Start tracing: 

`wpr.exe -start GeneralProfile -start Audio -start circular-audio-glitches.wprp!MediaProfile -filemode`

Stop tracing and save the results to a file (say, my-wpr-glitches.etl):  

`wpr.exe -stop my-wpr-glitches.etl` 

(Optional) if you want to cancel tracing: `wpr.exe -cancel`

(Optional) if you want to see whether tracing is currently active:  `wpr.exe -status`

### Profiling a system boot

To collect general profile traces use: 

`wpr -start generalprofile -onoffscenario boot -numiterations 1`

All options are displayed after executing: `wpr -help start`.

### WPR schema analysis

I guess that the name in the Profile tag is used to group the profiles for the UI. Those names are displayed when we call wpr -profiles. Interestingly WPR finds the most thorough profile from the available profiles in a given wprp file.

### Reading stack

When analyzing traces we have the usual stack available, but you may often see an option to display stack tags. Those are special values which replace the well-known stack frames with tags. This way we can group the events by a stack tag and have a better understand which types of operation built a given request.

System tools
------------

### Event Keywords and Levels

For **manifest-based** providers set MatchAnyKeywords to 0x00 to receive all events. Otherwise you need to create a bitmask which will be or-ed with event keywords. Additionally when MatchAllKeywords is set, its value is used for events that passed the MatchAnyKeywords test and providers additional and filtering.

For **classic providers** set MatchAnyKeywords to 0xFFFFFFFF to receive all events.

Up to 8 sessions may collect manifest-based provider events, but only 1 session may be created for a classic provider (when a new session is created the provider switches to the session).

When creating a session we may also specify the event's level:

- `TRACE_LEVEL_CRITICAL 0x1`
- `TRACE_LEVEL_ERROR 0x2`
- `TRACE_LEVEL_WARNING 0x3`
- `TRACE_LEVEL_INFORMATION 0x4`
- `TRACE_LEVEL_VERBOSE 0x5`

### Enum providers

List all providers: **logman query providers**

List provider details: `logman query providers ".NET Common Language Runtime"`

With logman you can also query providers in a given process: 

```
logman query providers -pid 808
```

You use logman or wevtutil: `wevtutil ep`

Find MSMQ publishers: `wevtutil ep | findstr /i msmq`

using Powershell: `Get-WinEvent -ListProvider`

### Extract details about a given provider

`wevtutil gp Microsoft-Windows-MSMQ /ge /gm /f:xml`

### Recording trace in logman

The following commands start and stop a tracing session that is using one provider:

`logman start mysession -p {9744AD71-6D44-4462-8694-46BD49FC7C0C} -o c:\temp\test.etl -ets & timeout -1 & logman stop mysession -ets`

For the provider options you may additionally specify the keywords (flags) and levels that will be logged:  -p provider [flags [level]]

You may also use a file with a list of providers:

`logman start mysession -pf providers.guids -o c:\temp\test.etl -ets & timeout -1 & logman stop mysession -ets`

And the providers.guids file content is: {guid} {flags} {level} [provider name]

Example for ASP.NET:

<code>{AFF081FE-0247-4275-9C4E-021F3DC1DA35} 0xf    5  ASP.NET Events
{3A2A4E84-4C21-4981-AE10-3FDA0D9B0F83} 0x1ffe 5  IIS: WWW Server</code>

If you want to record events from the kernel provider you need to name the session: "NT Kernel Logger", eg.:

`logman start "NT Kernel Logger" -p "Windows Kernel Trace" "(process,thread,file,fileio,net)" -o c:\kernel.etl -ets & timeout -1 & logman stop "NT Kernel Logger" -ets`

To see the available Kernel provider options, you may run:

```
> logman query providers "Windows Kernel Trace"

Provider                                 GUID
-------------------------------------------------------------------------------
Windows Kernel Trace                     {9E814AAD-3204-11D2-9A82-006008A86939}

Value               Keyword              Description
-------------------------------------------------------------------------------
0x0000000000000001  process              Process creations/deletions
0x0000000000000002  thread               Thread creations/deletions
0x0000000000000004  img                  Image load
0x0000000000000008  proccntr             Process counters
0x0000000000000010  cswitch              Context switches
0x0000000000000020  dpc                  Deferred procedure calls
0x0000000000000040  isr                  Interrupts
0x0000000000000080  syscall              System calls
0x0000000000000100  disk                 Disk IO
0x0000000000000200  file                 File details
0x0000000000000400  diskinit             Disk IO entry
0x0000000000000800  dispatcher           Dispatcher operations
0x0000000000001000  pf                   Page faults
0x0000000000002000  hf                   Hard page faults
0x0000000000004000  virtalloc            Virtual memory allocations
0x0000000000010000  net                  Network TCP/IP
0x0000000000020000  registry             Registry details
0x0000000000100000  alpc                 ALPC
0x0000000000200000  splitio              Split IO
0x0000000000800000  driver               Driver delays
0x0000000001000000  profile              Sample based profiling
0x0000000002000000  fileiocompletion     File IO completion
0x0000000004000000  fileio               File IO
```

### Convert .etl file

Convert etl file to evtx: `tracerpt -of EVTX test.etl -o test.evtx -summary test-summary.xml`

Dump events to an XML file:  `tracerpt test.etl -o test.xml -summary test-summary.xml`

Dump events to a text file: `xperf -i test.etl -o test.csv`

Dump events to a HTML file: `tracerpt.exe '.\NT Kernel Logger.etl' -o -report -f html`

The default stacktag file is here: `c:\Program Files (x86)\Windows Kits\10\Windows Performance Toolkit\Catalog\default.stacktags`

### Collect Windows network traces

Old way: `netsh trace start scenario=InternetClient capture=yes && timeout -1 && netsh trace stop`

New way: `pktmon start -c --comp nics --pkt-size 0 -m circular -s 512 -f c:\network-trace.etl && timeout && pktmon stop`. We may later convert the etl file to pcapng and open it in, for example, WireShar: `pktmon etl2pcap C:\network-trace.etl --out C:\network-trace.pcap`.
