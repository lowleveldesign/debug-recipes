
xperf.exe
=========

A lot of scripts for various collection scenarios can be found under the **scripts** folder. I collected them from various sources (Andrew Richard's one drive, Tarik Soulami's book, Bruce Dawson articles) and hopefully authors won't mind sharing them.

### Collecting stack walk events ###

To be able to view stack traces of the ETW events we need to enable special stack walk events collections. For kernel events there is a special **-stackwalk** switch. For user providers it's more complicated and requires a special **:::'stack'** string to be appended to the provider's name (or GUID).

To get more info on kernel stack walk settings execute `xperf -help stackwalk` command.

To be able to see stack traces remember to enable **PROC\_THREAD** and **LOADER** kernel flags as they are required to correctly decode the modules in the trace file. Otherwise you will see `?!?` symbols instead of valid strings. The next thing to check is that you merged the events from your trace session with the kernel rundown information on the machine where the ETW trace capture was performed (by using the –d command-line option of Xperf).

### Query provider information ###

Using the `-providers` switch in xperf you can get a list of installed/known and registered providers, as well as all known kernel flags and groups:

    xperf -providers [Installed|I] [Registered|R] [PerfTrack|PT] [KernelFlags|KF] [KernelGroups|KG] [Kernel|K]

xperf also lists kernel flags that may be used in collection of the kernel events:

    > xperf -providers KF
       PROC_THREAD    : Process and Thread create/delete
       LOADER         : Kernel and user mode Image Load/Unload events
       PROFILE        : CPU Sample profile
       ...
       FLT_IO_FAILURE : Minifilter callback completion with failure
       HAL_CLOCK      : HAL Clock Configuration events

    > xperf -providers KG
       Base           : PROC_THREAD+LOADER+DISK_IO+HARD_FAULTS+PROFILE+MEMINFO+MEMINFO_WS
       Diag           : PROC_THREAD+LOADER+DISK_IO+HARD_FAULTS+DPC+INTERRUPT+CSWITCH+PERF_COUNTER+COMPACT_CSWITCH
       DiagEasy       : PROC_THREAD+LOADER+DISK_IO+HARD_FAULTS+DPC+INTERRUPT+CSWITCH+PERF_COUNTER
       Latency        : PROC_THREAD+LOADER+DISK_IO+HARD_FAULTS+DPC+INTERRUPT+CSWITCH+PROFILE
       FileIO         : PROC_THREAD+LOADER+DISK_IO+HARD_FAULTS+FILE_IO+FILE_IO_INIT
       IOTrace        : PROC_THREAD+LOADER+DISK_IO+HARD_FAULTS+CSWITCH
       ResumeTrace    : PROC_THREAD+LOADER+DISK_IO+HARD_FAULTS+PROFILE+POWER
       SysProf        : PROC_THREAD+LOADER+PROFILE
       ResidentSet    : PROC_THREAD+LOADER+DISK_IO+HARD_FAULTS+MEMORY+MEMINFO+VAMAP+SESSION+VIRT_ALLOC
       ReferenceSet   : PROC_THREAD+LOADER+HARD_FAULTS+MEMORY+FOOTPRINT+VIRT_ALLOC+MEMINFO+VAMAP+SESSION+REFSET+MEMINFO_WS
       Network        : PROC_THREAD+LOADER+NETWORKTRACE

### Query active sessions ###

You can use `xperf -loggers`

    > xperf -loggers

    Logger Name           : Circular Kernel Context Logger
    Logger Id             : 2
    Logger Thread Id      : 00000000
    Buffer Size           : 4
    Maximum Buffers       : 2
    Minimum Buffers       : 2
    Number of Buffers     : 2
    Free Buffers          : 1
    Buffers Written       : 0
    Events Lost           : 0
    Log Buffers Lost      : 0
    Real Time Buffers Lost: 0
    Flush Timer           : 0
    Age Limit             : 0
    Log File Mode         : Secure Buffered <0x10000000>
    Maximum File Size     : 0
    Log Filename          :
    Trace Flags           : LOADER+HARD_FAULTS
    PoolTagFilter         : *

### Tracing with xperf ###

For **kernel tracing** you just need to specify kernel flags or a kernel group:

    xperf -on DiagEasy

In **user-mode tracing** you may still use kernel flags and groups, but for each user-trace provider you need to add some additional parameters

    -on ProviderName:Keyword:Level:'stack|[,]sid|[,]tsid'

To stop run:

    xperf -stop [session-name] -d c:\temp\merged.etl

### Trace file postprocessing with xperf ###

Based on <http://randomascii.wordpress.com/2014/02/04/process-tree-from-an-xperf-trace/>

You may generate a process tree from xperf using `xperf -i foo.etl -a process -tree` command. Other analysis command allow you to extract thread stacks, modules etc.

