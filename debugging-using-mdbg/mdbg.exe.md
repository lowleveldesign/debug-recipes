
Mdbg.exe
========

Starting the debugger
---------------------

### Spawn a new process ###

### Attach to a process (!attach) ###

    C:>tasklist /FI "imagename eq iisexpress.exe"

    Image Name                     PID Session Name        Session#    Mem Usage
    ========================= ======== ================ =========== ============
    iisexpress.exe                5300 Console                    1     61 504 K

    C:>mdbg !a 5300
    MDbg (Managed debugger) v4.0.30319.1 (RTMRel.030319-0100) started.
    Copyright (C) Microsoft Corporation. All rights reserved.

    For information about commands type "help";
    to exit program type "quit".

    a 5300
    [p#:0, t#:8] mdbg>

Controling the debugging process
--------------------------------

### Breakpoints ###

    Syntax: b[reak] [ClassName.Method | FileName:LineNo] | [module!ClassName.Method+IlOffset]

Examples:

    [p#:0, t#:5] mdbg> b LowLevelDesign.Samples.MySqlWebEventProvider.CreateCommandText
    Breakpoint #1 bound (LowLevelDesign.Samples.MySqlWebEventProvider::CreateCommandText(+0))

To **delete a breakpoint**: `del[ete] [#num]`, eg.

    [p#:0, t#:9] mdbg> b
    Current breakpoints:
    Breakpoint #1 bound (LowLevelDesign.Samples.MySqlWebEventProvider::CreateCommandText(+0))

    [p#:0, t#:9] mdbg> del 1

**Conditional breakpoints** can be created using the `when` statement:

    [p#:0, t#:0] mdbg> b TraceReader.cs:33
    Breakpoint #1 bound (line 33 in TraceReader.cs)

    [p#:0, t#:0] mdbg> when BreakpointHit 1 do "p line"
    [p#:0, t#:0] mdbg> when
    1.      when BreakpointHit (Number=1) do: p line

### Stack trace ###

    Usage: w[here] [-v] [-c depth] [threadID]

    [p#:0, t#:6] mdbg> w -c 4
    Thread [#:6]
    *0. LowLevelDesign.Samples.MySqlWebEventProvider.CreateCommandText (c:\Users\Sebastian\SkyDrive\lab\asp.net-health-monitoring-mysql\multiple_tables\MySqlWebEventProvider\MySqlWebEventProvider.cs:77)
     1. LowLevelDesign.Samples.MySqlWebEventProvider.WriteToMySql (c:\Users\Sebastian\SkyDrive\lab\asp.net-health-monitoring-mysql\multiple_tables\MySqlWebEventProvider\MySqlWebEventProvider.cs:64)
     2. LowLevelDesign.Samples.MySqlWebEventProvider.ProcessEvent (c:\Users\Sebastian\SkyDrive\lab\asp.net-health-monitoring-mysql\multiple_tables\MySqlWebEventProvider\MySqlWebEventProvider.cs:38)
     3. System.Web.Management.WebBaseEvent.RaiseInternal (f:\dd\ndp\fx\src\xsp\System\Web\Management\WebEvents.cs:599)
    displayed only first 4 frames. For more frames use -c switch

### Symbols and sources ###

To **show sources** at the current location use `sh[ow] [lines]`, eg:

    [p#:0, t#:6] mdbg> sh
    74          }
    75
    76          private static String CreateCommandText(WebBaseEvent eventRaised)
    77:*        {
    78              // choose the table to which we will write events
    79              String eventsTable;

The source path can be set using `pa[th] [pathName]`:

    [p#:1, t#:4] mdbg> pa

After the source path is set the debugger somehow is able to resolve source files relevant paths.

### Evaluating expressions ###

To print a variable value use: `print [var] | [-d]`, eg.

    [p#:0, t#:6] mdbg> p -d
    $ex=<N/A>
    $thread=System.Threading.Thread

    [p#:0, t#:6] mdbg> p eventRaised
    eventRaised=System.Web.Management.WebHeartbeatEvent
            s_procStats=System.Web.Management.WebProcessStatistics
            s_processInfo=System.Web.Management.WebProcessInformation
            _eventTimeUtc=System.DateTime
            _code=1005
            _detailCode=0
            _source=<null>
            _message="Application heartbeat."
            _sequenceNumber=71
            _occurrenceNumber=20
            _id=System.Guid
            s_globalSequenceNumber=71
            s_applicationInfo=System.Web.Management.WebApplicationInformation
            s_eventCodeToSystemEventTypeMappings=array [6,12]
            s_eventCodeOccurrence=array [6,12]
            s_customEventCodeOccurrence=System.Collections.Hashtable
            s_lockCustomEventCodeOccurrence=System.Web.Util.ReadWriteSpinLock
            s_systemEventTypeInfos=array [10]



    set variable=value
    newobj typeName [arguments...]
    funceval [-ad Num] functionName [args ... ]

Links
-----

- Getting source code from a source server from Mdbg
  <http://blog.ranamauro.com/2010/02/getting-source-code-from-source-server.html>

Syntax
------


    Usage: mdbg [program [ arguments... ] ]
           mdbg !command1 [!command2 !command3 ... ]

      When program name is entered on the command line, the debugger
      automatically starts debugging such program.

      Arguments starting with ! are interpreted as debugger commands.

    Examples:
      mdbg myProgram.exe

      mdbg !run myProgram.exe !step !go !kill !quit

Commands:

    mdbg> help
    Following commands are available:
    ?             Prints this help screen.
    ap[rocess]    Switches to another debugged process or prints available ones
    a[ttach]      Attaches to a process or prints available processes
    block[ingObjects]
                  Displays any monitor locks blocking threads
    b[reak]       Sets or displays breakpoints
    ca[tch]       Set or display what events will be stopped on
    cl[earException]

    conf[ig]      Sets or Displays debugger configurable options
    del[ete]      Deletes a breakpoint
    de[tach]      Detaches from debugged process
    d[own]        Moves the active stack frame down
    echo          Echoes a message to the console
    enableNotif[ication]
                  Enables or disables custom notifications for a given type
    ex[it]        Quits the program
    fo[reach]     Executes other command on all threads
    f[unceval]    Evaluates a given function outside normal program flow
    g[o]          Continues program execution
    h[elp]        Prints this help screen.
    ig[nore]      Set or display what events will be ignored
    int[ercept]   Intercepts the current exception at the given frame on the stack
    k[ill]        Kills the active process
    l[ist]        Displays loaded modules appdomains or assemblies
    lo[ad]        Loads an extension from some assembly
    log           Set or display what events will be logged
    mo[de]        Set/Query different debugger options
    mon[itorInfo] Displays object monitor lock information
    newo[bj]      Creates new object of type typeName
    n[ext]        Step Over
    opendump      Opens the specified dump file for debugging.
    o[ut]         Steps Out of function
    pa[th]        Sets or displays current source path
    p[rint]       prints local or debug variables
    printe[xception]
                  Prints the last exception on the current thread
    pro[cessenum] Displays active processes
    q[uit]        Quits the program
    re[sume]      Resumes suspended thread
    r[un]         Runs a program under the debugger
    set           Sets a variable to a new value
    setip         Sets an ip into new position in the current function
    sh[ow]        Show sources around the current location
    s[tep]        Step Into
    su[spend]     Prevents thread from running
    sy[mbol]      Sets/Displays path or Reloads/Lists symbols
    t[hread]      Displays active threads or switches to a specified thread
    u[p]          Moves the active stack frame up
    uwgc[handle]  Prints the object tracked by a GC handle
    when          Execute commands based on debugger event
    w[here]       Prints a stack trace
    x             Displays functions in a module

