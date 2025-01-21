---
layout: page
title: WinDbg usage guide
date: 2024-12-04 08:00:00 +0200
redirect_from:
    - /guides/using-ttd/
    - /guides/using-windbg/
---

{% raw %}

**Table of contents:**

<!-- MarkdownTOC -->

- [Installing WinDbg](#installing-windbg)
    - [WinDbgX \(WinDbgNext, formely WinDbg Preview\)](#windbgx-windbgnext-formely-windbg-preview)
    - [Classic WinDbg](#classic-windbg)
- [Configuring WinDbg](#configuring-windbg)
    - [Referencing extensions and scripts for easy access](#referencing-extensions-and-scripts-for-easy-access)
    - [Installing WinDbg as the Windows AE debugger](#installing-windbg-as-the-windows-ae-debugger)
- [Controlling the debugging session](#controlling-the-debugging-session)
    - [Setup Windows Kernel Debugging over network](#setup-windows-kernel-debugging-over-network)
    - [Remote debugging](#remote-debugging)
    - [Getting information about the debugging session](#getting-information-about-the-debugging-session)
- [Symbols and modules](#symbols-and-modules)
- [Working with memory](#working-with-memory)
    - [General memory commands](#general-memory-commands)
    - [Stack](#stack)
    - [Variables](#variables)
    - [Working with strings](#working-with-strings)
- [System objects in the debugger](#system-objects-in-the-debugger)
    - [Processes \(kernel-mode\)](#processes-kernel-mode)
    - [Handles](#handles)
    - [Threads](#threads)
    - [Critical sections](#critical-sections)
- [Controlling process execution](#controlling-process-execution)
    - [Controlling the target \(g, t, p\)](#controlling-the-target-g-t-p)
    - [Watch trace](#watch-trace)
    - [Breaking when a specific function is in the call stack](#breaking-when-a-specific-function-is-in-the-call-stack)
    - [Breaking on a specific function enter and leave](#breaking-on-a-specific-function-enter-and-leave)
    - [Breaking for all methods in the C++ object virtual table](#breaking-for-all-methods-in-the-c-object-virtual-table)
    - [Breaking when a user-mode process is created \(kernel-mode\)](#breaking-when-a-user-mode-process-is-created-kernel-mode)
    - [Setting a user-mode breakpoint in kernel-mode](#setting-a-user-mode-breakpoint-in-kernel-mode)
- [Scripting the debugger](#scripting-the-debugger)
    - [Using meta-commands \(legacy way\)](#using-meta-commands-legacy-way)
    - [Using the dx command](#using-the-dx-command)
        - [Using variables and creating new objects in the dx query](#using-variables-and-creating-new-objects-in-the-dx-query)
        - [Example queries with explanations](#example-queries-with-explanations)
        - [Managed application support in the dx queries](#managed-application-support-in-the-dx-queries)
    - [Using the JavaScript engine](#using-the-javascript-engine)
        - [Loading a script](#loading-a-script)
        - [Running a script](#running-a-script)
        - [Debugging a script](#debugging-a-script)
    - [Launching commands from a script file](#launching-commands-from-a-script-file)
- [Time Travel Debugging \(TTD\)](#time-travel-debugging-ttd)
    - [Installation](#installation)
    - [Collection](#collection)
    - [Accessing TTD data](#accessing-ttd-data)
    - [Querying debugging events](#querying-debugging-events)
    - [Examining function calls](#examining-function-calls)
    - [Position in TTD trace](#position-in-ttd-trace)
    - [Examining memory access](#examining-memory-access)
- [Misc tips](#misc-tips)
    - [Converting a memory dump from one format to another](#converting-a-memory-dump-from-one-format-to-another)
    - [Loading an arbitrary DLL into WinDbg for analysis](#loading-an-arbitrary-dll-into-windbg-for-analysis)
    - [Keyboard and mouse shortcuts](#keyboard-and-mouse-shortcuts)
    - [Running a command for all the processes](#running-a-command-for-all-the-processes)
    - [Attaching to multiple processes at once](#attaching-to-multiple-processes-at-once)
    - [Injecting a DLL into a process being debugged](#injecting-a-dll-into-a-process-being-debugged)

<!-- /MarkdownTOC -->

Installing WinDbg
-----------------

### WinDbgX (WinDbgNext, formely WinDbg Preview)

On modern systems download the [appinstaller](https://learn.microsoft.com/en-us/windows-hardware/drivers/debugger/) file and choose Install in the context menu. If you are on Windows Server 2019 and you don't see the Install option in the context menu, there is a big chance you're missing the App Installer package on your system. In that case, you may download and run **[this PowerShell script](/assets/other/windbg-install.ps1.txt)** ([created by @Izybkr](https://github.com/microsoftfeedback/WinDbg-Feedback/issues/19#issuecomment-1513926394) with my minor updates to make it work with latest WinDbg releases).

### Classic WinDbg

If you need to debug on an old system with no support for WinDbgX, you need to **download Windows SDK and install the Debugging Tools for Windows** feature. Executables will be in the Debuggers folder, for example, `c:\Program Files (x86)\Windows Kits\10\Debuggers`.

Configuring WinDbg
------------------

### Referencing extensions and scripts for easy access

When we use the **.load** or **.scriptload** commands, WinDbg will search for extensions in the following folders:

- `{install_folder}\{target_arch}\winxp`
- `{install_folder}\{target_arch}\winext`
- `{install_folder}\{target_arch}\winext\arcade`
- `{install_folder}\{target_arch}\pri`
- `{install_folder}\{target_arch}`
- `%LOCALAPPDATA%\DBG\EngineExtensions32` or `%LOCALAPPDATA%\DBG\EngineExtensions` (only WinDbgX)
- `%PATH%`

where target_arch is either x86 or amd64.

I usually include the directories containing the JavaScript scripts in the PATH since they are architecture-agnostic. As for the 32- and 64-bit DLLs, I store them in EngineExtensions32 and EngineExtensions folders, respectively.

It is also possible to configure [extensions galleries](https://github.com/microsoft/WinDbg-Samples/tree/master/Manifest). Unfortunately, I didn't manage to make it work with my own extensions.

### Installing WinDbg as the Windows AE debugger

The **windbx -I** (**windbg -iae**) command registers WinDbg as the automatic system debugger - it will launch anytime an application crashes. The modified AeDebug registry keys:

```
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AeDebug
HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows NT\CurrentVersion\AeDebug
```

However, we may also use configure those keys manually and use WinDbg to, for example, create a memory dump when the application crashes:

```
REG_SZ Debugger = "C:\Users\me\AppData\Local\Microsoft\WindowsApps\WinDbgX.exe" -c ".dump /ma /u C:\dumps\crash.dmp; qd" -p %ld -e %ld -g
REG_SZ Auto = 1
```

If you miss the **-g** option, WinDbg will inject a remote thread with a breakpoint instruction, which will hide our original exception. In such case, you might need to scan the stack to find the original exception record.

Controlling the debugging session
---------------------------------

### Setup Windows Kernel Debugging over network

*HYPER-V note*: When debugging a Gen 2 VM remember to turn off the secure booting: `Set-VMFirmware -VMName "Windows 2012 R2" -EnableSecureBoot Off -Confirm`

Turn on network debugging (HOSTIP is the address of the machine on which we will run the debugger):

```shell
bcdedit /dbgsettings NET HOSTIP:192.168.0.2 PORT:60000
# Key=3ma3qyz02ptls.23uxbvnd0e2zh.1gnwiqb6v3mpb.mjltos9cf63x

bcdedit /debug {current} on
# The operation completed successfully.
```

Then on the host machine, run windbg, select **Attach to kernel** and fill the port and key textboxes.

**Network card compatibility check**

Starting from Debugging Tools for Windows 10 we have an additional tool: **kdnet.exe**. By running it on the guest you may see if your network card supports kernel debugging and get the instructions for the host machine:

```shell
kdnet 172.25.121.1 60000
# Enabling network debugging on Microsoft Hypervisor Virtual Machine.
# Key=xxxx
#
# To finish setting up KDNET for this VM, run the following command from an
# elevated command prompt running on the Windows hyper-v host.  (NOT this VM!)
# powershell -ExecutionPolicy Bypass kdnetdebugvm.ps1 -vmguid DD4F4AFE-9B5F-49AD-8
# 775-20863740C942 -port 60000
#
# To debug this vm, run the following command on your debugger host machine.
# windbg -k net:port=60000,key=xxxx,target=DELAPTOP
#
# Then make sure to SHUTDOWN (not restart) the VM so that the new settings will
# take effect.  Run shutdown -s -t 0 from this command prompt.
```

If you are hosting your guest **on QEMU KVM** and want to use network debugging, you need to either create your VM as a Generic one (not Windows) or update the VM configuration XML, changing the vendor_id under the hyperv node, for example:

```xml
<domain type="kvm">
  <name>win2k19</name>
  <!-- ... -->
  <features>
    <acpi/>
    <apic/>
    <hyperv mode="custom">
      <relaxed state="on"/>
      <vapic state="on"/>
      <spinlocks state="on" retries="8191"/>
      <vendor_id state="on" value="KVMKVMKVM"/>
    </hyperv>
    <!-- ... -->
  </features>
  <!-- ... -->
</domain> 
```

I highly recommend checking [this post by the OSR team](https://www.osr.com/blog/2021/10/05/using-windbg-over-kdnet-on-qemu-kvm/) describing why those changes are required and revealing some details about the kdnet inner working. 

### Remote debugging

To start a remote session of WinDbg, you may use the **-server** switch, e.g.: `windbg(x) -server "npipe:pipe=svcpipe" notepad`.

You may attach to the currently running session by using **-remote** switch, e.g.: `windbg(x) -remote "npipe:pipe=svcpipe,server=localhost"`

To terminate the entire session and exit the debugging server, use the **q (Quit)** command. To exit from one debugging client without terminating the server, you must issue a command from that specific client. If this client is KD or CDB, use the **CTRL+B** key to exit. If you are using a script to run KD or CDB, use **.remote_exit (Exit Debugging Client)**.

### Getting information about the debugging session

The **\|** command displays a path to the process image. You may run **vercommand** to check how the debugger was launched. The **vertarget** command shows the OS version, the process lifetime, and more, for example, the dump time when debugging a memory dump. The **.time** command displays information about the system time variable (session time).

**.lastevent** shows the last reason why the debugger stopped and **.eventlog** displays the recent events.

Symbols and modules
-------------------

The **lm** command lists all modules with symbol load info. To examine a specific module, use **lmvm {module-name}**. To find out if a given address belongs to any of the loaded dlls you may use the **!dlls -c {addr}** command. Another way would be to use the **lma {addr}** command.

The **.sympath** command shows the symbol search path and allows its modification. Use **.reload /f {module-name}** to reload symbols for a given module.

The **x {module-name}!{function}** command resolves a function address, and **ln {address}** finds the nearest symbol.

When we don't have access to the symbol server, we may create a list of required symbols with **symchk.exe** (part of the Debugging Tools for Windows installation) and download them later on a different host. First, we need to prepare the manifest, for example:

```shell
symchk /id test.dmp /om test.dmp.sym /s C:\non-existing
```

Then copy it to the machine with the symbol server access, and download the required symbols, for example:

```shell
symchk /im test.dmp.sym /s SRV*C:\symbols*https://msdl.microsoft.com/download/symbols
```

In WinDbgX, we may also list and filter modules with the **@$curprocess.Modules** property. Some usage examples:

```shell
dx @$curprocess.Modules["win32u.dll"]
# @$curprocess.Modules["win32u.dll"]                 : C:\WINDOWS\System32\win32u.dll
#     BaseAddress      : 0x7ffa0e2c0000
#     Name             : C:\WINDOWS\System32\win32u.dll
#     Size             : 0x26000
#     Attributes
#     Contents
#     Symbols          : [SymbolModule]win32u

dx @$curprocess.Modules["win32u.dll"].Contents.Exports
#@$curprocess.Modules["win32u.dll"].Contents.Exports
#    [0x0]            : Function export of 'NtBindCompositionSurface'
#    [0x1]            : Function export of 'NtCloseCompositionInputSink'
#    ...

# List modules with information if they have combase.dll as a direct import
dx -g @$curprocess.Modules.Select(m => new { Name = m.Name, HasCombase = m.Contents.Imports.Any(i => i.ModuleName == "combase.dll") })
```

Working with memory
-------------------

### General memory commands

The `!address` command shows information about a specific region of memory, for example:

```shell
!address 0x00fd7df8
# Usage:                  Image
# Base Address:           00fd6000
# End Address:            00fdc000
# Region Size:            00006000 (  24.000 kB)
# State:                  00001000          MEM_COMMIT
# Protect:                00000002          PAGE_READONLY
# Type:                   01000000          MEM_IMAGE
# Allocation Base:        00fb0000
# Allocation Protect:     00000080          PAGE_EXECUTE_WRITECOPY
# Image Path:             prog.exe
# Module Name:            prog
# Loaded Image Name:      c:\test\prog.exe
# Mapped Image Name:
# More info:              lmv m prog
# More info:              !lmi prog
# More info:              ln 0xfd7df8
# More info:              !dh 0xfb0000
```

Additionally, it can display regions of memory of specific type, for example:

```shell
!address -f:FileMap
#   BaseAddr EndAddr+1 RgnSize     Type       State                 Protect             Usage
# -----------------------------------------------------------------------------------------------
#   9a0000   9b0000    10000 MEM_MAPPED  MEM_COMMIT  PAGE_READWRITE                     MappedFile "PageFile"
#   9b0000   9b1000     1000 MEM_MAPPED  MEM_COMMIT  PAGE_READONLY                      MappedFile "PageFile"
#   9c0000   9c1000     1000 MEM_MAPPED  MEM_COMMIT  PAGE_READONLY                      MappedFile "PageFile"
#   d50000   e19000    c9000 MEM_MAPPED  MEM_COMMIT  PAGE_READONLY                      MappedFile "\Device\HarddiskVolume3\Windows\System32\locale.nls"
#   ff0000   ff1000     1000 MEM_MAPPED  MEM_COMMIT  PAGE_READONLY                      MappedFile "PageFile"
# 7f995000 7fa90000    fb000 MEM_MAPPED  MEM_RESERVE                                    MappedFile "PageFile"
# 7fae0000 7fae1000     1000 MEM_MAPPED  MEM_COMMIT  PAGE_READONLY                      MappedFile "PageFile"

!address -f:MEM_MAPPED
#   BaseAddr EndAddr+1 RgnSize     Type       State                 Protect             Usage
# -----------------------------------------------------------------------------------------------
#   9a0000   9b0000    10000 MEM_MAPPED  MEM_COMMIT  PAGE_READWRITE                     MappedFile "PageFile"
#   9b0000   9b1000     1000 MEM_MAPPED  MEM_COMMIT  PAGE_READONLY                      MappedFile "PageFile"
#   9c0000   9c1000     1000 MEM_MAPPED  MEM_COMMIT  PAGE_READONLY                      MappedFile "PageFile"
#   9d0000   9ed000    1d000 MEM_MAPPED  MEM_COMMIT  PAGE_READONLY                      Other      [API Set Map]
#   9f0000   9f4000     4000 MEM_MAPPED  MEM_COMMIT  PAGE_READONLY                      Other      [System Default Activation Context Data]
#   d50000   e19000    c9000 MEM_MAPPED  MEM_COMMIT  PAGE_READONLY                      MappedFile "\Device\HarddiskVolume3\Windows\System32\locale.nls"
#   ff0000   ff1000     1000 MEM_MAPPED  MEM_COMMIT  PAGE_READONLY                      MappedFile "PageFile"
# 7f990000 7f995000     5000 MEM_MAPPED  MEM_COMMIT  PAGE_READONLY                      Other      [Read Only Shared Memory]
# 7f995000 7fa90000    fb000 MEM_MAPPED  MEM_RESERVE                                    MappedFile "PageFile"
# 7fae0000 7fae1000     1000 MEM_MAPPED  MEM_COMMIT  PAGE_READONLY                      MappedFile "PageFile"
# 7faf0000 7fb13000    23000 MEM_MAPPED  MEM_COMMIT  PAGE_READONLY                      Other      [NLS Tables]
```

### Stack

Stack grows from high addresses to lower. Thus, when you see addresses bigger than the frame base (such as ebp+C) they usually refer to the function arguments. Smaller addresses (such as ebp-20) usually refer to local function variables.

To display stack frames use the **k** command. The **kP** command will additionally print function arguments if private symbols are available. The **kbM** command outputs stack frames with first three parameters passed on the stack (those will be first three parameters of the function in x86).

When there are many threads running in a process it's common that some of them have the same call stacks. To better organize call stacks we can use the **!uniqstack** command. Adding **-b** parameter adds first three parameters to the output, **-v** displays all parameters (but requires private symbols).

To switch a local context to a different stack frame we can use the **.frame** command:

```shell
.frame [/c] [/r] [FrameNumber]
.frame [/c] [/r] = BasePtr [FrameIncrement]
.frame [/c] [/r] = BasePtr StackPtr InstructionPtr
```

The **!for_each_frame** extension command enables you to execute a single command repeatedly, once for each frame in the stack.

In WinDbgX, we may access the call stack frames using **dx @$curstack.Frames**, for example:

```shell
dx @$curstack.Frames
# @$curstack.Frames
#     [0x0]            : ntdll!LdrpDoDebuggerBreak + 0x30 [Switch To]
#     [0x1]            : ntdll!LdrpInitializeProcess + 0x1cfa [Switch To]
#     [0x2]            : ntdll!_LdrpInitialize + 0x56298 [Switch To]
#     [0x3]            : ntdll!LdrpInitializeInternal + 0x6b [Switch To]
#     [0x4]            : ntdll!LdrInitializeThunk + 0xe [Switch To]

dx @$curstack.Frames[0].Attributes
# InstructionOffset : 0x7ffa1102b784
# ReturnOffset     : 0x7ffa1102e9d6
# FrameOffset      : 0xea5055f370
# StackOffset      : 0xea5055f340
# FuncTableEntry   : 0x0
# Virtual          : 1
# FrameNumber      : 0x0
# SourceInformation
```

### Variables

When you have private symbols you may list local variables with the **dv** command.

Additionally the **dt** command allows you to work with type symbols. You may either list them, eg.: `dt notepad!g_*` or dump a data address using a given type format, eg.: `dt nt!_PEB 0x13123`.

The **dx** command allows you to dump local variables or read them from any place in the memory. It uses a navigation expressions just like Visual Studio (you may define your own file .natvis files). You load the interesting .natvis file with the **.nvload** command.

**#FIELD_OFFSET(Type, Field)** is an interesting operator which returns the offset of the field in the type, eg. **? \#FIELD_OFFSET(\_PEB, ImageSubsystemMajorVersion)**.

### Working with strings

The **!du** command from the [PDE extension](https://onedrive.live.com/redir?resid=DAE128BD454CF957!7152&authkey=!AJeSzeiu8SQ7T4w&ithint=folder%2czip) shows strings up to 4GB (the default du command stops when it hits the range limit).

The PDE extension also contains the **!ssz** command to look for zero-terminated (either unicode or ascii) strings. To change a text in memory use **!ezu**, for example: `ezu  "test string"`. The extension works on committed memory.

Another interesting command is **!grep**, which allows you to filter the output of other commands: `!grep _NT !peb`.

System objects in the debugger
------------------------------

The **!object** command displays some basic information about a kernel object:

```shell
!object  ffffc30162f26080
# Object: ffffc30162f26080  Type: (ffffc30161891d20) Process
#     ObjectHeader: ffffc30162f26050 (new version)
#     HandleCount: 23  PointerCount: 582900
```

We may then analyze the object header to learn some more details about the object, for example:

```shell
dx (nt!_OBJECT_HEADER *)0xffffc30162f26050
# (nt!_OBJECT_HEADER *)0xffffc30162f26050                 : 0xffffc30162f26050 [Type: _OBJECT_HEADER *]
#     [+0x000] PointerCount     : 582900 [Type: __int64]
#     [+0x008] HandleCount      : 23 [Type: __int64]
#     [+0x008] NextToFree       : 0x17 [Type: void *]
#     [+0x010] Lock             [Type: _EX_PUSH_LOCK]
#     [+0x018] TypeIndex        : 0x5 [Type: unsigned char]
#     [+0x019] TraceFlags       : 0x0 [Type: unsigned char]
#     [+0x019 ( 0: 0)] DbgRefTrace      : 0x0 [Type: unsigned char]
#     [+0x019 ( 1: 1)] DbgTracePermanent : 0x0 [Type: unsigned char]
#     [+0x01a] InfoMask         : 0x88 [Type: unsigned char]
#     [+0x01b] Flags            : 0x0 [Type: unsigned char]
#     [+0x01b ( 0: 0)] NewObject        : 0x0 [Type: unsigned char]
#     [+0x01b ( 1: 1)] KernelObject     : 0x0 [Type: unsigned char]
#     [+0x01b ( 2: 2)] KernelOnlyAccess : 0x0 [Type: unsigned char]
#     [+0x01b ( 3: 3)] ExclusiveObject  : 0x0 [Type: unsigned char]
#     [+0x01b ( 4: 4)] PermanentObject  : 0x0 [Type: unsigned char]
#     [+0x01b ( 5: 5)] DefaultSecurityQuota : 0x0 [Type: unsigned char]
#     [+0x01b ( 6: 6)] SingleHandleEntry : 0x0 [Type: unsigned char]
#     [+0x01b ( 7: 7)] DeletedInline    : 0x0 [Type: unsigned char]
#     [+0x01c] Reserved         : 0x62005c [Type: unsigned long]
#     [+0x020] ObjectCreateInfo : 0xffffc301671872c0 [Type: _OBJECT_CREATE_INFORMATION *]
#     [+0x020] QuotaBlockCharged : 0xffffc301671872c0 [Type: void *]
#     [+0x028] SecurityDescriptor : 0xffffd689feeef0ea [Type: void *]
#     [+0x030] Body             [Type: _QUAD]
#     ObjectType       : Process
#     UnderlyingObject [Type: _EPROCESS]

dx -r1 (*((ntkrnlmp!_EPROCESS *)0xffffc30162f26080))
# (*((ntkrnlmp!_EPROCESS *)0xffffc30162f26080))                 [Type: _EPROCESS]
#     [+0x000] Pcb              [Type: _KPROCESS]
#     [+0x438] ProcessLock      [Type: _EX_PUSH_LOCK]
#     [+0x440] UniqueProcessId  : 0x1488 [Type: void *]
#     [+0x448] ActiveProcessLinks [Type: _LIST_ENTRY]
#     [+0x458] RundownProtect   [Type: _EX_RUNDOWN_REF]
#     [+0x460] Flags2           : 0x200d014 [Type: unsigned long]
#     [+0x460 ( 0: 0)] JobNotReallyActive : 0x0 [Type: unsigned long]
#     [+0x460 ( 1: 1)] AccountingFolded : 0x0 [Type: unsigned long]
#     [+0x460 ( 2: 2)] NewProcessReported : 0x1 [Type: unsigned long]
#     ...
```

### Processes (kernel-mode)

Each time you break into the kernel-mode debugger, one of the processes will be active. You may learn which one by running the **!process -1 0** command. If you are going to work with user-mode memory space you need to reload the process modules symbols (otherwise you will see symbols from the last reload). You may do so while switching process context with **.process /i** or **.process /r /p**, or ,manually, with the command: **.reload /user**. **/i** means invasive debugging and allows you to control the process from the kernel debugger. **/r** reloads user-mode symbols after the process context has been set (the behavior is the same as **.reload /user**). **/p** translates all transition page table entries (PTEs) for this process to physical addresses before access.

**!peb** shows loaded modules, environment variables, command line arg, and more.

The **!process 0 0 {image}** command finds a proces using its image name, e.g.: `!process 0 0 LINQPad.UserQuery.exe`.

When we know the process ID, we may use **!process {PID \| address} 0x7** (the 0x7 flag will list all the threads with their stacks)

### Handles

There is a special debugger extension command **!handle** that allows you to find system handles reserved by a process: **!handle [Handle [UMFlags [TypeName]]]**

To list all handles reserved by a process use -1 (in kernel mode) or 0 (in user-mode) - you filter further by seeting a type of a handle: Event, Section, File, Port, Directory, SymbolicLink, Mutant, WindowStation, Semaphore, Key, Token, Process, Thread, Desktop, IoCompletion, Timer, Job, and WaitablePort, ex.:

```shell
!handle 0 1 File
# ...
# Handle 1c0
#   Type          File
# 7 handles of type File
```

### Threads

The **!thread {addr}** command shows details about a specific thread.

Each thread has its own register values. These values are stored in the CPU registers when the thread is executing and are stored in memory when another thread is executing. You can set the register context using .thread command:

**.thread [/p [/r] ] [/P] [/w] [Thread]**

or

**.trap [Address]**
**.cxr [Options] [Address]**

For WOW64 processes, the **/w** parameter (**.thread /w**) will additionally switch to the x86 context. After loading the thread context, the commands opearating on stack should start working (remember to be in the right process context).

**To list all threads** in a current process use **~** command (user-mode). Dot (.) in the first column signals a currently selected thread and hash (#) points to a thread on which an exception occurred.

**!runaway** shows the time consumed by each thread:

```shell
!runaway 7
# User Mode Time
#  Thread       Time
#   0:bfc       0 days 0:00:00.031
#   3:10c       0 days 0:00:00.000
#   2:844       0 days 0:00:00.000
#   1:15bc      0 days 0:00:00.000
# Kernel Mode Time
#  Thread       Time
#   0:bfc       0 days 0:00:00.046
#   3:10c       0 days 0:00:00.000
#   2:844       0 days 0:00:00.000
#   1:15bc      0 days 0:00:00.000
# Elapsed Time
#  Thread       Time
#   0:bfc       0 days 0:27:19.817
#   1:15bc      0 days 0:27:19.810
#   2:844       0 days 0:27:19.809
#   3:10c       0 days 0:27:19.809
```

**\~\~\[thread-id\]** - in case you would like to use the system thread id you may with this syntax.

**!tls Slot** extension displays a thread local storage slot (or -1 for all slots)

### Critical sections

Display information about a particular critical section: **!critsec {address}**

**!locks** extension in Ntsdexts.dll displays a list of critical sections associated with the current process.

**!cs -lso [Address]**  - display information about critical sections (-l - only locked critical sections, -o - owner's stack, -s  - initialization stack, if available)

**!critsec Address** - information about a specific critical section

```shell
!cs -lso
# -----------------------------------------
# DebugInfo          = 0x77294380
# Critical section   = 0x772920c0 (ntdll!LdrpLoaderLock+0x0)
# LOCKED
# LockCount          = 0x10
# WaiterWoken        = No
# OwningThread       = 0x00002c78
# RecursionCount     = 0x1
# LockSemaphore      = 0x194
# SpinCount          = 0x00000000
# -----------------------------------------
# DebugInfo          = 0x00581850
# Critical section   = 0x5164a394 (AcLayers!NS_VirtualRegistry::csRegCriticalSection+0x0)
# LOCKED
# LockCount          = 0x4
# WaiterWoken        = No
# OwningThread       = 0x0000206c
# RecursionCount     = 0x1
# LockSemaphore      = 0x788
# SpinCount          = 0x00000000
```

Finally, we may use the raw output:

```shell
dx -r1 ((ole32!_RTL_CRITICAL_SECTION_DEBUG *)0x581850)
# ((ole32!_RTL_CRITICAL_SECTION_DEBUG *)0x581850)                 : 0x581850 [Type: _RTL_CRITICAL_SECTION_DEBUG *]
#     [+0x000] Type             : 0x0 [Type: unsigned short]
#     [+0x002] CreatorBackTraceIndex : 0x0 [Type: unsigned short]
#     [+0x004] CriticalSection  : 0x5164a394 [Type: _RTL_CRITICAL_SECTION *]
#     [+0x008] ProcessLocksList [Type: _LIST_ENTRY]
#     [+0x010] EntryCount       : 0x0 [Type: unsigned long]
#     [+0x014] ContentionCount  : 0x6 [Type: unsigned long]
#     [+0x018] Flags            : 0x0 [Type: unsigned long]
#     [+0x01c] CreatorBackTraceIndexHigh : 0x0 [Type: unsigned short]
#     [+0x01e] SpareUSHORT      : 0x0 [Type: unsigned short]
```

Controlling process execution
-----------------------------

### Controlling the target (g, t, p)

To go up the funtion use **gu** command. We can go to a specified address using **ga [address]**. We can also step or trace to a specified address using accordingly **pa** and **ta** commands.

Useful commands are **pc** and **tc** which step or trace to **the next call statement**. **pt** and **tt** step or trace to **the next return statement**.

### Watch trace

**wt** is a very powerful command and might be excellent at revealing what the function under the cursor is doing, eg. (-oa displays the actual address of the call sites, -or displays the return register values):

```shell
wt -l1 -oa -or
# Tracing notepad!NPInit to return address 00007ff6`72c23af5
#    11     0 [  0] notepad!NPInit
#                       call at 00007ff6`72c27749
#    14     0 [  1]   notepad!_chkstk rax = 1570
#    20    14 [  0] notepad!NPInit
#                       call at 00007ff6`72c27772
#    11     0 [  1]   USER32!RegisterWindowMessageW rax = c06f
#    26    25 [  0] notepad!NPInit
#                       call at 00007ff6`72c2778f
#    11     0 [  1]   USER32!RegisterWindowMessageW rax = c06c
#    31    36 [  0] notepad!NPInit
#                       call at 00007ff6`72c277a5
#     6     0 [  1]   USER32!NtUserGetDC rax = 9011652
# >> More than one level popped 0 -> 0
#    37    42 [  0] notepad!NPInit
#                       call at 00007ff6`72c277bc
#  1635     0 [  1]   notepad!InitStrings rax = 1
#    42  1677 [  0] notepad!NPInit
#                       call at 00007ff6`72c277d0
#     8     0 [  1]   USER32!LoadCursorW rax = 10007
#    46  1685 [  0] notepad!NPInit
#                       call at 00007ff6`72c277e4
#     8     0 [  1]   USER32!LoadCursorW rax = 10009
#    50  1693 [  0] notepad!NPInit
#                       call at 00007ff6`72c277fb
#    24     0 [  1]   USER32!LoadAcceleratorsW
#    24     0 [  1]   USER32!LoadAcc rax = 0
#    59  1741 [  0] notepad!NPInit
#                       call at 00007ff6`72c27d84
#     6     0 [  1]   notepad!_security_check_cookie rax = 0
#    69  1747 [  0] notepad!NPInit
# 
# 1816 instructions were executed in 1815 events (0 from other threads)
# 
# Function Name                               Invocations MinInst MaxInst AvgInst
# USER32!LoadAcc                                        1      24      24      24
# USER32!LoadAcceleratorsW                              1      24      24      24
# USER32!LoadCursorW                                    2       8       8       8
# USER32!NtUserGetDC                                    1       6       6       6
# USER32!RegisterWindowMessageW                         2      11      11      11
# notepad!InitStrings                                   1    1635    1635    1635
# notepad!NPInit                                        1      69      69      69
# notepad!_chkstk                                       1      14      14      14
# notepad!_security_check_cookie                        1       6       6       6
# 
# 1 system call was executed
# 
# Calls  System Call
#     1  USER32!NtUserGetDC
```

The first number in the trace output specifies the number of instructions that were executed from the beginning of the trace in a given function (it is always incrementing), the second number specifies the number of instructions executed in the child functions (it is also always incrementing), and the third represents the depth of the function in the stack (parameter -l).

If the **wt** command does not work, you may achieve similar results manually with the help of the target controlling commands:

- stepping until a specified address: **ta**, **pa**
- stepping until the next branching instruction: **th**, **ph**
- stepping until the next call instruction: **tc**, **pc**
- stepping until the next return: **tt**, **pt**
- stepping until the next return or call instruction: **tct**, **pct**


### Breaking when a specific function is in the call stack

```shell
bp Module!MyFunctionWithConditionalBreakpoint "r $t0 = 0;.foreach (v { k }) { .if ($spat(\"v\", \"*Module!ClassA:MemberFunction*\")) { r $t0 = 1;.break } }; .if($t0 = 0) { gc }"
```

### Breaking on a specific function enter and leave

The trick is to set a one-time breakpoint on the return address (**bp /1 @$ra**) when the main breakpoint is hit, for example:

```shell
bp 031a6160 "dt ntdll!_GUID poi(@esp + 8); .printf /D \"==> obj addr: %p\", poi(@esp + C);.echo; bp /1 @$ra; g"
bp kernel32!RegOpenKeyExW "du @rdx; bp /1 @$ra \"r @$retreg; g\"; g"
```

```shell
bp kernelbase!CreateFileW ".printf \"CreateFileW('%mu', ...)\", @rcx; bp /1 @$ra \".printf \\\" => %p\\\\n\\\", @rax; g\"; g"
bp kernelbase!DeviceIoControl ".printf \"DeviceIoControl(%p, %p, ...)\\n\", @rcx, @rdx; g"
bp kernelbase!CloseHandle ".printf \"CloseHandle(%p)\\n\", @rcx;g"
```

Remove the 'g' commands from the above samples if you want the debugger to stop.

### Breaking for all methods in the C++ object virtual table

This could be useful when debugging COM interfaces, as in the example below. When we know the number of methods in the interface and the address of the virtual table, we may set the breakpoint using the .for loop, for example:

```shell
.for (r $t0 = 0; @$t0 < 5; r $t0= @$t0 + 1) { bp poi(5f4d8948 + @$t0 * @$ptrsize) }
```

### Breaking when a user-mode process is created (kernel-mode)

**bp nt!PspInsertProcess**

The breakpoint is hit whenever a new user-mode process is created. To know what process is it we may access the \_EPROCESS structure ImageFileName field.

```shell
# x64
dt nt!_EPROCESS @rcx ImageFileName
# x86
dt nt!_EPROCESS @eax ImageFileName
```

### Setting a user-mode breakpoint in kernel-mode

You may set a breakpoint in user space, but you need to be in a valid process context:

```shell
!process 0 0 notepad.exe
# PROCESS ffffe0014f80d680
#     SessionId: 2  Cid: 0e44    Peb: 7ff7360ef000  ParentCid: 0aac
#     DirBase: 2d497000  ObjectTable: ffffc00054529240  HandleCount:
#     Image: notepad.exe

.process /i ffffe0014f80d680
# You need to continue execution (press 'g' ) for the context
# to be switched. When the debugger breaks in again, you will be in
# the new process context.

kd> g
```

Then when you are in a given process context, set the breakpoint:

```shell
.reload /user

!process -1 0
# PROCESS ffffe0014f80d680
#     SessionId: 2  Cid: 0e44    Peb: 7ff7360ef000  ParentCid: 0aac
#     DirBase: 2d497000  ObjectTable: ffffc00054529240  HandleCount:
#     Image: notepad.exe

x kernel32!CreateFileW
# 00007ffa`d8502508 KERNEL32!CreateFileW ()

bp 00007ffa`d8502508
```

Alternative way (which does not require process context switching) is to use data execution breakpoints, eg.:

```shell
!process 0 0 notepad.exe
# PROCESS ffffe0014ca22480
#     SessionId: 2  Cid: 0614    Peb: 7ff73628f000  ParentCid: 0d88
#     DirBase: 5607b000  ObjectTable: ffffc0005c2dfc40  HandleCount:
#     Image: notepad.exe

.process /r /p ffffe0014ca22480
# Implicit process is now ffffe001`4ca22480
# .cache forcedecodeuser done
# Loading User Symbols
# ..........................

x KERNEL32!CreateFileW
# 00007ffa`d8502508 KERNEL32!CreateFileW ()

ba e1 00007ffa`d8502508
```

For both those commands you may limit their scope to a particular process using /p switch.

Scripting the debugger
----------------------

### Using meta-commands (legacy way)

WinDbg contains several meta-commands (starting with a dot) that allow you to control the debugger actions. The **.expr** command prints the expression evaluator (MASM or C++) that will be used when interpreting the symbols in the executed commands. You may use the **/s** to change it. The **?** command uses the default evaluator, and **??** always uses the C++ evaluator. Also, you can mix the evaluators in one expression by using **@@c++(expression)** or **@@masm(expression)** syntax, for example: **? @@c++(@$peb->ImageSubsystemMajorVersion) + @@masm(0y1)**.

When using **.if** and **.foreach**, sometimes the names are not resolved - use spaces between them. For example, the command would fail if there was no space between poi( and addr in the code below.

```shell
.foreach (addr {!DumpHeap -mt 71d75b24 -short}) { .if (dwo(poi( addr + 5c ) + c)) { !do addr } }
```

### Using the dx command

The **[dx command](https://learn.microsoft.com/en-us/windows-hardware/drivers/debuggercmds/dx--display-visualizer-variables-)** allows us to query the **Debugger Object Model**. There is a set of root objects from which we may start our query, including **@$cursession**, **@$curprocess**, **@$curthread**, **@$curstack**, or **@$curframe**.

**dx Debugger.State** shows the current state of the debugger. The **-h** parameter additionally displays help for the debugger objects, for example:

```shell
dx -h Debugger.State
# Debugger.State                 [State pertaining to the current execution of the debugger (e.g.: user variables)]
#     DebuggerInformation [Debugger variables which are owned by the debugger and can be referenced by a pseudo-register prefix of @$]
#     DebuggerVariables [Debugger variables which are owned by the debugger and can be referenced by a pseudo-register prefix of @$]
#     FunctionAliases  [Functions aliased to names which are accessible via a pseudo-register prefix of @$ or executable via a '!' command prefix]
#     PseudoRegisters  [Categorizied debugger managed pseudo-registers which can be referenced by a pseudo-register prefix of @$]
#     Scripts          [Scripts which have been loaded into the debugger and have properties, methods, or other accessible constructs]
#     UserVariables    [User variables which are maintained by the debugger and can be referenced by a pseudo-register prefix of @$]
#     ExtensionGallery [Extension Gallery]
```

If we add the **-v** parameter, dx will print not only the values of the properties and fields but also the methods we may call on an object:

```shell
dx -v -r1 Debugger.Sessions[0].Processes[15416].Threads[12796]
# Debugger.Sessions[0].Processes[15416].Threads[12796]                 [Switch To]
#     Id               : 0x31fc
#     Index            : 0x0
#     Stack           
#     Registers       
#     SwitchTo         [SwitchTo() - Switch to this thread as the default context]
#     Environment     
#     TTD             
#     ToDisplayString  [ToDisplayString([FormatSpecifier]) - Method which converts the object to its display string representation according to an optional format specifier]
```

#### Using variables and creating new objects in the dx query

In our queries we may create **anonymous objets**, **lambdas**, **arrays** and **objects of the Debugger Object Model types**, for example:

```shell
# Create an anonymous object for each call to RtlSetLastWin32Error that contains TTD time of the call and the error code value
dx -g @$cursession.TTD.Calls("ntdll!RtlSetLastWin32Error").Select(c => new { TimeStart = c.TimeStart, Error = c.Parameters[0] })
# =========================================
# =           = (+) TimeStart = Error     =
# =========================================
# = [0x0]     - 725:3B        - 0xbb      =
# = [0x1]     - 725:3D6       - 0x57      =
# = [0x2]     - 725:4AA       - 0x57      =
# = [0x3]     - 725:EF0       - 0xbb      =
# ....

# Create a simple array containing four numbers
dx Debugger.Utility.Collections.CreateArray(1, 2, 3, 4)
# Debugger.Utility.Collections.CreateArray(1, 2, 3, 4)                
#     [0x0]            : 1
#     [0x1]            : 2
#     [0x2]            : 3
#     [0x3]            : 4

# Create a TTD position object and use it to set the current trace position
dx -s @$create("Debugger.Models.TTD.Position", 4173, 75).SeekTo()

# Create a lambda function to sum two numbers
dx ((x, y) => x + y)(1, 2)
# ((x, y) => x + y)(1, 2) : 3
```

Additionally, we may assign the created object or the result of a dx query to a variable, for example:

```shell
# Assign a lambda function to a $sum variable and use it
dx @$sum = (x, y) => x + y
dx @$sum(1, 2)
# @$sum(1, 2)      : 3

# Save all calls to the CreateFileW function to the @$calls variable
dx @$calls = @$cursession.TTD.Calls("kernelbase!CreateFileW")
```

We may also use variables and pseudo-registers available in the debugger context. You may list them by examining the **Debugger.State.DebuggerVariables**, **Debugger.State.PseudoRegisters**, and **Debugger.State.UserVariables** objects.

#### Example queries with explanations

```shell
# Find kernel32 exports that contain the 'RegGetVal' string (by Tim Misiak)
dx @$curprocess.Modules["kernel32"].Contents.Exports.Where(exp => exp.Name.Contains("RegGetVal"))

# Show the address of the exported RegGetValueW function (by Tim Misiak)
dx -r1 @$curprocess.Modules["kernel32"].Contents.Exports.Single(exp => exp.Name == "RegGetValueW").CodeAddress

# Set a breakpoint on every exported function of the bindfltapi module
dx @$curprocess.Modules["bindfltapi"].Contents.Exports.Select(m =>  Debugger.Utility.Control.ExecuteCommand($"bp {m.CodeAddress}"))

# Show the number of calls made to functions with names starting from NdrClient in the rpcrt4 module
dx -g @$cursession.TTD.Calls("rpcrt4!NdrClient*").GroupBy(c => c.Function).Select(g => new { Function = g.First().Function, Count = g.Count() })
```

More examples of the dx queries for analysing the TTD traces can be found in the [TTD guide](/guides/using-ttd).

#### Managed application support in the dx queries

The SOS extension does not currently support the Debugger Object Models, but we can see that some of the debugger objects understand the managed context. For example, when we list **stack frames** of a managed process, the method names should be properly decoded:

```shell
dx -r1 @$curprocess.Threads[13236].Stack.Frames
# @$curprocess.Threads[13236].Stack.Frames                
#     [0x0]            : ntdll!NtReadFile + 0x14 [Switch To]
#     [0x1]            : KERNELBASE!ReadFile + 0x7b [Switch To]
#     [0x2]            : System_Console!Interop.Kernel32.ReadFile + 0x84 [Switch To]
#     [0x3]            : System_Console!System.ConsolePal.WindowsConsoleStream.ReadFileNative + 0x60 [Switch To]
#     [0x4]            : System_Console!System.ConsolePal.WindowsConsoleStream.Read + 0x2b [Switch To]
#     [0x5]            : System_Console!System.IO.ConsoleStream.Read + 0x74 [Switch To]
#     [0x6]            : System_Private_CoreLib!System.IO.StreamReader.ReadBuffer + 0x268 [Switch To]
#     [0x7]            : System_Private_CoreLib!System.IO.StreamReader.ReadLine + 0xd3 [Switch To]
#     [0x8]            : System_Console!System.IO.SyncTextReader.ReadLine + 0x3d [Switch To]
#     [0x9]            : System_Console!System.Console.ReadLine + 0x19 [Switch To]
#     [0xa]            : testcs!Program.Main + 0xc6 [Switch To]
#     ...

dx -r1 @$curprocess.Threads[13236].Stack.Frames[10]
# @$curprocess.Threads[13236].Stack.Frames[10]                 : testcs!Program.Main + 0xc6 [Switch To]
#     LocalVariables  
#     Parameters       : ()
#     Attributes      

dx -r1 @$curprocess.Threads[13236].Stack.Frames[10].LocalVariables
# @$curprocess.Threads[13236].Stack.Frames[10].LocalVariables                
#     ex               : 0x0 [Type: System.Exception]
#     slot0            [Type: System.Runtime.CompilerServices.DefaultInterpolatedStringHandler]
#     ...
```

Additionally, we may query **the managed heap** (**ManagedHeap** property is a nice replacement for the !DumpHeap command):

```shell
dx -r1 @$curprocess.Memory.ManagedHeap
# @$curprocess.Memory.ManagedHeap                
#     GCHandles       
#     Objects         
#     ObjectsByType

dx -r1 @$curprocess.Memory.ManagedHeap.Objects
# @$curprocess.Memory.ManagedHeap.Objects                
#     [0x0]            : 0x1ab6fc00020   size = 60   type = int[]
#     [0x1]            : 0x1ab6fc00080   size = 80   type = System.OutOfMemoryException
#     [0x2]            : 0x1ab6fc00100   size = 80   type = System.StackOverflowException
#     [0x3]            : 0x1ab6fc00180   size = 80   type = System.ExecutionEngineException
#     [0x4]            : 0x1ab6fc00200   size = 18   type = System.Object
#     [0x5]            : 0x1ab6fc00218   size = 18   type = System.String
#     [0x6]            : 0x1ab6fc00230   size = 50   type = System.Collections.Generic.Dictionary<string,object>
#     [0x7]            : 0x1ab6fc00280   size = 48   type = System.String
#     [...]           
```

### Using the JavaScript engine

Links:

- [Official Microsoft documentation](https://learn.microsoft.com/en-us/windows-hardware/drivers/debugger/javascript-debugger-scripting)
- [The API reference for the host object](https://learn.microsoft.com/en-us/windows-hardware/drivers/debugger/native-objects-in-javascript-extensions-debugger-objects)
- [Debugger data model, Javascript & x64 exception handling](https://doar-e.github.io/blog/2017/12/01/debugger-data-model) - a great article on scripting the debugger by Alex "0vercl0k" Souchet

#### Loading a script

The **.scriptproviders** command must include the JavaScript provider in the output.

Then we may run a script with the **.scriptrun** command or load it using the **.scriptload** command. The difference is that model modifications made by the **.scriptload** will stay in place until the call to **.scriptunload**. Also, **.scriptrun** will call the **invokeScript** JS function after the usual calls to the root code and the **initializeScript** function.

**.scriptlist** lists the loaded scripts.

#### Running a script

After loading a script file, we may find it in the **Debugger.State.Scripts** list (**.scriptlist** will show it, too):

```shell
.scriptload c:\windbg-js\windbg-scripting.js
# JavaScript script successfully loaded from 'c:\windbg-js\windbg-scripting.js'

dx -r1 Debugger.State.Scripts
# Debugger.State.Scripts
#     windbg-scripting
```

Then we are ready to call any defined public function, for example, logn:

```shell
dx Debugger.State.Scripts.@"windbg-scripting".Contents.logn("test")
# test

Debugger.State.Scripts.@"windbg-scripting".Contents.logn("test")
```

The **@$scriptContents** variable is a shortcut to all the public functions from all the loaded scripts, so our call could be more compact:

```shell
dx @$scriptContents.logn("test")
# test

@$scriptContents.logn("test")
```

#### Debugging a script

After we loaded the script (**.scriptload**), we may also debug its parts thanks to the **.scriptdebug** command, for example:

```shell
.scriptload c:\windbg-js\strings.js

.scriptdebug strings.js

# *** Inside JS debugger context ***
|
#     ...
#     [11] NatVis script from 'C:\Program Files\WindowsApps\Microsoft.WinDbg_1.2308.2002.0_x64__8wekyb3d8bbwe\amd64\Visualizers\winrt.natvis'
#     [12] [*DEBUGGED*] JavaScript script from 'c:\windbg-js\strings.js'
# 
bp logn
# Breakpoint 1 set at logn (11:5)
bl
#       Id State    Pos
#        1 enabled  11:5
# 
q
```

We are running a debugger in the debugger, so it could be a bit confusing :) After quitting the JavaScript debugger, it will keep the breakpoints information, so when we call our function from the main debugger, we will land in the JavaScript debugger again, for example:

```shell
dx @$scriptContents.logn("test")
# >>> ****** SCRIPT BREAK strings [Breakpoint 1] ******
#            Location: line = 11, column = 5
#            Text: log(s + "\n")
#
# *** Inside JS debugger context ***
dv
#                    s = test
```

The number of commands available in the inner JavaScript debugger is quite long and we may list them with the **.help** command. Especially, the evaluate expression (**?** or **??**) are very useful as they allow us to execute any JavaScript expressions and check their results:

```shell
? host
# host             : {...}
#     __proto__        : {...}
#     ...
#     Int64            : function () { [native code] }
#     parseInt64       : function () { [native code] }
#     namespace        : {...}
#     evaluateExpression : function () { [native code] }
#     evaluateExpressionInContext : function () { [native code] }
#     getModuleSymbol  : function () { [native code] }
#     getModuleContainingSymbol : function () { [native code] }
#     getModuleContainingSymbolInformation : function () { [native code] }
#     getModuleSymbolAddress : function () { [native code] }
#     setModuleSymbol  : function () { [native code] }
#     getModuleType    : function () { [native code] }
#     ...
```

### Launching commands from a script file

We can also execute commands from a script file. We use the **\$\$** command family for that purpose. The **-c** option allows us to run a command on a debugger launch. So if we pass the **\$\$\<** command with a file path, windbg will read the file and execute the commands from it as if they were entered manually, for example:

```shell
windbgx -c "$$<test.txt" notepad
```

And the test.txt content:

```shell
sxe -c ".echo advapi32; g" ld:advapi32
g
```

We may use the **$$\>args\<** command variant to pass arguments to our script.

When analyzing multiple files, I often use PowerShell to call WinDbg with the commands I want to run. In each WinDbg session, I pass the output of the commands to the windbg.log file, for example:

```shell
Get-ChildItem .\dumps | % { Start-Process -Wait -FilePath windbg-x64\windbg.exe -ArgumentList @("-loga", "windbg.log", "-y", "`"SRV*C:\dbg\symbols*https://msdl.microsoft.com/download/symbols`"", "-c", "`".exr -1; .ecxr; k; q`"", "-z", $_.FullName) }
```

To make a **comment**, you can use one of the comment commands: `$$ my comment` or `* my comment`. The difference between them is that **\*** comments everything till the end of the line, while **\$\$** comments text till the semicolon (or end of a line), e.g., `r eax; $$ some text; r ebx; * more text; r ecx` will print eax, ebx but not ecx. The **.echo** command ends if the debugger encounters a semicolon (unless the semicolon occurs within a quoted string).

Time Travel Debugging (TTD)
---------------------------

[TTD](https://learn.microsoft.com/en-us/windows-hardware/drivers/debugger/time-travel-debugging-overview) is a fantastic way to debug application code. After collecting a debug trace, we may query process memory, function calls, going deeper and deeper into the call stacks if necessary, and jump through various process lifetime events.

### Installation

The collector is installed with WinDbgX and we may enable it when starting a WinDbgX debugging session.

Alternatively, we could [install the command-line TTD collector](https://learn.microsoft.com/en-us/windows-hardware/drivers/debuggercmds/time-travel-debugging-ttd-exe-command-line-util#how-to-download-and-install-the-ttdexe-command-line-utility-preferred-method). The PowerShell script published on the linked site is capable of installing TTD even on systems not supporting the MSIX installations. The command-line tool is probably the best option when collecting TTD traces on server systems. When done, you may uninstall the driver by using the **-cleanup** option.

### Collection

If you have WinDbgX, you may use TTD by checking the "Record with Time Travel Debugging" checkbox when you start a new process or attach to a running one. When you stop the TTD trace in WinDbgX it will terminate the target process (TTD.exe, described later, can detach from a process without killing it).

An alternative to WinDbgX is running the command-line TTD collector. Some usage examples:

```shell
# launch a new winver.exe process and record the trace in C:\logs
ttd.exe -accepteula -out c:\logs winver.exe

# attach and trace the process with ID 1234 and all its newly started children
ttd.exe -accepteula -children -out c:\logs -attach 1234 

# attach and trace the process with ID 1234 to a ring buffer, backed by a trace file of maximum size 1024 MB
ttd.exe -accepteula -ring -maxFile 1024 -out c:\logs -attach 1234

# record a trace of the running and newly started processes, add a timestamp to the trace file names
ttd.exe -accepteula -timestampFilename -out c:\logs -monitor winver.exe
ttd.exe -accepteula -timestampFilename -out c:\logs -monitor app1.exe -monitor app2.exe
```

### Accessing TTD data

We can acess TTD objects by querying the TTD property of the session or process objects:

```shell
dx -v @$cursession.TTD
# @$cursession.TTD                
#     HeapLookup       [Returns a vector of heap blocks that contain the provided address: TTD.Utility.HeapLookup(address)]
#     Calls            [Returns call information from the trace for the specified set of methods: TTD.Calls("module!method1", "module!method2", ...) For example: dx @$cursession.TTD.Calls("user32!SendMessageA")]
#     Memory           [Returns memory access information for specified address range: TTD.Memory(startAddress, endAddress [, "rwec"])]
#     MemoryForPositionRange [Returns memory access information for specified address range and position range: TTD.MemoryForPositionRange(startAddress, endAddress [, "rwec"], minPosition, maxPosition)]
#     PinObjectPosition [Pins an object to the given time position: TTD.PinObjectPosition(obj, pos)]
#     AsyncQueryEnabled : false
#     Data             : Normalized data sources based on the contents of the time travel trace
#     Utility          : Methods that can be useful when analyzing time travel traces
#     ToDisplayString  [ToDisplayString([FormatSpecifier]) - Method which converts the object to its display string representation according to an optional format specifier]

dx -v @$curprocess.TTD
# @$curprocess.TTD                
#     Index           
#     Threads         
#     Events          
#     DebugOutput     
#     Lifetime         : [66:0, 118A2:0]
#     DefaultMemoryPolicy : GloballyAggressive
#     SetPosition      [Sets the debugger to point to the given position on this process.]
#     GatherMemoryUse  [0]
#     RecordClients  
```

### Querying debugging events

The **@$curprocess.Events** collection contains [TTD Event objects](https://learn.microsoft.com/en-us/windows-hardware/drivers/debuggercmds/time-travel-debugging-event-objects). We can use the group query to learn what type of events we have in our trace:

```shell
dx -g @$curprocess.TTD.Events.GroupBy(ev => ev.Type).Select(g => new { Type = g.First().Type, Count = g.Count() })
# ===========================================================
# =                         = (+) Type            = Count   =
# ===========================================================
# = ["ModuleLoaded"]        - ModuleLoaded        - 0x23    =
# = ["ThreadCreated"]       - ThreadCreated       - 0x9     =
# = ["ThreadTerminated"]    - ThreadTerminated    - 0x9     =
# = ["Exception"]           - Exception           - 0x4     =
# = ["ModuleUnloaded"]      - ModuleUnloaded      - 0x23    =
# ===========================================================
```

Next, we may filter the list for events that interest us, for example, to extract the first [TTD Exception object](https://learn.microsoft.com/en-us/windows-hardware/drivers/debuggercmds/time-travel-debugging-exception-objects), we may run the following query:

```shell
dx @$curprocess.TTD.Events.Where(ev => ev.Type == "Exception").Select(ev => ev.Exception).First()
# @$curprocess.TTD.Events.Where(ev => ev.Type == "Exception").Select(ev => ev.Exception).First()                 : Exception 0xE0434352 of type Software at PC: 0X7FF91E0842D0
#     Position         : 7E7C:0 [Time Travel]
#     Type             : Software
#     ProgramCounter   : 0x7ff91e0842d0
#     Code             : 0xe0434352
#     Flags            : 0x1
#     RecordAddress    : 0x0
# ...
```

### Examining function calls

The **Calls** method of the **TTD** objects allows us to query [function calls](https://learn.microsoft.com/en-us/windows-hardware/drivers/debuggercmds/time-travel-debugging-calls-objects) made in the trace. We may use either an address or a symbol name (even with wildcards) as a parameter to the Calls method:

```shell
x OLEAUT32!IDispatch_Invoke_Proxy
# 75a13bf0          OLEAUT32!IDispatch_Invoke_Proxy (void)

# we may use the address of a function
dx @$cursession.TTD.Calls(0x75a13bf0).Count()
# @$cursession.TTD.Calls(0x75a13bf0).Count() : 0x6a18

# or its symbolic name
dx @$cursession.TTD.Calls("OLEAUT32!IDispatch_Invoke_Proxy").Count()
# @$cursession.TTD.Calls("OLEAUT32!IDispatch_Invoke_Proxy").Count() : 0x6a18
```

Thanks to **wildcards**, we can easily get statistics on function calls from a given module or modules (this call might take some time for longer traces):

```shell
# Show the number of calls made to functions with names starting from NdrClient in the rpcrt4 module
dx -g @$cursession.TTD.Calls("rpcrt4!NdrClient*").GroupBy(c => c.Function).Select(g => new { Function = g.First().Function, Count = g.Count() })
# ==============================================================================
# =                                   = (+) Function                  = Count  =
# ==============================================================================
# = ["RPCRT4!NdrClientCall2"]         - RPCRT4!NdrClientCall2         - 0x5    =
# = ["RPCRT4!NdrClientInitialize"]    - RPCRT4!NdrClientInitialize    - 0x5    =
# = ["RPCRT4!NdrClientCall3"]         - RPCRT4!NdrClientCall3         - 0x8    =
# = ["RPCRT4!NdrClientZeroOut"]       - RPCRT4!NdrClientZeroOut       - 0x1    =
# ==============================================================================
```

**TimeStart** shows the position of a call in a trace and we may use it to jump between different places in the trace. **SystemTimeStart** shows the clock time of a given call:

```shell
dx -g @$cursession.TTD.Calls("user32!DialogBox*").Select(c => new { Function = c.Function, TimeStart = c.TimeStart, SystemTimeStart = c.SystemTimeStart })
# ==============================================================================================================
# =          = (+) Function                         = (+) TimeStart = (+) SystemTimeStart                      =
# ==============================================================================================================
# = [0x0]    - USER32!DialogBoxIndirectParamW       - 62E569:57     - Friday, February 2, 2024 16:03:39.391    =
# = [0x1]    - USER32!DialogBoxIndirectParamAorW    - 62E569:5C     - Friday, February 2, 2024 16:03:39.391    =
# = [0x2]    - USER32!DialogBox2                    - 631C23:102    - Friday, February 2, 2024 16:03:39.791    =
```

Each function call has a **Parameters** property that gives us access to the function parameters (without private symbols, we can access the first four parameters) of a call:

```shell
# Check which LastErrors were set during the call
dx -h @$cursession.TTD.Calls("ntdll!RtlSetLastWin32Error").Select(c => c.Parameters[0]).Distinct()
# @$cursession.TTD.Calls("ntdll!RtlSetLastWin32Error").Select(c => c.Parameters[0]).Distinct()                
#     [0x0]            : 0xbb
#     [0x1]            : 0x57
#     [0x2]            : 0x0
#     [0x3]            : 0x7e
#     [0x4]            : 0x3f0

# Find LastError calls when LastError is not zero
dx -g @$cursession.TTD.Calls("ntdll!RtlSetLastWin32Error").Where(c => c.Parameters[0] != 0).Select(c => new { TimeStart = c.TimeStart, Error = c.Parameters[0] })
# =========================================
# =           = (+) TimeStart = Error     =
# =========================================
# = [0x0]     - 725:3B        - 0xbb      =
# = [0x1]     - 725:3D6       - 0x57      =
# = [0x2]     - 725:4AA       - 0x57      =
# = [0x3]     - 725:EF0       - 0xbb      =
# ....
```

### Position in TTD trace

The **[TTD Position object](https://learn.microsoft.com/en-us/windows-hardware/drivers/debuggercmds/time-travel-debugging-position-objects)** describes a moment in time in the trace. Its **SeekTo** method allows us to jump to this moment and analyze the process state:

```shell
dx -r1 @$create("Debugger.Models.TTD.Position", 34395, 1278)
# @$create("Debugger.Models.TTD.Position", 34395, 1278)                 : 865B:4FE [Time Travel]
#     Sequence         : 0x865b
#     Steps            : 0x4fe
#     SeekTo           [Method which seeks to time position]
#     ToSystemTime     [Method which obtains the approximate system time at a given position]

dx -s @$create("Debugger.Models.TTD.Position", 34395, 1278).SeekTo()
# (1d30.1b94): Break instruction exception - code 80000003 (first/second chance not available)
# Time Travel Position: 865B:4FE
```

If we are troubleshooting an issue spanning multiple processes, we may simultaneously record TTD traces for all of them, and later, use the TTD Position objects to set the same moment in time in all the traces. It is a very effective technique when debugging locking issues.

### Examining memory access

The **Memory** and **MemoryForPositionRange** methods of the TTD Session object return [TTD Memory objects](https://learn.microsoft.com/en-us/windows-hardware/drivers/debuggercmds/time-travel-debugging-memory-objects) describing various operations on the memory. For example, the command below shows all the changes to the global GcInProgress variable in a .NET application:

```shell
dx -g @$cursession.TTD.Memory(&coreclr!g_pGCHeap->GcInProgress, &coreclr!g_pGCHeap->GcInProgress+4, "w")
# ==============================================================================================================================================================================================================================================================================================================
# =          = (+) EventType = (+) ThreadId = (+) UniqueThreadId = (+) TimeStart = (+) TimeEnd = (+) AccessType = (+) IP            = (+) Address       = (+) Size = (+) Value        = (+) OverwrittenValue = (+) SystemTimeStart                            = (+) SystemTimeEnd                              =
# ==============================================================================================================================================================================================================================================================================================================
# = [0x0]    - 0x1           - 0x2c80       - 0x2                - C79:58C       - C79:58C     - Write          - 0x7ff8fdbce0ee    - 0x7ff8fe00caf0    - 0x8      - 0x2b4800c9bc0    - 0x0                  - poniedziałek, 15 kwietnia 2024 10:14:18.475    - poniedziałek, 15 kwietnia 2024 10:14:18.475    =
# = [0x1]    - 0x1           - 0x2c80       - 0x2                - 3AF4:5A       - 3AF4:5A     - Write          - 0x7ff8fdcdacc3    - 0x7ff8fe00cae8    - 0x4      - 0x1              - 0x0                  - poniedziałek, 15 kwietnia 2024 10:14:20.896    - poniedziałek, 15 kwietnia 2024 10:14:20.896    =
# = [0x2]    - 0x1           - 0x2c80       - 0x2                - 3B26:E6C      - 3B26:E6C    - Write          - 0x7ff8fdcdacc3    - 0x7ff8fe00cae8    - 0x4      - 0x0              - 0x1                  - poniedziałek, 15 kwietnia 2024 10:14:20.910    - poniedziałek, 15 kwietnia 2024 10:14:20.910    =
# = [0x3]    - 0x1           - 0x2c80       - 0x2                - 87DF:5A       - 87DF:5A     - Write          - 0x7ff8fdcdacc3    - 0x7ff8fe00cae8    - 0x4      - 0x1              - 0x0                  - poniedziałek, 15 kwietnia 2024 10:14:24.539    - poniedziałek, 15 kwietnia 2024 10:14:24.539    =
# = [0x4]    - 0x1           - 0x2c80       - 0x2                - 880C:50C      - 880C:50C    - Write          - 0x7ff8fdcdacc3    - 0x7ff8fe00cae8    - 0x4      - 0x0              - 0x1                  - poniedziałek, 15 kwietnia 2024 10:14:24.548    - poniedziałek, 15 kwietnia 2024 10:14:24.548    =
# = [0x5]    - 0x1           - 0x2c80       - 0x2                - 889F:5A       - 889F:5A     - Write          - 0x7ff8fdcdacc3    - 0x7ff8fe00cae8    - 0x4      - 0x1              - 0x0                  - poniedziałek, 15 kwietnia 2024 10:14:25.769    - poniedziałek, 15 kwietnia 2024 10:14:25.769    =
# ==============================================================================================================================================================================================================================================================================================================
```

The **MemoryForPositionRange** method allows us to additionally limit memory access queries to a specific time-range. It makes sense to use this method for scope-based addresses, such as function parameters or local variables. Below, you may see an example of a query when we list all the places in the CreateFileW function that read the file name (the first argument to the function):

```shell
dx -s @$call = @$cursession.TTD.Calls("kernelbase!CreateFileW").First()
dx -g @$cursession.TTD.MemoryForPositionRange(@$call.Parameters[0], @$call.Parameters[0] + sizeof(wchar_t), "r", @$call.TimeStart, @$call.TimeEnd)
# ======================================================================================================================================================
# =          = (+) Position = ThreadId  = UniqueThreadId = Address          = IP                = Size   = AccessType = Value               = (+) Data =
# ======================================================================================================================================================
# = [0x0]    - AB:1981      - 0x2018    - 0x2            - 0x236011c33c0    - 0x7ff91e04a836    - 0x2    - Read       - 0x55005c003a0043    - {...}    =
# = [0x1]    - AB:1AD4      - 0x2018    - 0x2            - 0x236011c33c0    - 0x7ff91e04b6e1    - 0x2    - Read       - 0x55005c003a0043    - {...}    =
# = [0x2]    - AB:1C27      - 0x2018    - 0x2            - 0x236011c33c0    - 0x7ff91e04b796    - 0x2    - Read       - 0x55005c003a0043    - {...}    =
# = [0x3]    - AB:1C5E      - 0x2018    - 0x2            - 0x236011c33c0    - 0x7ff91e04bca9    - 0x2    - Read       - 0x55005c003a0043    - {...}    =
# = [0x4]    - AB:1CC8      - 0x2018    - 0x2            - 0x236011c33c0    - 0x7ff91e04caa8    - 0x2    - Read       - 0x55005c003a0043    - {...}    =
# = [0x5]    - AB:1CCA      - 0x2018    - 0x2            - 0x236011c33c0    - 0x7ff91e04caae    - 0x2    - Read       - 0x55005c003a0043    - {...}    =
# = [0x6]    - AB:1CCF      - 0x2018    - 0x2            - 0x236011c33c0    - 0x7ff91e04cabe    - 0x2    - Read       - 0x55005c003a0043    - {...}    =
# = [0x7]    - AB:1E23      - 0x2018    - 0x2            - 0x236011c33c0    - 0x7ff91e04bd5a    - 0x2    - Read       - 0x55005c003a0043    - {...}    =
# = [0x8]    - AB:1E2A      - 0x2018    - 0x2            - 0x236011c33c0    - 0x7ff91e04bd7b    - 0x2    - Read       - 0x55005c003a0043    - {...}    =
# = [0x9]    - AB:1E5C      - 0x2018    - 0x2            - 0x236011c33c0    - 0x7ff91e04be56    - 0x2    - Read       - 0x55005c003a0043    - {...}    =
# = [0xa]    - AB:1E68      - 0x2018    - 0x2            - 0x236011c33c0    - 0x7ff91e04be7a    - 0x2    - Read       - 0x55005c003a0043    - {...}    =
# ======================================================================================================================================================
```

Misc tips
---------

### Converting a memory dump from one format to another

When debugging a full memory dump (**/ma**), we may convert it to a smaller memory dump using again the **.dump** command, for example:

```shell
.dump /mpi c:\tmp\smaller.dmp
```

### Loading an arbitrary DLL into WinDbg for analysis

WinDbg allows analysis of an arbitrary PE file if we load it as a crash dump (the **Open dump file** menu option or the **-z** command-line argument), for example: `windbgx -z C:\Windows\System32\shell32.dll`. WinDbg will load a DLL/EXE as a data file.

Alternatively, if we want to normally load the DLL, we may use **rundll32.exe** as our debugging target and wait until the DLL gets loaded, for example: `windbgx -c "sxe ld:jscript9.dll;g" rundll32.exe .\jscript9.dll,TestFunction`. The TestFunction in the snippet could be any string. Rundll32.exe loads the DLL before validating the exported function address.

### Keyboard and mouse shortcuts

The **SHIFT + \[UP ARROW\]** completes the current command from previously executed commands (much as F8 in cmd).

If you double-click on a word in the command window in WinDbgX, the debugger will **highlight** all occurrences of the selected term. You may highlight other words with different colors if you press the ctrl key when double-clicking on them. To unhighlight a given word, double-click on it again, pressing the ctrl key.

### Running a command for all the processes

```shell
dx -r2 @$cursession.Processes.Where(p => p.Name == "test.exe").Select(p => Debugger.Utility.Control.ExecuteCommand("|~[0n" + p.Id + "]s;bp testlib!TestMethod \".lastevent; r @rdx; u poi(@rdx); g\""))
```

### Attaching to multiple processes at once

In PowerShell:

```shell
Get-Process -Name disp+work | where Id -ne 6612 | % { ".attach -b 0n$($_.Id)" } | Out-File -Encoding ascii c:\tmp\attach_all.txt
windbgx.exe -c "`$`$<C:\tmp\attach_all.txt" -pn winver.exe
```

### Injecting a DLL into a process being debugged

You may use the **!injectdll** command from my [lldext](https://github.com/lowleveldesign/lldext) extension.

Or use the **.call** method, as shown in the shell32.dll example below. We start by allocating some space for the DLL name and filling it up:

```shell
.dvalloc 0x1a
# Allocated 1000 bytes starting at 00000279`c1be0000

ezu 00000279`c1be0000 "shell32.dll"

du 00000279`c1be0000
# 00000279`c1be0000  "shell32.dll"
```

The .call command requires private symbols. Microsoft does not publish public symbols for KernelBase!LoadLibraryW, but we may create them (thanks to the [SymbolBuilderComposition extension](https://github.com/microsoft/WinDbg-Samples/tree/master/TargetComposition/SymBuilder)):

```shell
? kernelbase!LoadLibraryW - kernelbase
# Evaluate expression: 533568 = 00000000`00082440

.load c:\dbg64ex\SymbolBuilderComposition.dll

dx @$sym = Debugger.Utility.SymbolBuilder.CreateSymbols("kernelbase.dll")

dx @$fnLoadLibraryW = @$sym.Functions.Create("LoadLibraryW", "void*", 0x0000000000082440, 0x8)
dx @$param =  @$fnLoadLibraryW.Parameters.Add("lpLibFileName", "wchar_t*")
dx @$param.LiveRanges.Add(0, 8, "@rcx")

.reload /f kernelbase.dll

.call kernelbase!LoadLibraryW(0x00000279`c1be0000)

~.g

lm
# start             end                 module name
# ...
# 00007ff9`b3390000 00007ff9`b3be9000   SHELL32    (deferred)
# ...
```

{% endraw %}
