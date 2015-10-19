
Windbg debugging tips
=====================

General usage
-------------

First, some very useful start commands:

**| - pipe** command displays a path to the process image

    0:029> |
    .  0	id: 5ec	examine	name: c:\WINDOWS\system32\inetsrv\w3wp.exe

You can also use **vercommand** to show how the debugger was called:

    0:000> vercommand
    command-line: '"c:\Program Files\Debugging Tools for Windows (x86)\windbg.exe" c:\Windows\system32\notepad.exe'

**||** display information what type of debugging we are in, eg.:

    0:001> ||
    .  0 Live user mode: <Local>

**vertarget** shows dump time, OS version, process lifetime, and more

    0:029> vertarget
    Windows Server 2003 Version 3790 (Service Pack 2) MP (2 procs) Free x86 compatible
    Product: Server, suite: TerminalServer SingleUserTS
    kernel32.dll version: 5.2.3790.4062 (srv03_sp2_gdr.070417-0203)
    Machine Name:
    Debug session time: Tue Jul 29 10:51:49.000 2008 (GMT-5)
    System Uptime: 0 days 6:19:45.750
    Process Uptime: 0 days 4:34:57.000
      Kernel time: 0 days 0:24:43.000
      User time: 0 days 0:05:48.000

**version** additionally shows version of the debugging libraries used in the session. The **.time** command displays information about the system time variable (session time).

**.lastevent** shows the last reason why the debugger stopped and **.eventlog** shows a number of recent events.

### Shortcuts and tips ###

There is a great **SHIFT + [UP ARROW]** that completes a command from previously executed commands (much as F8 in cmd).

You may create your own command shortcuts tree with the `.cmdtree` command.

To make **a comment** you can either use `.echo comment` command or one of the comment commands: `$$ comment`, `* comment`. The difference between last two is that `*` sign comments everything till the end of line, when `$$` signs comment text till the semicolon (or end of line), eg.:

    0:000> r eax; $$ some text; r ebx; * more text; r ecx

will print eax, ebx but not ecx. An `.echo` command is ended if the debugger encounters a semicolon (unless the semicolon occurs within a quoted string). Additionally text in `.echo` command gets interpreted.

There is a special **pde** extension which contains commands that will help you to work with string in the debugger. For instance to look for zero-terminated (either unicode or ascii) string use: `!pde.ssz brown`. To change a text in memory use **!ezu**, example: `ezu <memory-address> "test string"`. The extension works on committed memory.

Another interesting command is **!grep** which allows you to filter output of other commands: `!grep _NT !peb`.

### Scripting the debugger ###

when using `.if` , `.foreach` somtimes the names are not resolved - use spaces between them, eg.

    .foreach (addr {!DumpHeap -mt 71d75b24 -short}) { .if (dwo(poi( addr + 5c ) + c)) { !do addr } }

if there was no space between poi( and addr it would fail.

Based on <http://blogs.msdn.com/b/debuggingtoolbox/archive/2009/01/31/special-command-advanced-programming-techniques-for-windbg-scripts.aspx>

### Install windbg as postmortem debugger ###

    windbg -iae

This registration step populates the AeDebug registry key:

    [HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AeDebug]

### Remote debugging ###

You may attach to the currently running session by using `-remote` switch, eg.:

    windbg -remote "npipe:pipe=svcpipe,server=localhost"

To terminate the entire session and exit the debugging server, use the `q (Quit)` command. To exit from one debugging client without terminating the server, you must issue a command from that specific client. If this client is KD or CDB, use the **CTRL+B** key to exit. If you are using a script to run KD or CDB, use `.remote_exit (Exit Debugging Client)`.

### Omit specific method and modules in analysis ###

When running `!analyse -v` windbg makes checks in order to identify the faulting driver (or module). When looking for the faulting module it first checks the "help list" stored in `triage\triage.ini` file in the debuggers home folder.

Check process information
-------------------------

**!peb** shows loaded modules, environment variables, command line arg, and more.

Check threads information
-------------------------

**To list all threads** in a current process use `~` command. Dot (.) in the first column signals a currently selected thread and hash (#) points to a thread on which an exception occurred.

**!runaway** shows quanta of each thread

    0:029> !runaway
     User Mode Time
      Thread       Time
      17:828       0 days 0:04:40.578
      11:380       0 days 0:04:24.046
      14:288       0 days 0:04:14.296
      13:4a0       0 days 0:03:58.984
      29:13e4      0 days 0:01:13.078

**~~[thread-id]** - in case you would like to use the system thread id you may with this syntax.

**!tls Slot** extension displays a thread local storage slot (or -1 for all slots), eg.:

    0:001> !tls 0
    10b8.1628: 00000000

Work with data
--------------

When you have private symbols you may list local variables with the **dv** command.

Additionally the **dt** command allows you to work with type symbols. You may either list them, eg.: `dt notepad!g_*` or dump a data address using a given type format, eg.: `dt nt!_PEG 0x13123`.

With windbg 10.0 a new very interesting command was introduced: **dx**. It uses a navigation expressions just like Visual Studio (you may define your own file .natvis files). You load the interesting .natvis file with the **.nvload** command.

Debugging techniques
--------------------

### Checking stack content ###

Stack grows from high addresses to lower.

When there are many threads running in a process it's common that some of them have same call stacks. To better organize list call stacks we can use the **!uniqstack** command. Adding `-b` parameter adds first three parameters to the output, `-v` displays all parameters (but requires private symbols).

### Switching frames ###

Using `kbn` command we can print the callstack with frame numbers. Even more useful command is `kbM` which displays output using Debugger Markup Language. Each frame number in the display is a link that you can click to set the local context and display local variables.

To switch a local context to a different stack frame we can use the `.frame` command:

    .frame [/c] [/r] [FrameNumber]
    .frame [/c] [/r] = BasePtr [FrameIncrement]
    .frame [/c] [/r] = BasePtr StackPtr InstructionPtr

The `!for_each_frame` extension enables you to execute a single command repeatedly, once for each frame in the stack.


### Controlling the target (g, t, p) ###

To go up the funtion use **gu** command. We can go to a specified address using **ga [address]**. We can also step or trace to a specified address using accordingly **pa** and **ta** commands.

Useful commands are **pc** and **tc** which step or trace to **the next call statement**. **pt** and **tt** step or trace to **the next return statement**.

FIXME wt

### Breakpoints ###

Setting breakpoint if a specific function is in the call stack:

	bp Module!MyFunctionWithConditionalBreakpoint "r $t0 = 0;.foreach (v { k }) { .if ($spat(\"v\", \"*Module!ClassA:MemberFunction*\")) { r $t0 = 1;.break } }; .if($t0 = 0) { gc }"

<http://stackoverflow.com/questions/7791675/windbg-set-conditional-breakpoints-that-depends-on-call-stack/7800435#7800435>, for managed stack visit <http://naveensrinivasan.com/2010/12/28/conditional-breakpoint-based-on-callstack-within-windbg-net/>.

Find process handles
--------------------

There is a special debugger extension command `!handle` that allows you to find system handles reserved by a process:

    !handle [Handle [UMFlags [TypeName]]]

Example:

    0:000> !handle 000001cc f
    Handle 1cc
      Type         	Event
      Attributes   	0
      GrantedAccess	0x1f0003:
             Delete,ReadControl,WriteDac,WriteOwner,Synch
             QueryState,ModifyState
      HandleCount  	2
      PointerCount 	129
      Name         	<none>
      Object Specific Information
        Event Type Manual Reset
        Event is Waiting

To list all handles reserved by a process use -1 (in kernel mode) or 0 (in user-mode) - you filter further by seeting a type of a handle: ` Event, Section, File, Port, Directory, SymbolicLink, Mutant, WindowStation, Semaphore, Key, Token, Process, Thread, Desktop, IoCompletion, Timer, Job, and WaitablePort`, ex.:

    0:000> !handle 0 1 File
    ...
    Handle 1c0
      Type         	File
    7 handles of type File

Links
-----

- [Heap Layout Visualization with mona.py and WinDBG](https://www.corelan.be/index.php/2013/01/18/heap-layout-visualization-with-mona-py-and-windbg/)
- [Obtaining Reliable Thread Call Stacks of 64-bit Processes](http://blogs.microsoft.co.il/blogs/sasha/archive/2013/05/15/obtaining-reliable-thread-call-stacks-of-64-bit-processes.aspx?utm_source=feedly&utm_medium=feed&utm_campaign=Feed%3A+sashag+(All+Your+Base+Are+Belong+To+Us))
- [Customizing the WinDbg environment](http://bsodanalysis.blogspot.fr/2014/07/customizing-windbg-environment.html)
- [Reverse Engineering Windbg Commands for Profit](http://standa-note.blogspot.ca/2015/06/reverse-engineering-winbg-for-profit.html)
- [I have the handle to a file; how can I get the file name from the debugger?](http://blogs.msdn.com/b/oldnewthing/archive/2015/10/16/10648184.aspx)
- ["No .natvis files found" error when you run Debugging Tools For Windows (WinDbg)](https://support.microsoft.com/en-us/kb/3091112)

### Commands ###

- [Interesting Windbg commands explained](http://blogs.microsoft.co.il/blogs/sasha/search.aspx?q=obscure+windbg+commands)
- [dx command and NatVis](https://channel9.msdn.com/Shows/Defrag-Tools/Defrag-Tools-138-Debugging-dx-Command-Part-1)
