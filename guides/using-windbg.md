---
layout: page
title: Using WinDbg
---

WIP

**Table of contents:**

<!-- MarkdownTOC -->

- [Installing WinDbg](#installing-windbg)
    - [WinDbgX \(WinDbgNext, formely WinDbg Preview\)](#windbgx-windbgnext-formely-windbg-preview)
    - [Classic WinDbg](#classic-windbg)
- [Configuring a debugging session](#configuring-a-debugging-session)
    - [Setup Windows Kernel Debugging over network](#setup-windows-kernel-debugging-over-network)
    - [Setup Kernel debugging in QEMU/KVM](#setup-kernel-debugging-in-qemukvm)
    - [Remote debugging](#remote-debugging)
    - [Installing WinDbg as the Windows AE debugger](#installing-windbg-as-the-windows-ae-debugger)
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
    - [Break when a specific function is in the call stack](#break-when-a-specific-function-is-in-the-call-stack)
    - [Break on a specific function enter and leave](#break-on-a-specific-function-enter-and-leave)
    - [Break for all methods in the C++ object virtual table](#break-for-all-methods-in-the-c-object-virtual-table)
    - [Break when user-mode process is created \(kernel-mode\)](#break-when-user-mode-process-is-created-kernel-mode)
    - [Set a user-mode breakpoint in kernel-mode](#set-a-user-mode-breakpoint-in-kernel-mode)
- [Scripting the debugger](#scripting-the-debugger)
    - [The dx command](#the-dx-command)
    - [Javascript engine](#javascript-engine)
    - [Run a command for all the processes](#run-a-command-for-all-the-processes)
    - [Attach to multiple processes at once](#attach-to-multiple-processes-at-once)
    - [Inject a DLL into a process being debugged](#inject-a-dll-into-a-process-being-debugged)
- [Time Travel Debugging \(TTD\)](#time-travel-debugging-ttd)
- [Misc tips](#misc-tips)
    - [Convert memory dump from one format to another](#convert-memory-dump-from-one-format-to-another)
    - [Loading arbitrary DLL into WinDbg for analysis](#loading-arbitrary-dll-into-windbg-for-analysis)
    - [Keyboard and mouse shortcuts](#keyboard-and-mouse-shortcuts)
    - [Check registry keys inside debugger](#check-registry-keys-inside-debugger)

<!-- /MarkdownTOC -->

## Installing WinDbg

### WinDbgX (WinDbgNext, formely WinDbg Preview)

On modern systems **download the [appinstaller](https://learn.microsoft.com/en-us/windows-hardware/drivers/debugger/)** file and choose **Install** in the context menu.

If you are on Windows Server 2019 and you don't see the Install option in the context menu, there is a big chance you're missing the App Installer package on your system. In that case, you may use [a PowerShell script provided by @Izybkr](https://github.com/microsoftfeedback/WinDbg-Feedback/issues/19#issuecomment-1513926394).

### Classic WinDbg

If you need to debug on an old system with no support for WinDbgX, you need to **download Windows SDK and install the Debugging Tools for Windows** feature. The executables will be in the Debuggers folder, for example, `c:\Program Files (x86)\Windows Kits\10\Debuggers`.

## Configuring a debugging session

### Setup Windows Kernel Debugging over network

*HYPER-V note*: When debugging a Gen 2 VM remember to turn off the secure booting:
**Set-VMFirmware -VMName "Windows 2012 R2" -EnableSecureBoot Off -Confirm**

Turn on network deubugging (HOSTIP is the address of the machine on which we will run the debugger):

C:\Windows\system32>**bcdedit /dbgsettings NET HOSTIP:192.168.0.2 PORT:60000**
Key=3ma3qyz02ptls.23uxbvnd0e2zh.1gnwiqb6v3mpb.mjltos9cf63x

C:\Windows\system32>**bcdedit /debug {current} on**
The operation completed successfully.

Then on the host machine, run windbg, select **Attach to kernel** and fill the port and key textboxes.

**Network card compatibility check**

Starting from Debugging Tools for Windows 10 we have an additional tool: **kdnet.exe**. By running it on the guest you may see if your network card supports kernel debugging and get the instructions for the host machine:

```
C:\tools\x64>kdnet 172.25.121.1 60000

Enabling network debugging on Microsoft Hypervisor Virtual Machine.
Key=1a88vu15z4lta.8q4ler06jr8v.1fv4h88r9e0ob.1139s57nv8obj

To finish setting up KDNET for this VM, run the following command from an
elevated command prompt running on the Windows hyper-v host.  (NOT this VM!)
powershell -ExecutionPolicy Bypass kdnetdebugvm.ps1 -vmguid DD4F4AFE-9B5F-49AD-8
775-20863740C942 -port 60000

To debug this vm, run the following command on your debugger host machine.
windbg -k net:port=60000,key=1a88vu15z4lta.8q4ler06jr8v.1fv4h88r9e0ob.1139s57nv8
obj,target=DELAPTOP

Then make sure to SHUTDOWN (not restart) the VM so that the new settings will
take effect.  Run shutdown -s -t 0 from this command prompt.
```

### Setup Kernel debugging in QEMU/KVM

The tutorial at <https://resources.infosecinstitute.com/topic/kernel-debugging-qemu-windbg/> helped me a lot to achieve this.

The main idea is to use the Unix pipe. One side (debugger host) must have the serial port in the bind mode and the other side (client) in a connect mode. Example configuration in QEMU:

```xml
<serial type="unix">
  <source mode="bind" path="/tmp/dbgpipe"/>
  <target type="isa-serial" port="1">
    <model name="isa-serial"/>
  </target>
  <alias name="serial1"/>
</serial>
```

```xml
<serial type="unix">
  <source mode="connect" path="/tmp/dbgpipe"/>
  <target type="isa-serial" port="1">
    <model name="isa-serial"/>
  </target>
  <alias name="serial1"/>
</serial>
```

*NOTE: by default the mode is set to bind, otherwise, the VM  won't start without something listening on this pipe. Therefore, when you're done with debugging, set the mode back to bind or remove the serial port.*

The serial1 on virtualized Windows appears as the COM2 port.

```
bcdedit /debug {current} on
bcdedit /dbgsettings SERIAL DEBUGPORT:2 BAUDRATE:115200
```

### Remote debugging

To start a remote session of WinDbg, you may use the **-server** switch, e.g.: **windbg(x) -server "npipe:pipe=svcpipe" notepad**.

You may attach to the currently running session by using **-remote** switch, e.g.: **windbg(x) -remote "npipe:pipe=svcpipe,server=localhost"**

To terminate the entire session and exit the debugging server, use the **q (Quit)** command. To exit from one debugging client without terminating the server, you must issue a command from that specific client. If this client is KD or CDB, use the **CTRL+B** key to exit. If you are using a script to run KD or CDB, use **.remote_exit (Exit Debugging Client)**.

### Installing WinDbg as the Windows AE debugger

The **windbx -I** (**windbg -iae**) command registers WinDbg as the automatic system debugger - it will launch anytime an application crashes. The modified AeDebug registry keys:

```
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AeDebug
HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows NT\CurrentVersion\AeDebug
```

However, we may also use configure those keys manually and use WinDbg to, for example, create a memory dump at an application crash:

```
REG_SZ Debugger = "C:\Users\me\AppData\Local\Microsoft\WindowsApps\WinDbgX.exe" -c ".dump /ma /u C:\dumps\crash.dmp; qd" -p %ld -e %ld -g
REG_SZ Auto = 1
```

If you miss the **-g** option, WinDbg will inject a remote thread with a breakpoint instruction, which will hide our original exception. In such case, you might need to [scan the stack to find the original exception record](../exceptions/exceptions.md#scanning-the-stack-for-native-exception-records)).

## Getting information about the debugging session

The **|** command displays a path to the process image. You may run **vercommand** to check how the debugger was launched. The **vertarget** command shows the OS version, the process lifetime, and more, for example, the dump time when debugging a memory dump. The **.time** command displays information about the system time variable (session time).

**.lastevent** shows the last reason why the debugger stopped and **.eventlog** displays the recent events.

## Symbols and modules

The **lm** command lists all modules with symbol load info. To examine a specific module, use **lmvm {module-name}**. To find out if a given address belongs to any of the loaded dlls you may use the **!dlls -c {addr}** command. Another way would be to use the **lma {addr}** command.

The **.sympath** command shows the symbol search path and allows its modification. Use **.reload /f {module-name}** to reload symbols for a given module.

The **x {module-name}!{function}** command resolves a function address, and **ln {address}** finds the nearest symbol.

When we don't have access to the symbol server, we may create a list of required symbols with **symchk.exe** (part of the Debugging Tools for Windows installation) and download them later on a different host. First, we need to prepare the manifest, for example:

```
symchk /id test.dmp /om test.dmp.sym /s C:\non-existing
```

Then copy it to the machine with the symbol server access, and download the required symbols, for example:

```
symchk /im test.dmp.sym /s SRV*C:\symbols*https://msdl.microsoft.com/download/symbols
```

## Working with memory

### General memory commands

The `!address` command shows information about a specific region of memory, for example:

```
0:000> !address 0x00fd7df8

Usage:                  Image
Base Address:           00fd6000
End Address:            00fdc000
Region Size:            00006000 (  24.000 kB)
State:                  00001000          MEM_COMMIT
Protect:                00000002          PAGE_READONLY
Type:                   01000000          MEM_IMAGE
Allocation Base:        00fb0000
Allocation Protect:     00000080          PAGE_EXECUTE_WRITECOPY
Image Path:             prog.exe
Module Name:            prog
Loaded Image Name:      c:\test\prog.exe
Mapped Image Name:
More info:              lmv m prog
More info:              !lmi prog
More info:              ln 0xfd7df8
More info:              !dh 0xfb0000
```

Additionally, it can display regions of memory of specific type, for example:

```
0:000> !address -f:FileMap

  BaseAddr EndAddr+1 RgnSize     Type       State                 Protect             Usage
-----------------------------------------------------------------------------------------------
  9a0000   9b0000    10000 MEM_MAPPED  MEM_COMMIT  PAGE_READWRITE                     MappedFile "PageFile"
  9b0000   9b1000     1000 MEM_MAPPED  MEM_COMMIT  PAGE_READONLY                      MappedFile "PageFile"
  9c0000   9c1000     1000 MEM_MAPPED  MEM_COMMIT  PAGE_READONLY                      MappedFile "PageFile"
  d50000   e19000    c9000 MEM_MAPPED  MEM_COMMIT  PAGE_READONLY                      MappedFile "\Device\HarddiskVolume3\Windows\System32\locale.nls"
  ff0000   ff1000     1000 MEM_MAPPED  MEM_COMMIT  PAGE_READONLY                      MappedFile "PageFile"
7f995000 7fa90000    fb000 MEM_MAPPED  MEM_RESERVE                                    MappedFile "PageFile"
7fae0000 7fae1000     1000 MEM_MAPPED  MEM_COMMIT  PAGE_READONLY                      MappedFile "PageFile"

0:000> !address -f:MEM_MAPPED

  BaseAddr EndAddr+1 RgnSize     Type       State                 Protect             Usage
-----------------------------------------------------------------------------------------------
  9a0000   9b0000    10000 MEM_MAPPED  MEM_COMMIT  PAGE_READWRITE                     MappedFile "PageFile"
  9b0000   9b1000     1000 MEM_MAPPED  MEM_COMMIT  PAGE_READONLY                      MappedFile "PageFile"
  9c0000   9c1000     1000 MEM_MAPPED  MEM_COMMIT  PAGE_READONLY                      MappedFile "PageFile"
  9d0000   9ed000    1d000 MEM_MAPPED  MEM_COMMIT  PAGE_READONLY                      Other      [API Set Map]
  9f0000   9f4000     4000 MEM_MAPPED  MEM_COMMIT  PAGE_READONLY                      Other      [System Default Activation Context Data]
  d50000   e19000    c9000 MEM_MAPPED  MEM_COMMIT  PAGE_READONLY                      MappedFile "\Device\HarddiskVolume3\Windows\System32\locale.nls"
  ff0000   ff1000     1000 MEM_MAPPED  MEM_COMMIT  PAGE_READONLY                      MappedFile "PageFile"
7f990000 7f995000     5000 MEM_MAPPED  MEM_COMMIT  PAGE_READONLY                      Other      [Read Only Shared Memory]
7f995000 7fa90000    fb000 MEM_MAPPED  MEM_RESERVE                                    MappedFile "PageFile"
7fae0000 7fae1000     1000 MEM_MAPPED  MEM_COMMIT  PAGE_READONLY                      MappedFile "PageFile"
7faf0000 7fb13000    23000 MEM_MAPPED  MEM_COMMIT  PAGE_READONLY                      Other      [NLS Tables]
```

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

The **!for_each_frame** extension command enables you to execute a single command repeatedly, once for each frame in the stack.

Reading stack in Windbg

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

### Variables

When you have private symbols you may list local variables with the **dv** command.

Additionally the **dt** command allows you to work with type symbols. You may either list them, eg.: `dt notepad!g_*` or dump a data address using a given type format, eg.: `dt nt!_PEG 0x13123`.

With windbg 10.0 a new very interesting command was introduced: **dx**. It uses a navigation expressions just like Visual Studio (you may define your own file .natvis files). You load the interesting .natvis file with the **.nvload** command.

**#FIELD_OFFSET(Type, Field)** is an interesting operator which returns the offset of the field in the type, eg. **? \#FIELD_OFFSET(\_PEB, ImageSubsystemMajorVersion)**.

### Working with strings

The **!du** command from the PDE extension shows strings up to 4GB (the default du command stops when it hits the range limit).

The PDE extension also contains the **!ssz** command to look for zero-terminated (either unicode or ascii) strings. To change a text in memory use **!ezu**, for example: `ezu  "test string"`. The extension works on committed memory.

Another interesting command is **!grep**, which allows you to filter the output of other commands: `!grep _NT !peb`.

## System objects in the debugger

The **!object** command displays some basic information about a kernel object:

```
0: kd> !object  ffffc30162f26080
Object: ffffc30162f26080  Type: (ffffc30161891d20) Process
    ObjectHeader: ffffc30162f26050 (new version)
    HandleCount: 23  PointerCount: 582900
```

We may then analyze the object header to learn some more details about the object, for example:

```
0: kd> dx (nt!_OBJECT_HEADER *)0xffffc30162f26050
(nt!_OBJECT_HEADER *)0xffffc30162f26050                 : 0xffffc30162f26050 [Type: _OBJECT_HEADER *]
    [+0x000] PointerCount     : 582900 [Type: __int64]
    [+0x008] HandleCount      : 23 [Type: __int64]
    [+0x008] NextToFree       : 0x17 [Type: void *]
    [+0x010] Lock             [Type: _EX_PUSH_LOCK]
    [+0x018] TypeIndex        : 0x5 [Type: unsigned char]
    [+0x019] TraceFlags       : 0x0 [Type: unsigned char]
    [+0x019 ( 0: 0)] DbgRefTrace      : 0x0 [Type: unsigned char]
    [+0x019 ( 1: 1)] DbgTracePermanent : 0x0 [Type: unsigned char]
    [+0x01a] InfoMask         : 0x88 [Type: unsigned char]
    [+0x01b] Flags            : 0x0 [Type: unsigned char]
    [+0x01b ( 0: 0)] NewObject        : 0x0 [Type: unsigned char]
    [+0x01b ( 1: 1)] KernelObject     : 0x0 [Type: unsigned char]
    [+0x01b ( 2: 2)] KernelOnlyAccess : 0x0 [Type: unsigned char]
    [+0x01b ( 3: 3)] ExclusiveObject  : 0x0 [Type: unsigned char]
    [+0x01b ( 4: 4)] PermanentObject  : 0x0 [Type: unsigned char]
    [+0x01b ( 5: 5)] DefaultSecurityQuota : 0x0 [Type: unsigned char]
    [+0x01b ( 6: 6)] SingleHandleEntry : 0x0 [Type: unsigned char]
    [+0x01b ( 7: 7)] DeletedInline    : 0x0 [Type: unsigned char]
    [+0x01c] Reserved         : 0x62005c [Type: unsigned long]
    [+0x020] ObjectCreateInfo : 0xffffc301671872c0 [Type: _OBJECT_CREATE_INFORMATION *]
    [+0x020] QuotaBlockCharged : 0xffffc301671872c0 [Type: void *]
    [+0x028] SecurityDescriptor : 0xffffd689feeef0ea [Type: void *]
    [+0x030] Body             [Type: _QUAD]
    ObjectType       : Process
    UnderlyingObject [Type: _EPROCESS]

0: kd> dx -r1 (*((ntkrnlmp!_EPROCESS *)0xffffc30162f26080))
(*((ntkrnlmp!_EPROCESS *)0xffffc30162f26080))                 [Type: _EPROCESS]
    [+0x000] Pcb              [Type: _KPROCESS]
    [+0x438] ProcessLock      [Type: _EX_PUSH_LOCK]
    [+0x440] UniqueProcessId  : 0x1488 [Type: void *]
    [+0x448] ActiveProcessLinks [Type: _LIST_ENTRY]
    [+0x458] RundownProtect   [Type: _EX_RUNDOWN_REF]
    [+0x460] Flags2           : 0x200d014 [Type: unsigned long]
    [+0x460 ( 0: 0)] JobNotReallyActive : 0x0 [Type: unsigned long]
    [+0x460 ( 1: 1)] AccountingFolded : 0x0 [Type: unsigned long]
    [+0x460 ( 2: 2)] NewProcessReported : 0x1 [Type: unsigned long]
    ...
```

### Processes (kernel-mode)

Each time you break into the kernel-mode debugger one of the processes will be active. You may check which one is it by running **!process -1 0** command. If you are going to work with user-mode memory space you need to reload the process modules symbols (otherwise you will see symbols from the last reload). You may do so while switching process context with **.process /i** or **.process /r /p** or manually with the command: **.reload /user**.  The first two command allow you to select which process's page directory is used to interpret virtual addresses. After you set the process context, you can use this context in any command that takes addresses.

**.process [/i] [/p [/r] ] [/P] [Process]**

**/i** means invasive debugging and allows you to control the process from the kernel debugger. **/r** reloads user-mode symbols after the process context has been set (the behavior is the same as **.reload /user**). **/p** translates all transition page table entries (PTEs) for this process to physical addresses before access.

**!peb** shows loaded modules, environment variables, command line arg, and more.

The **!process 0 0 {image}** command finds a proces using its image name, np.: `!process 0 0 LINQPad.UserQuery.exe`.

When we know the process ID, we may use **!process {PID | address} 0x7** (the 0x7 flag will list all the threads with their stacks)

### Handles

There is a special debugger extension command **!handle** that allows you to find system handles reserved by a process: **!handle [Handle [UMFlags [TypeName]]]**

To list all handles reserved by a process use -1 (in kernel mode) or 0 (in user-mode) - you filter further by seeting a type of a handle: Event, Section, File, Port, Directory, SymbolicLink, Mutant, WindowStation, Semaphore, Key, Token, Process, Thread, Desktop, IoCompletion, Timer, Job, and WaitablePort, ex.:

```
0:000> !handle 0 1 File
...
Handle 1c0
  Type          File
7 handles of type File
```

### Threads

The **!thread {addr}** command shows details about a specific thread.

Each thread has its own register values. These values are stored in the CPU registers when the thread is executing and are stored in memory when another thread is executing. You can set the register context using .thread command:

**.thread [/p [/r] ] [/P] [/w] [Thread]**

or

**.trap [Address]**
**.cxr [Options] [Address]**

For WOW64 processes, the **\w** parameter (**.thread \w**) will additionally switch to the x86 context. After loading the thread context, the commands opearating on stack should start working (remember to be in the right process context).

**To list all threads** in a current process use **~** command (user-mode). Dot (.) in the first column signals a currently selected thread and hash (#) points to a thread on which an exception occurred.

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

**\~\~\[thread-id\]** - in case you would like to use the system thread id you may with this syntax.

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

## Controlling process execution

### Controlling the target (g, t, p)

To go up the funtion use **gu** command. We can go to a specified address using **ga [address]**. We can also step or trace to a specified address using accordingly **pa** and **ta** commands.

Useful commands are **pc** and **tc** which step or trace to **the next call statement**. **pt** and **tt** step or trace to **the next return statement**.

### Watch trace

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

If the **wt** command does not work, you may achieve similar results manually with the help of the target controlling commands:

- stepping until a specified address: **ta**, **pa**
- stepping until the next branching instruction: **th**, **ph**
- stepping until the next call instruction: **tc**, **pc**
- stepping until the next return: **tt**, **pt**
- stepping until the next return or call instruction: **tct**, **pct**


### Break when a specific function is in the call stack

```
bp Module!MyFunctionWithConditionalBreakpoint "r $t0 = 0;.foreach (v { k }) { .if ($spat(\"v\", \"*Module!ClassA:MemberFunction*\")) { r $t0 = 1;.break } }; .if($t0 = 0) { gc }"
```

### Break on a specific function enter and leave

The trick is to set a one-time breakpoint on the return address (**bp /1 @$ra**) when the main breakpoint is hit, for example:

```
bp 031a6160 "dt ntdll!_GUID poi(@esp + 8); .printf /D \"==> obj addr: %p\", poi(@esp + C);.echo; bp /1 @$ra; g"
bp kernel32!RegOpenKeyExW "du @rdx; bp /1 @$ra \"r @$retreg; g\"; g"
```

```
bp kernelbase!CreateFileW ".printf \"CreateFileW('%mu', ...)\", @rcx; bp /1 @$ra \".printf \\\" => %p\\\\n\\\", @rax; g\"; g"
bp kernelbase!DeviceIoControl ".printf \"DeviceIoControl(%p, %p, ...)\\n\", @rcx, @rdx; g"
bp kernelbase!CloseHandle ".printf \"CloseHandle(%p)\\n\", @rcx;g"
```

Remove the 'g' commands from the above samples if you want the debugger to stop.

### Break for all methods in the C++ object virtual table

This could be useful when debugging COM interfaces, as in the example below. When we know the number of methods in the interface and the address of the virtual table, we may set the breakpoint using the .for loop, for example:

```
.for (r $t0 = 0; @$t0 < 5; r $t0= @$t0 + 1) { bp poi(5f4d8948 + @$t0 * @$ptrsize) }
```

### Break when user-mode process is created (kernel-mode)

**bp nt!PspInsertProcess**

The breakpoint is hit whenever a new user-mode process is created. To know what process is it we may access the \_EPROCESS structure ImageFileName field.

    x64: dt nt!_EPROCESS @rcx ImageFileName
    x86: dt nt!_EPROCESS @eax ImageFileName

### Set a user-mode breakpoint in kernel-mode

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


## Scripting the debugger

WinDbg contains several meta-commands (starting with a dot) that allow you to control the debugger actions. The current evaluator plays an important role in interpreting the symbols in the provided command. The **.expr** command prints the current expression evaluator (MASM or C++). You may use the **/s** to change it. The **?** command uses the default evaluator, and **??** always uses the C++ evaluator. Also, you can mix the evaluators in one expression by using **@@c++(expression)** or **@@masm(expression)** syntax, for example: **? @@c++(@$peb->ImageSubsystemMajorVersion) + @@masm(0y1)**.

When using **.if** and **.foreach**, sometimes the names are not resolved - use spaces between them. For example, the command would fail if there was no space between poi( and addr in the code below.

```
.foreach (addr {!DumpHeap -mt 71d75b24 -short}) { .if (dwo(poi( addr + 5c ) + c)) { !do addr } }
```

We can also execute commands from a script file. We use the **$$** command family for that purpose. The **-c** option allows us to run a command on a debugger launch. So if we pass the **$$\<** command with a file path, windbg will read the file and execute the commands from it as if they were entered manually, for example:

```
PS> windbgx -c "$$<test.txt" notepad
```

And the test.txt content:

```
sxe -c ".echo advapi32; g" ld:advapi32
g
```

We may use the **$$\>args\<** command variant to pass arguments to our script.

When analyzing multiple files, I often use PowerShell to call WinDbg with the commands I want to run. In each WinDbg session, I pass the output of the commands to the windbg.log file, for example:

```
Get-ChildItem .\dumps | % { Start-Process -Wait -FilePath windbg-x64\windbg.exe -ArgumentList @("-loga", "windbg.log", "-y", "`"SRV*C:\dbg\symbols*https://msdl.microsoft.com/download/symbols`"", "-c", "`".exr -1; .ecxr; k; q`"", "-z", $_.FullName) }
```

You may create your own command shortcuts tree with the `.cmdtree` command.

To make a **comment**, you can use one of the comment commands: **$$ comment**, **\* comment**. The difference between them is that **\*** comments everything till the end of the line, while **$$** comments text till the semicolon (or end of a line), e.g., `r eax; $$ some text; r ebx; * more text; r ecx` will print eax, ebx but not ecx. The **.echo** command ends if the debugger encounters a semicolon (unless the semicolon occurs within a quoted string).

### The dx command

The **dx** command allows us to query the Debugger Object Model. There is a set of root objects from which we may start our query, including: **@$cursession**, **@$curprocess**, **@$curthread**, **@$curstack**, and **@$curframe**. **dx Debugger.State** shows the current state of the debugger.

Other example queries with explanations:

```
* Find kernel32 exports that contain the 'RegGetVal' string (by Tim Misiak)
dx @$curprocess.Modules["kernel32"].Contents.Exports.Where(exp => exp.Name.Contains("RegGetVal"))

* Show the address of the exported RegGetValueW function (by Tim Misiak)
dx -r1 @$curprocess.Modules["kernel32"].Contents.Exports.Single(exp => exp.Name == "RegGetValueW").CodeAddress

* Set a breakpoint on every exported function of the bindfltapi module
dx @$curprocess.Modules["bindfltapi"].Contents.Exports.Select(m =>  Debugger.Utility.Control.ExecuteCommand($"bp {m.CodeAddress}"))
```

### Javascript engine

The referance for the host object is [here](https://learn.microsoft.com/en-us/windows-hardware/drivers/debugger/native-objects-in-javascript-extensions-debugger-objects).

I tried to understand the **host object** so I wrote [a little test script](windbg-scripting.js):

```
0:000> .scriptload c:\temp\windbg-scripting.js

field    currentApiVersionSupported : object
  field    majorVersion : number
  field    minorVersion : number
field    currentApiVersionInitialized : object
  field    majorVersion : number
  field    minorVersion : number
field    diagnostics : object
  function debugBreak
  function debugLog
  function logObjectCollection
  field    logUnhandledExceptions : boolean
field    metadata : object
  function defineMetadata
  function valueWithMetadata
function typeSignatureRegistration
function typeSignatureExtension
function namedModelRegistration
function namedModelParent
function functionAlias
function namespacePropertyParent
function optionalRecord
function apiVersionSupport
function resourceFileName
function allowOutsidePropertyWrites
function Int64
function parseInt64
```

### Run a command for all the processes

```
dx -r2 @$cursession.Processes.Where(p => p.Name == "test.exe").Select(p => Debugger.Utility.Control.ExecuteCommand("|~[0n" + p.Id + "]s;bp testlib!TestMethod \".lastevent; r @rdx; u poi(@rdx); g\""))
```

### Attach to multiple processes at once

```
$ Get-Process -Name disp+work | where Id -ne 6612 | % { ".attach -b 0n$($_.Id)" } | Out-File -Encoding ascii c:\tmp\attach_all.txt
$ windbgx.exe -c "`$`$<C:\tmp\attach_all.txt" -pn winver.exe
```

### Inject a DLL into a process being debugged

In the example below we will inject shell32.dll into a target process by using the **.call** command. We start by allocating some space for the DLL name and filling it up:

```
0:000> .dvalloc 0x1a
Allocated 1000 bytes starting at 00000279`c1be0000
0:000> ezu 00000279`c1be0000 "shell32.dll"
0:000> du 00000279`c1be0000
00000279`c1be0000  "shell32.dll"
```

The .call command requires private symbols. Microsoft does not publish public symbols for KernelBase!LoadLibraryW, but we may create them (thanks to the [SymbolBuilderComposition extension](https://github.com/microsoft/WinDbg-Samples/tree/master/TargetComposition/SymBuilder)):

```
0:000> ? kernelbase!LoadLibraryW - kernelbase
Evaluate expression: 533568 = 00000000`00082440

0:000> .load c:\dbg64ex\SymbolBuilderComposition.dll

0:000> dx @$sym = Debugger.Utility.SymbolBuilder.CreateSymbols("kernelbase.dll")

0:000> dx @$fnLoadLibraryW = @$sym.Functions.Create("LoadLibraryW", "void*", 0x0000000000082440, 0x8)
0:000> dx @$param =  @$fnLoadLibraryW.Parameters.Add("lpLibFileName", "wchar_t*")
0:000> dx @$param.LiveRanges.Add(0, 8, "@rcx")

0:000> .reload /f kernelbase.dll

0:000> .call kernelbase!LoadLibraryW(0x00000279`c1be0000)

0:000> ~.g

0:000> lm
start             end                 module name
...
00007ff9`b3390000 00007ff9`b3be9000   SHELL32    (deferred)
...
```

## Time Travel Debugging (TTD)

[TTD](https://learn.microsoft.com/en-us/windows-hardware/drivers/debugger/time-travel-debugging-overview), added in WinDbg Preview, is a fantastic way to debug application code. After collecting a debug trace, we may examine it as much as possible, going deeper and deeper into the call stacks.

Additionally, TTD is one of the session properties which we can query. Axel Souchet in [this post](https://blahcat.github.io/posts/2018/11/02/some-time-travel-musings.html) presents some interesting TTD queries. I list some of them below, but I recommend checking the article to learn more.

```
0:000> dx @$cursession.TTD

0:000> dx @$cursession.TTD.Calls("user32!GetMessage*")
@$cursession.TTD.Calls("user32!GetMessage*").Count() : 0x1e8

// Isolate the address(es) newly allocated as RWX
0:000> dx @$cursession.TTD.Calls("Kernel*!VirtualAlloc*").Where( f => f.Parameters[3] == 0x40 ).Select( f => new {Address : f.ReturnValue } )

// Time-Travel to when the 1st byte is executed
0:000> dx @$cursession.TTD.Memory(0xAddressFromAbove, 0xAddressFromAbove+1, "e")[0].TimeStart.SeekTo()
```

## Misc tips

### Convert memory dump from one format to another

When debugging a full memory dump (**/ma**), we may convert it to a smaller memory dump using again the **.dump** command, for example:

```
.dump /mpi c:\tmp\smaller.dmp
```

### Loading arbitrary DLL into WinDbg for analysis

WinDbg allows analysis of an arbitrary PE file if we load it as a crash dump (the **Open dump file** menu option or the **-z** command-line argument), for example: `windbgx -z C:\Windows\System32\shell32.dll`. WinDbg will load a DLL/EXE as a data file.

Alternatively, if we want to normally load the DLL, we may use **rundll32.exe** as our debugging target and wait until the DLL gets loaded, for example: `windbgx -c "sxe ld:jscript9.dll;g" rundll32.exe .\jscript9.dll,TestFunction`. The TestFunction in the snippet could be any string. Rundll32.exe loads the DLL before validating the exported function address.

### Keyboard and mouse shortcuts

The **SHIFT + \[UP ARROW\]** completes the current command from previously executed commands (much as F8 in cmd).

If you double-click on a word in the command window in WinDbgX, the debugger will **highlight** all occurrences of the selected term. You may highlight other words with different colors if you press the ctrl key when double-clicking on them. To unhighlight a given word, double-click on it again, pressing the ctrl key.

### Check registry keys inside debugger

FIXME: !dreg
