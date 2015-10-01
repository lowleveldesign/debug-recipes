
Debugging kernel
================

General information
-------------------

Common function prefixes:

Prefix | Description
-------|------------
Cc | Cache manager
Cm | Configuration manager
Ex | Executive support routines
FsRtl | File system driver run time lib
Hal | Hardware abstraction layer
Io | IO manager
Ke | Kernel
Lpc | Local procedure call
Lsa | Local security authority
Mm | Memory manager
Nt | System services
Ob | Object manager
Po | Power manager
Pp | PnP manager
Ps | Process support
Rtl | Runtime lib
Se | Security
Wmi | Windows management instrumentation
Zw | Kernel version of Nt functions

Gathering machine information
-----------------------------

### Information about the hardware ###

`!cpuinfo` - display CPU manufacturer, speed, features
`!sysinfo cpuinfo` - displays detailed processor information
`!sysinfo machineid` - displays system hardware model, BIOS

### Read Kernel Processor Control Region and Control Block (KPCR and KPRCB) ###

The kernel uses a data structure called the processor control region, or KPCR, to store processor-specific data.

    0: kd> !pcr

Or we can examine the `_KPCR` manually:

    0: kd> dt nt!_KPCR  82d32c00

Kernel Processor Control Region has a special structure embedded into it, called Control Region Block which is used internally by kernel for scheduling purposes:

    0: kd> !prcb
    PRCB for Processor 0 at 82d32d20:
    Current IRQL -- 0
    Threads--  Current 8604b280 Next 00000000 Idle 82d3c380
    Processor Index 0 Number (0, 0) GroupSetMember 1
    Interrupt Count -- 000d9a28
    Times -- Dpc    000000b2 Interrupt 00000044
             Kernel 00009a30 User      000054fc

Having the address in memory of this data structure we can also list it raw content. For instance to check the clock speed of the first processor we can run:

    0: kd> dt nt!_KPRCB 807c4120 Mhz
       +0x3c0 MHz : 0x63c
    0: kd> ? 0x63c
    Evaluate expression: 1596 = 0000063c

Work with user sessions
-----------------------

The **!session** extension displays all logon sessions or changes the current session context. The session context is used by the **!sprocess** and **!spoolused** extensions when the session number is entered as "-2". When the session context is changed, the process context is automatically changed to the active process for that session.

Work with processes and threads in the kernel-mode
--------------------------------------------------

Each time you break into the kernel-mode debugger one of the processes will be active. You may check which one is it by running `!process -1 0` command. If you are going to work with user-mode memory space you need to reload the process modules symbols (otherwise you will see symbols from the last reload). You may do so while switching process context with `.process /i` or `.process /r /p` or manually with the command: `.reload /user`.  The first two command allow you to select which process's page directory is used to interpret virtual addresses. After you set the process context, you can use this context in any command that takes addresses.

    .process [/i] [/p [/r] ] [/P] [Process]

**/i** means invasive debugging and allows you to control the process from the kernel debugger. **/r** reloads user-mode symbols after the process context has been set (the behavior is the same as **.reload /user**). **/p** translates all transition page table entries (PTEs) for this process to physical addresses before access. Example:

    lkd> .process /p /r fffffa8006aac080
    Implicit process is now fffffa80`06aac080
    Loading User Symbols
    .................................Missing image name, possible paged-out or corrupt data.
    .*** WARNING: Unable to verify timestamp for Unknown_Module_00000000`00000000
    Unable to add module at 00000000`00000000
    ..............Missing image name, possible paged-out or corrupt data.
    .*** WARNING: Unable to verify timestamp for Unknown_Module_00000000`00000000
    Unable to add module at 00000000`00000000

Each thread has its own register values. These values are stored in the CPU registers when the thread is executing and are stored in memory when another thread is executing. You can set the register context using **.thread** command:

    .thread [/p [/r] ] [/P] [/w] [Thread]

or

    .trap [Address]
    .cxr [Options] [Address]

### Break when user-mode process is created

```
bp nt!PspInsertProcess
```

The breakpoint is hit whenever a new user-mode process is created. To know what process is it we may access the `_EPROCESS` structure `ImageFileName` field.

```
x64: dt nt!_EPROCESS @rcx ImageFileName
x86: dt nt!_EPROCESS @eax ImageFileName
```

### List processes running in the system

This command lists all processes running currently on the system:

    lkd> !process 0 0
    **** NT ACTIVE PROCESS DUMP ****
    PROCESS fffffa80052071d0
        SessionId: none  Cid: 0004    Peb: 00000000  ParentCid: 0000
        DirBase: 00187000  ObjectTable: fffff8a0000018d0  HandleCount: 905.
        Image: System
    ...

You can now focus on one of the processes, eg.:

    lkd> !process fffffa8006aac080 f

To display information about a specific thread (with its call stack) use the **!thread address** command. By default it will display kernel-mode stacks only, but you may combine both worlds by switching the process context with the **.process /r /p** command.

### Find process by its image name ###

    0: kd> !process 0 0 Test.exe
    PROCESS 85551cc0  SessionId: 1  Cid: 0128    Peb: 7f823000  ParentCid: 0d08
    FreezeCount 1
        DirBase: dcd75740  ObjectTable: f3db2840  HandleCount: <Data Not Accessible>
        Image: Test.exe

### Breakpoint in user-mode process from the kernel-mode ###

You may set a breakpoint in user space, but you need to be in a valid process context:

```
kd> !process 0 0 notepad.exe
PROCESS ffffe0014f80d680
    SessionId: 2  Cid: 0e44    Peb: 7ff7360ef000  ParentCid: 0aac
    DirBase: 2d497000  ObjectTable: ffffc00054529240  HandleCount: <Data Not Accessible>
    Image: notepad.exe

kd> .process /i ffffe0014f80d680
You need to continue execution (press 'g' <enter>) for the context
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
    DirBase: 2d497000  ObjectTable: ffffc00054529240  HandleCount: <Data Not Accessible>
    Image: notepad.exe

kd> x kernel32!CreateFileW
00007ffa`d8502508 KERNEL32!CreateFileW (<no parameter info>)
kd> bp 00007ffa`d8502508
```

Alternative way (which does not require process context switching) is to use data execution breakpoints, eg.:

```
kd> !process 0 0 notepad.exe
PROCESS ffffe0014ca22480
    SessionId: 2  Cid: 0614    Peb: 7ff73628f000  ParentCid: 0d88
    DirBase: 5607b000  ObjectTable: ffffc0005c2dfc40  HandleCount: <Data Not Accessible>
    Image: notepad.exe

kd> .process /r /p ffffe0014ca22480
Implicit process is now ffffe001`4ca22480
.cache forcedecodeuser done
Loading User Symbols
..........................

kd> x KERNEL32!CreateFileW
00007ffa`d8502508 KERNEL32!CreateFileW (<no parameter info>)
kd> ba e1 00007ffa`d8502508
```

For both those commands you may limit their scope to a particular process using /p switch.

### Display currently executed code in all threads (!stacks) ###

FIXME


Diagnosing BugCheck
-------------------

You may need to check what was the IRQL using `!irql` command. Current IRQL is also saved in a Processor Control Region (PCR) which we can examine using `!pcr` command.

Tools
-----

- kernrate - can be used to track CPU usage consumed by individual processes and/or time spent in kernel mode independent of processes (for example, interrupt service routines). Kernel profiling is useful when you want to obtain a breakdown of where the system is spending time

Links
-----

- [Windows 8 kernel debugging: New protocols and certification requirements](http://channel9.msdn.com/Events/Build/BUILD2011/HW-98P)
- [Fun with Windows Kernel Flaw - Part 2: Hunting the important part](http://security.my/post/76395059266/fun-with-windows-kernel-flaw-part-2-hunting-the)
- [Analyst's Perspective: Analyzing User Mode State from a Kernel Connection](https://www.osronline.com/article.cfm?article=576)
