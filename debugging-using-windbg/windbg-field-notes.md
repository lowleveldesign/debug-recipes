General usage
-------------

First, some very useful start commands:

**| - pipe** command displays a path to the process image

You can also use **vercommand** to show how the debugger was called

**||** display information what type of debugging we are in

**vertarget** shows dump time, OS version, process lifetime, and more

**version** additionally shows version of the debugging libraries used in the session. The **.time** command displays information about the system time variable (session time).

**.lastevent** shows the last reason why the debugger stopped and **.eventlog** shows a number of recent events.

### Shortcuts and tips ###

There is a great **SHIFT + [UP ARROW]** that completes a command from previously executed commands (much as F8 in cmd).

You may create your own command shortcuts tree with the `.cmdtree` command.

To make **a comment** you can either use `.echo comment` command or one of the comment commands: `$$ comment`, `* comment`. The difference between last two is that `*` sign comments everything till the end of line, when `$$` signs comment text till the semicolon (or end of line), eg.: <code>r eax; $$ some text; r ebx; * more text; r ecx</code> will print eax, ebx but not ecx. An `.echo` command is ended if the debugger encounters a semicolon (unless the semicolon occurs within a quoted string). Additionally text in `.echo` command gets interpreted.

There is a special **pde** extension which contains commands that will help you to work with string in the debugger. For instance to look for zero-terminated (either unicode or ascii) string use: `!pde.ssz brown`. To change a text in memory use **!ezu**, example: `ezu  "test string"`. The extension works on committed memory.

Another interesting command is **!grep** which allows you to filter output of other commands: `!grep _NT !peb`.

### Scripting the debugger ###

**.expr** prints the current expression evaluator (MASM or C++). You may use the **/s** to change it. The **?** command uses the default evaluator, **??** always uses C++ evaluator. Also you can mix the evaluators in one expression by using **@@c++(expression)** or **@@masm(expression)** syntax, for example: **? @@c++(@$peb->ImageSubsystemMajorVersion) + @@masm(0y1)**.

**#FIELD_OFFSET(Type, Field)** is an interesting operator which returns the offset of the field in the type, eg. **? \#FIELD_OFFSET(\_PEB, ImageSubsystemMajorVersion)**.

when using `.if` , `.foreach` somtimes the names are not resolved - use spaces between them, eg.

<code>.foreach (addr {!DumpHeap -mt 71d75b24 -short}) { .if (dwo(poi( addr + 5c ) + c)) { !do addr } }</code>

if there was no space between poi( and addr it would fail.

Based on http://blogs.msdn.com/b/debuggingtoolbox/archive/2009/01/31/special-command-advanced-programming-techniques-for-windbg-scripts.aspx

### Install windbg as postmortem debugger ###

**windbg -iae**

This registration step populates the AeDebug registry key: **[HKEY\_LOCAL\_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AeDebug]**

### Remote debugging ###

You may attach to the currently running session by using `-remote` switch, eg.: **windbg -remote "npipe:pipe=svcpipe,server=localhost"**

To terminate the entire session and exit the debugging server, use the `q (Quit)` command. To exit from one debugging client without terminating the server, you must issue a command from that specific client. If this client is KD or CDB, use the **CTRL+B** key to exit. If you are using a script to run KD or CDB, use `.remote_exit (Exit Debugging Client)`.

### Omit specific method and modules in analysis ###

When running `!analyse -v` windbg makes checks in order to identify the faulting driver (or module). When looking for the faulting module it first checks the "help list" stored in `triage\triage.ini` file in the debuggers home folder.

System objects in the debugger
------------------------------

### Processes

Each time you break into the kernel-mode debugger one of the processes will be active. You may check which one is it by running **!process -1 0** command. If you are going to work with user-mode memory space you need to reload the process modules symbols (otherwise you will see symbols from the last reload). You may do so while switching process context with **.process /i** or **.process /r /p** or manually with the command: **.reload /user**.  The first two command allow you to select which process's page directory is used to interpret virtual addresses. After you set the process context, you can use this context in any command that takes addresses.

**.process [/i] [/p [/r] ] [/P] [Process]**

**/i** means invasive debugging and allows you to control the process from the kernel debugger. **/r** reloads user-mode symbols after the process context has been set (the behavior is the same as **.reload /user**). **/p** translates all transition page table entries (PTEs) for this process to physical addresses before access.

**!peb** shows loaded modules, environment variables, command line arg, and more.

### Handles

There is a special debugger extension command `!handle` that allows you to find system handles reserved by a process: **!handle [Handle [UMFlags [TypeName]]]**

To list all handles reserved by a process use -1 (in kernel mode) or 0 (in user-mode) - you filter further by seeting a type of a handle: Event, Section, File, Port, Directory, SymbolicLink, Mutant, WindowStation, Semaphore, Key, Token, Process, Thread, Desktop, IoCompletion, Timer, Job, and WaitablePort, ex.:

```
0:000> !handle 0 1 File
...
Handle 1c0
  Type         	File
7 handles of type File
```

### Threads

Each thread has its own register values. These values are stored in the CPU registers when the thread is executing and are stored in memory when another thread is executing. You can set the register context using .thread command:

**.thread [/p [/r] ] [/P] [/w] [Thread]**

or

**.trap [Address]**
**.cxr [Options] [Address]**

**To list all threads** in a current process use `~` command. Dot (.) in the first column signals a currently selected thread and hash (#) points to a thread on which an exception occurred.

**!runaway** shows the time consumed by each thread:

```
0:029> !runaway 7
 User Mode Time
  Thread       Time
   0:bfc       0 days 0:00:00.031
   3:10c       0 days 0:00:00.000
   2:844       0 days 0:00:00.000
   1:15bc      0 days 0:00:00.000
 Kernel Mode Time
  Thread       Time
   0:bfc       0 days 0:00:00.046
   3:10c       0 days 0:00:00.000
   2:844       0 days 0:00:00.000
   1:15bc      0 days 0:00:00.000
 Elapsed Time
  Thread       Time
   0:bfc       0 days 0:27:19.817
   1:15bc      0 days 0:27:19.810
   2:844       0 days 0:27:19.809
   3:10c       0 days 0:27:19.809
```

**~~[thread-id]** - in case you would like to use the system thread id you may with this syntax.

**!tls Slot** extension displays a thread local storage slot (or -1 for all slots)

### Critical sections

Display information about a particular critical section: **!critsec {address}**

**!locks** extension in Ntsdexts.dll displays a list of critical sections associated with the current process.

**!cs -lso [Address]**  - display information about critical sections (-l - only locked critical sections, -o - owner's stack, -s  - initialization stack, if available)

**!critsec Address** - information about a specific critical section

```
0:000> !cs -lso
-----------------------------------------
DebugInfo          = 0x77294380
Critical section   = 0x772920c0 (ntdll!LdrpLoaderLock+0x0)
LOCKED
LockCount          = 0x10
WaiterWoken        = No
OwningThread       = 0x00002c78
RecursionCount     = 0x1
LockSemaphore      = 0x194
SpinCount          = 0x00000000
-----------------------------------------
DebugInfo          = 0x00581850
Critical section   = 0x5164a394 (AcLayers!NS_VirtualRegistry::csRegCriticalSection+0x0)
LOCKED
LockCount          = 0x4
WaiterWoken        = No
OwningThread       = 0x0000206c
RecursionCount     = 0x1
LockSemaphore      = 0x788
SpinCount          = 0x00000000
```

Finally, we may use the raw output:

```
0:000> dx -r1 ((ole32!_RTL_CRITICAL_SECTION_DEBUG *)0x581850)
((ole32!_RTL_CRITICAL_SECTION_DEBUG *)0x581850)                 : 0x581850 [Type: _RTL_CRITICAL_SECTION_DEBUG *]
    [+0x000] Type             : 0x0 [Type: unsigned short]
    [+0x002] CreatorBackTraceIndex : 0x0 [Type: unsigned short]
    [+0x004] CriticalSection  : 0x5164a394 [Type: _RTL_CRITICAL_SECTION *]
    [+0x008] ProcessLocksList [Type: _LIST_ENTRY]
    [+0x010] EntryCount       : 0x0 [Type: unsigned long]
    [+0x014] ContentionCount  : 0x6 [Type: unsigned long]
    [+0x018] Flags            : 0x0 [Type: unsigned long]
    [+0x01c] CreatorBackTraceIndexHigh : 0x0 [Type: unsigned short]
    [+0x01e] SpareUSHORT      : 0x0 [Type: unsigned short]
```

Work with data
--------------

When you have private symbols you may list local variables with the **dv** command.

Additionally the **dt** command allows you to work with type symbols. You may either list them, eg.: `dt notepad!g_*` or dump a data address using a given type format, eg.: `dt nt!_PEG 0x13123`.

With windbg 10.0 a new very interesting command was introduced: **dx**. It uses a navigation expressions just like Visual Studio (you may define your own file .natvis files). You load the interesting .natvis file with the **.nvload** command.

### Stack

Stack grows from high addresses to lower. Thus, when you see addresses bigger than the frame base (such as `ebp+C`) they usually refer to the function arguments. Smaller addresses (such as `ebp-20`) usually refer to local function variables.

To display stack frames use the **k** command. The **kP** command will additionally print function arguments if private symbols are available. The **kbM** command outputs stack frames with first three parameters passed on the stack (those will be first three parameters of the function in x86).

When there are many threads running in a process it's common that some of them have same call stacks. To better organize list call stacks we can use the **!uniqstack** command. Adding **-b** parameter adds first three parameters to the output, **-v** displays all parameters (but requires private symbols).

To switch a local context to a different stack frame we can use the `.frame` command:

```
.frame [/c] [/r] [FrameNumber]
.frame [/c] [/r] = BasePtr [FrameIncrement]
.frame [/c] [/r] = BasePtr StackPtr InstructionPtr
```

The **!for_each_frame** extension enables you to execute a single command repeatedly, once for each frame in the stack.

#### Stack (x64)

X64 calling convention:

- **RCX, RDX, R8, R9** are used for integer and pointer arguments in that order left to right.
- **XMM0, XMM1, XMM2, and XMM3** are used for floating point arguments.
- Additional arguments are pushed on the stack right to left (the parameter below the return address is the first parameter from left).
- It is the caller responsibility to clear the stack after the call.
- **Returned** integer values are in **RAX**, float values are in **XMM0**.

The first four integer/float parameters are passed through registers:

Argument 0
Argument 1
Argument 2
Argument 3

Condition   | Argument 0 | Argument 1 | Argument 2 | Argument 3
------------|------------|------------|------------|------------
If integer  | RCX        | RDX        | R8         | R9
If float    | XMM0       | XMM1       | XMM2       | XMM3

Parameters less than 64 bits are not zero extended and the high bits may contain garbage. Just before the return address there is a “shadow space” 32 bytes long allocated on the stack. It is not initialized and it is up to the called function to save its arguments in it. So the stack might look as follows:


Address    | The value is
-----------|---------------------------
 ...       | ...
RSP - 0x08 | Local variable 0
RSP        | Return address
RSP + 0x08 | Argument 4
RSP + 0x10 | Argument 5
RSP + 0x18 | Argument 6
 ...       | ...

#### Stack (x86)

FIXME:calling conventions

**Reading stacks in WinDbg**

```
0:000> kb
 # ChildEBP RetAddr  Args to Child              
00 0019da88 73ed875c 0019e064 00020019 0019daf4 ntdll!NtOpenKeyEx
01 0019dd20 73ebfc52 0019dfd4 00020019 00000003 KERNELBASE!BaseRegOpenClassKeyFromLocation+0x21c
02 0019def8 73ed851e 00000000 00020019 0019e064 KERNELBASE!BaseRegOpenClassKey+0x93
03 0019dfa8 73ed7fe7 00000000 00020019 0019e064 KERNELBASE!LocalBaseRegOpenKey+0x18e
04 0019e010 73ed7e9c 00000292 0019e138 00000000 KERNELBASE!RegOpenKeyExInternalW+0x137
05 0019e034 74310cf8 00000292 0019e138 00000000 KERNELBASE!RegOpenKeyExW+0x1c
```

The ChildEBP is the actual stack frame address. To see the first three arguments to the `RegOpenKeyExInternalW` you may issue:

```
0:000> dpu 0019e034+8 L3
0019e03c  00000292
0019e040  0019e138 "CLSID\{2BB89983-7EE7-4EBF-858F-9B11D4BD07D6}"
0019e044  00000000
```

Which matches the kb output. The RetAddr is the address where program will continue when the current function call is finished.

### Heap

FIXME

Controlling process execution
-----------------------------


### Controlling the target (g, t, p) ###

To go up the funtion use **gu** command. We can go to a specified address using **ga [address]**. We can also step or trace to a specified address using accordingly **pa** and **ta** commands.

Useful commands are **pc** and **tc** which step or trace to **the next call statement**. **pt** and **tt** step or trace to **the next return statement**.

### Watch trace ###

**wt** is a very powerful command and might be excellent at revealing what the function under the cursor is doing, eg. (-oa displays the actual address of the call sites, -or displays the return register values):

```
0:000> wt -l1 -oa -or
Tracing notepad!NPInit to return address 00007ff6`72c23af5
   11     0 [  0] notepad!NPInit
                      call at 00007ff6`72c27749
   14     0 [  1]   notepad!_chkstk rax = 1570
   20    14 [  0] notepad!NPInit
                      call at 00007ff6`72c27772
   11     0 [  1]   USER32!RegisterWindowMessageW rax = c06f
   26    25 [  0] notepad!NPInit
                      call at 00007ff6`72c2778f
   11     0 [  1]   USER32!RegisterWindowMessageW rax = c06c
   31    36 [  0] notepad!NPInit
                      call at 00007ff6`72c277a5
    6     0 [  1]   USER32!NtUserGetDC rax = 9011652
>> More than one level popped 0 -> 0
   37    42 [  0] notepad!NPInit
                      call at 00007ff6`72c277bc
 1635     0 [  1]   notepad!InitStrings rax = 1
   42  1677 [  0] notepad!NPInit
                      call at 00007ff6`72c277d0
    8     0 [  1]   USER32!LoadCursorW rax = 10007
   46  1685 [  0] notepad!NPInit
                      call at 00007ff6`72c277e4
    8     0 [  1]   USER32!LoadCursorW rax = 10009
   50  1693 [  0] notepad!NPInit
                      call at 00007ff6`72c277fb
   24     0 [  1]   USER32!LoadAcceleratorsW
   24     0 [  1]   USER32!LoadAcc rax = 0
   59  1741 [  0] notepad!NPInit
                      call at 00007ff6`72c27d84
    6     0 [  1]   notepad!_security_check_cookie rax = 0
   69  1747 [  0] notepad!NPInit

1816 instructions were executed in 1815 events (0 from other threads)

Function Name                               Invocations MinInst MaxInst AvgInst
USER32!LoadAcc                                        1      24      24      24
USER32!LoadAcceleratorsW                              1      24      24      24
USER32!LoadCursorW                                    2       8       8       8
USER32!NtUserGetDC                                    1       6       6       6
USER32!RegisterWindowMessageW                         2      11      11      11
notepad!InitStrings                                   1    1635    1635    1635
notepad!NPInit                                        1      69      69      69
notepad!_chkstk                                       1      14      14      14
notepad!_security_check_cookie                        1       6       6       6

1 system call was executed

Calls  System Call
    1  USER32!NtUserGetDC
```

The first number in the trace output specifies the number of instructions that were executed from the beginning of the trace in a given function (it is always incrementing), the second number specifies the number of instructions executed in the child functions (it is also always incrementing), and the third represents the depth of the function in the stack (parameter -l).

### Break when a specific funtion is in the call stack

```
bp Module!MyFunctionWithConditionalBreakpoint "r $t0 = 0;.foreach (v { k }) { .if ($spat(\"v\", \"*Module!ClassA:MemberFunction*\")) { r $t0 = 1;.break } }; .if($t0 = 0) { gc }"
```

### Break when user-mode process is created [Kernel]

**bp nt!PspInsertProcess**

The breakpoint is hit whenever a new user-mode process is created. To know what process is it we may access the \_EPROCESS structure ImageFileName field.

    x64: dt nt!_EPROCESS @rcx ImageFileName
    x86: dt nt!_EPROCESS @eax ImageFileName

### Break in user-mode process from the kernel-mode

You may set a breakpoint in user space, but you need to be in a valid process context:

```
kd> !process 0 0 notepad.exe
PROCESS ffffe0014f80d680
    SessionId: 2  Cid: 0e44    Peb: 7ff7360ef000  ParentCid: 0aac
    DirBase: 2d497000  ObjectTable: ffffc00054529240  HandleCount: 
    Image: notepad.exe

kd> .process /i ffffe0014f80d680
You need to continue execution (press 'g' ) for the context
to be switched. When the debugger breaks in again, you will be in
the new process context.

kd> g
```

Then when you are in a given process context, set the breakpoint:

```
kd> .reload /user
kd> !process -1 0
PROCESS ffffe0014f80d680
    SessionId: 2  Cid: 0e44    Peb: 7ff7360ef000  ParentCid: 0aac
    DirBase: 2d497000  ObjectTable: ffffc00054529240  HandleCount: 
    Image: notepad.exe

kd> x kernel32!CreateFileW
00007ffa`d8502508 KERNEL32!CreateFileW ()
kd> bp 00007ffa`d8502508
```

Alternative way (which does not require process context switching) is to use data execution breakpoints, eg.:

```
kd> !process 0 0 notepad.exe
PROCESS ffffe0014ca22480
    SessionId: 2  Cid: 0614    Peb: 7ff73628f000  ParentCid: 0d88
    DirBase: 5607b000  ObjectTable: ffffc0005c2dfc40  HandleCount: 
    Image: notepad.exe

kd> .process /r /p ffffe0014ca22480
Implicit process is now ffffe001`4ca22480
.cache forcedecodeuser done
Loading User Symbols
..........................

kd> x KERNEL32!CreateFileW
00007ffa`d8502508 KERNEL32!CreateFileW ()
kd> ba e1 00007ffa`d8502508
```

For both those commands you may limit their scope to a particular process using /p switch.

### Find module by an address ###

To find out if a given address belongs to any of the loaded dlls we may use the **!dlls -c {addr}** command.

### Error codes ###

To decode the error value use the **!error {code}** command. To check the last error code on the thread use the **!gle [-all]** command.

