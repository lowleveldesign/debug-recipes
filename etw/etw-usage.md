
Event Tracing for Windows - usage samples
=========================================

Setup for diagnostics
---------------------

### Configure symbols loading ###

Based on <http://randomascii.wordpress.com/2012/10/04/xperf-symbol-loading-pitfalls/>

Windows Performance Toolkit does not ship any longer with symsrv.dll and dbghelp.dll which are required to correctly load symbols. It's best to copy manually those dlls into Toolkit folder. The problem might be diagnosed from the Diagnostics Console.

Query event tracing information
-------------------------------

### Query providers information ###

#### Using xperf / wpr ####

Seperate documents

#### Using logman ####

List all providers:

    logman query providers

List provider details:

    d:>logman query providers ".NET Common Language Runtime"

    Provider                                 GUID
    -------------------------------------------------------------------------------
    .NET Common Language Runtime             {E13C0D23-CCBC-4E12-931B-D9CC2EEE27E4}

    PID                 Image
    -------------------------------------------------------------------------------
    0x00001ac0          C:\Program Files (x86)\Microsoft Visual Studio 10.0\Common7\IDE\Remote Debugger\x64\msvsmon.exe
    0x000017b8          C:\Program Files (x86)\Microsoft Visual Studio 10.0\Team Tools\TraceDebugger Tools\IntelliTrace.EXE
    ...
    0x000018fc          C:\Program Files (x86)\Microsoft Visual Studio 10.0\Common7\IDE\Remote Debugger\x64\msvsmon.exe
    0x00001a30          C:\Program Files (x86)\Microsoft Visual Studio 10.0\Common7\IDE\devenv.exe
    0x00000548          C:\Program Files (x86)\Windows Live\Mesh\MOE.exe


    The command completed successfully.

With logman you can also query providers in a given process:

    c:>logman query providers -pid 808

    Provider                                 GUID
    -------------------------------------------------------------------------------
    .NET Common Language Runtime             {E13C0D23-CCBC-4E12-931B-D9CC2EEE27E4}
    FWPUCLNT Trace Provider                  {5A1600D2-68E5-4DE7-BCF4-1C2D215FE0FE}
    Microsoft-Windows-Diagnosis-PCW          {AABF8B86-7936-4FA2-ACB0-63127F879DBF}
    Microsoft-Windows-DNS-Client             {1C95126E-7EEA-49A9-A3FE-A378B03DDB4D}
    Microsoft-Windows-Dwm-Api                {92AE46D7-6D9C-4727-9ED5-E49AF9C24CBF}
    Microsoft-Windows-KnownFolders           {8939299F-2315-4C5C-9B91-ABB86AA0627D}
    Microsoft-Windows-LDAP-Client            {099614A5-5DD7-4788-8BC9-E29F43DB28FC}
    ...

#### Using wevtutil ####

You use logman or wevtutil:

    wevtutil ep

Find MSMQ publishers:

    c:\temp>wevtutil ep | findstr /i msmq
    Microsoft-Windows-MSMQ
    Microsoft-Windows-MSMQTriggers

Find detailed information about a publisher (**{ gp | get-publisher }**) with its events (**/{ge | getevents}:[true|false]**) and messages (**/{gm | getmessage}:[true|false]**):

    c:\temp>wevtutil gp Microsoft-Windows-MSMQ /ge /gm /f:text
    name: Microsoft-Windows-MSMQ
    guid: ce18af71-5efd-4f5a-9bd5-635e34632f69
    helpLink: http://go.microsoft.com/fwlink/events.asp?CoName=Microsoft%20Corporation&ProdName=Microsoft%c2%ae%20Windows%c2%ae%20Operating%20System&ProdVer=6.1.7600.16385&FileName=mqutil.dll&FileVer=6.1.7600.16385
    resourceFileName: C:\Windows\system32\mqutil.dll
    messageFileName: C:\Windows\system32\mqutil.dll
    message: Microsoft-Windows-MSMQ
    channels:
      channel:
        name: Application
        id: 9
        flags: 1
        message: Application
      channel:
        name: Microsoft-Windows-MSMQ/End2End
        id: 16
        flags: 0
        message: Microsoft-Windows-MSMQ/End2End
    levels:
      level:
        name: win:Informational
        value: 4
        message: Information
    opcodes:
      opcode:
        name: win:Info
        value: 0
          task: 0
          opcode: 0
        message: Info
    tasks:
    keywords:
      keyword:
        name: msmqe2emessage
        mask: 1
        message: Tracking MSMQ Messages
      keyword:
        name: win:EventlogClassic
        mask: 80000000000000
        message: Classic
    events:
      event:
        value: 1
        version: 0
        opcode: 0
        channel: 16
        level: 4
        task: 0
        keywords: 0x4000000000000001
        message: Message with ID %1\%2 was put into queue %3
      ...
      event:
        value: 1073743852
        version: 0
        opcode: 0
        channel: 0
        level: 0
        task: 0
        keywords: 0x80000000000000
        message: The Message Queuing service started.

#### Using Powershell ####

    Get-WinEvent -ListProvider *

Example: retrieve events from the event trace (`Microsoft-Windows-DateTimeControlPanel/Operational`) from a remote list of computers (specified in file `c:\fso\cn.txt`) using credentials provided in the `$cred` variable:

    invoke-command -cn (gc c:\fso\cn.txt) -cred $cred {Get-WinEvent -LogName Microsoft-Windows-DateTimeControlPanel/Operational -Force}
            | select pscomputername, timecreated, message | ft pscomputername, timecreated, message -AutoSize -Wrap

### Query sessions information ###

#### Using wpr / xperf ####

Seperate document

#### Using tracelog ####

    C:\temp>tracelog -l -lp

    Logger Name:            EventLog-Microsoft-Windows-EventLog-Analytic
    Logger Id:              0x8
    Logger Thread Id:       0000000000000090
    Guid:                   22ea436f-3bf5-731f-2a5d-0fbf61efccc5
    Session Security:       D:(A;;0x200;;;SY)(A;;0x200;;;BA)(A;;0x200;;;BO)(A;;0x200;;;SU)(A;;0x200;;;WR)(A;;0xffff;;;SY)(A;;0xff7f;;;BA)(A;;0xffff;;;S-1-5-80-880578595-1860270145-482643319-2788375705-1540778122)
    Buffer Size:            4 Kb
    Maximum Buffers:        10
    Minimum Buffers:        4
    Number of Buffers:      4
    Free Buffers:           4
    Buffers Written:        2
    Events Lost:            0
    Log Buffers Lost:       0
    Real Time Buffers Lost: 0
    AgeLimit:               0
    Real Time Consumers:    0
    ClockType:              SystemTime
    Log Mode:               Secure  Sequential
    Maximum File Size:      1 Mb
    Buffer Flush Timer:     5 secs
    Log Filename:           C:\Windows\System32\Winevt\Logs\Microsoft-Windows-EventLog%4Analytic.etl


    C:\temp>tracelog -q iistrace
    Operation Status:       0L      The operation completed successfully.

        Logger Name:            iistrace
        Logger Id:              0x9
        Logger Thread Id:       0000000000000D90
        Guid:                   53c20f8d-0626-42e6-ae8b-cac324d3ed92
        Session Security:       D:(A;;0x800;;;WD)(A;;0x120fff;;;SY)(A;;0x120fff;;;LS)(A;;0x120fff;;;NS)(A;;0x120fff;;;BA)(A;;0xee5;;;LU)(A;;LC;;;MU)
        Buffer Size:            8 Kb
        Maximum Buffers:        26
        Minimum Buffers:        4
        Number of Buffers:      4
        Free Buffers:           4
        Buffers Written:        1
        Events Lost:            0
        Log Buffers Lost:       0
        Real Time Buffers Lost: 0
        AgeLimit:               0
        Real Time Consumers:    0
        ClockType:              PerfCounter
        Log Mode:               Sequential
        Maximum File Size:      not set
        Buffer Flush Timer:     not set
        Log Filename:           C:\temp\out.etl

### Data collectors ###

### ETW Event logs ###

#### Install and uninstall manifest ####

    wevtutil im test.man
    wevtutil um test.man

Consume and control event tracing
---------------------------------
(<http://msdn.microsoft.com/en-us/library/dd392305(v=vs.85).aspx>)

### Event Keywords and Levels ###

For **manifest-based providers** set `MatchAnyKeywords` to `0x00` to receive all events. Otherwise you need to create a bitmask which will be *or-ed* with event keywords. Additionally when `MatchAllKeywords` is set, its value is used for events that passed the `MatchAnyKeywords` test and providers additional *and* filtering.

For **classic providers** set `MatchAnyKeywords` to `0xFFFFFFFF` to receive all events.

Up to 8 sessions may collect manifest-based provider events, but only 1 session may be created for a classic provider (when a new session is created the provider switches to the session).

When creating a session we may also specify **the event's level**:

- `TRACE_LEVEL_CRITICAL 0x1`
- `TRACE_LEVEL_ERROR 0x2`
- `TRACE_LEVEL_WARNING 0x3`
- `TRACE_LEVEL_INFORMATION 0x4`
- `TRACE_LEVEL_VERBOSE 0x5`

### Starting session and enabling a provider ###

#### Tracing with xperf / wpr ####

Seperate document

#### Tracing using logman ####

The following commands start and stop a tracing session that is using one provider:

    logman start mysession -p {9744AD71-6D44-4462-8694-46BD49FC7C0C} -o c:\temp\test.etl -ets
    logman stop mysession -ets

For the provider options you may additionally specify the keywords (flags) and levels that will be logged:

    -p <provider [flags [level]]>

You may also use a file with a list of providers:

    logman start mysession -pf providers.guids -o c:\temp\test.etl -ets
    logman stop mysession -ets

And the `providers.guids` file content is:

    {guid} {flags} {level} [provider name]

Example for ASP.NET:

    {AFF081FE-0247-4275-9C4E-021F3DC1DA35} 0xf    5  ASP.NET Events
    {3A2A4E84-4C21-4981-AE10-3FDA0D9B0F83} 0x1ffe 5  IIS: WWW Server

#### Tracing using netsh ####

netsh allows tracing with a specific provider. The syntax is:

     trace start [[scenario=]<scenario1,scenario2>]
            [[globalKeywords=]keywords] [[globalLevel=]level]
            [[capture=]yes|no] [[capturetype=]physical|vmswitch|both]
            [[report=]yes|no|disabled] [[persistent=]yes|no]
            [[traceFile=]path\filename] [[maxSize=]filemaxsize]
            [[fileMode=]single|circular|append] [[overwrite=]yes|no]
            [[correlation=]yes|no|disabled] [capturefilters]
            [[provider=]providerIdOrName] [[keywords=]keywordMaskOrSet]
            [[level=]level]
            [[[provider=]provider2IdOrName] [[providerFilter=]yes|no]]
            [[keywords=]keyword2MaskOrSet] [[perfMerge=]yes|no]
            [[level=]level2] ...

Example:

    netsh trace start provider=Microsoft-Windows-Winsock-AFD TraceFile=my_winsock_log2.etl
    Trace configuration:
    -------------------------------------------------------------------
    Status: Running
    Trace File: my_winsock_log2
    Append: Off
    Circular: On
    Max Size: 250 MB
    Report: Off
    ]] netsh trace stop
    Correlating traces ... done
    Generating data collection ... done
    ...

To stop tracing use `netsh trace stop` - a new .etl file will be created. Additionally netsh has many interesting tracing scenarios. You may list them using `netsh trace show scenarios`:

    Available scenarios (17):
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
    WCN                      : Troubleshoot Windows Connect Now related issues
    WFP-IPsec                : Troubleshoot Windows Filtering Platform and IPsec related issues
    WLAN                     : Troubleshoot wireless LAN related issues

### Convert .etl file to .evtx ###

    tracerpt -f XML -of EVTX test.etl

Dump etl file to xml:

    tracerpt test.etl

Run ETW sessions remotely
-------------------------

Using ETWController (<https://etwcontroler.codeplex.com/>) you may collect ETW traces on a remote machine. It has documentation tab that presents some usage samples.

Post-mortem ETW reading
---------------------

You can extract information from ETW buffers after a system failure. Load a kernel memory dump into windbg and use `!wmitrace` extension commands:

    0:027> !wmitrace.help

    ETW Tracing Kernel Debugger Extensions

        strdump                                - List running loggers
        logger <LoggerId>                      - Dump the logger information
        logdump <LoggerId> [-t n] [-tmf GUIDFile] [-man Man1 Man2 ... ManN] [-xml] [-of file]
                                               - Dump the in-memory portion of a log file.
                                                 [-t n]: Dump the last n events, sorted by timestamp.
                                                 [-tmf GUIDFile]: Specify the tmf file for WPP events.
                                                 [-man Man1 Man2 ... ManN]: Specify a list of manifest files for ETW events.
                                                 [-xml]: Dump the events in xml format.
                                                 [-of file]: Dump the events in file, instead of the debugger console.
        logsave  <LoggerId>  <Save file name>  - Save the in-memory portion of a log to an .etl file
        searchpath  [+]  <Path>                - Set the trace format search path
        manpath <Path>                         - Set the manifest search path
        tmffile <filename>                     - Set the TMF file name (default is 'default.tmf')
        setprefix [+] <TraceFormatPrefix>      - Set the prefix format.
                                                 (default for WPP events: [%9!d!]%8!04X!.%3!04X!::%4!s! [%1!s!])
                                                 (default for ETW events: [%9!d!]%8!04X!.%3!04X!::%4!s! [EventId=%2!s!])
        start LoggerName [-cir n] [-seq n] [-f file] [-b n] [-max n] [-min n] [-kd] [-ft n] [-singlestream [0|1]]
                                               - Start the logger. For circular and sequential file maximum file size
                                                 can be provided. Default is buffered mode. Other arguments: filename,
                                                 buffer size, max and min buffers, flush timer, KdFilter.
        enable LoggerId GUID [-level n] [-matchallkw n] [-matchanykw n] [-enableproperty n] [-flag n]
                                               - Enable provider. Level, keywords, flags and enableproperty can be provided
        stop <LoggerId>                        - Stop the logger.
        disable LoggerId GUID                  - Disable provider.
        kdtracing <LoggerId> <0|1>             - Turn live tracing messages on (1) or off (0) for a particular logger.
        dynamicprint <0|1>                     - Turn live tracing messages on (1) or off (0).  Default is on.
        traceoperation <0|1|2>                 - Verbose output. Default is OFF (debugging feature).
        dumpmini                               - Dump the system trace fragment stored in a minidump (Vista and later).
        dumpminievent                          - Dump the system event log trace fragment from a minidump (Vista SP1 and later).
        eventlogdump <LoggerId>                - Dump a logger using eventlog formatting.
        bufdump [<LoggerId>]                   - Dump the Wmi Trace Loggers Buffers

You can start with `!wmitrace.strdump` which will dump all loggers registered in the kernel. Then you can save the interesting log into an .etl file using `!wmitrace.logsave 0x2 c:\perf\test.etl`.
