
Windbg debugging tips
=====================

Entry commands
-------------

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

Examining thread stack
----------------------

### Checking stack content

Stack grows from high addresses to lower.

When there are many threads running in a process it's common that some of them have same call stacks. To better organize list call stacks we can use the **!uniqstack** command. Adding `-b` parameter adds first three parameters to the output, `-v` displays all parameters (but requires private symbols).

### Switching frames ###

Using `kbn` command we can print the callstack with frame numbers. Even more useful command is `kbM` which displays output using Debugger Markup Language. Each frame number in the display is a link that you can click to set the local context and display local variables.

To switch a local context to a different stack frame we can use the `.frame` command:

    .frame [/c] [/r] [FrameNumber]
    .frame [/c] [/r] = BasePtr [FrameIncrement]
    .frame [/c] [/r] = BasePtr StackPtr InstructionPtr

The `!for_each_frame` extension enables you to execute a single command repeatedly, once for each frame in the stack.


Controlling the target (g, t, p)
--------------------------------

To go up the funtion use **gu** command. We can go to a specified address using **ga [address]**. We can also step or trace to a specified address using accordingly **pa** and **ta** commands.

Useful commands are **pc** and **tc** which step or trace to **the next call statement**. **pt** and **tt** step or trace to **the next return statement**.

FIXME wt

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

