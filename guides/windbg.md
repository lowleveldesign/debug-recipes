---
layout: page
title: WinDbg usage guide
date: 2026-02-20 08:00:00 +0200
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
    - [Extensions](#extensions)
- [Configuring WinDbg](#configuring-windbg)
    - [Referencing extensions and scripts for easy access](#referencing-extensions-and-scripts-for-easy-access)
    - [Installing WinDbg as the Windows AE debugger](#installing-windbg-as-the-windows-ae-debugger)
- [Controlling the debugging session](#controlling-the-debugging-session)
    - [Enable local kernel-mode debugging](#enable-local-kernel-mode-debugging)
    - [Setup Windows Kernel Debugging over network](#setup-windows-kernel-debugging-over-network)
    - [Debugging system services \(local remote debugging\)](#debugging-system-services-local-remote-debugging)
    - [Getting information about the debugging session](#getting-information-about-the-debugging-session)
- [Symbols and modules](#symbols-and-modules)
- [Working with memory](#working-with-memory)
    - [General memory commands](#general-memory-commands)
    - [Stack](#stack)
    - [Variables](#variables)
    - [Strings](#strings)
    - [Fixed size arrays](#fixed-size-arrays)
- [Analyzing exceptions and errors](#analyzing-exceptions-and-errors)
    - [Reading the exception record](#reading-the-exception-record)
    - [Find Windows Runtime Error message](#find-windows-runtime-error-message)
    - [Find the C++ exception object in the SEH exception record](#find-the-c-exception-object-in-the-seh-exception-record)
    - [Read the Last Windows Error value](#read-the-last-windows-error-value)
    - [Scanning the stack for native exception records](#scanning-the-stack-for-native-exception-records)
    - [Finding exception handlers](#finding-exception-handlers)
    - [Breaking on a specific exception event](#breaking-on-a-specific-exception-event)
    - [Breaking on a specific Windows Error](#breaking-on-a-specific-windows-error)
    - [Breaking on a function return](#breaking-on-a-function-return)
    - [Decoding error numbers](#decoding-error-numbers)
- [Diagnosing dead-locks and hangs](#diagnosing-dead-locks-and-hangs)
    - [Listing threads call stacks](#listing-threads-call-stacks)
    - [Finding locks in memory dumps](#finding-locks-in-memory-dumps)
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
        - [Using text files](#using-text-files)
        - [Example queries with explanations](#example-queries-with-explanations)
        - [Managed application support in the dx queries](#managed-application-support-in-the-dx-queries)
    - [Using the JavaScript engine](#using-the-javascript-engine)
        - [Loading a script](#loading-a-script)
        - [Running a script](#running-a-script)
        - [Working with types](#working-with-types)
        - [Accessing the debugger engine objects](#accessing-the-debugger-engine-objects)
        - [Evaluating expressions in a debugger context](#evaluating-expressions-in-a-debugger-context)
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
    - [Save and reopen formatted WinDbg output](#save-and-reopen-formatted-windbg-output)

<!-- /MarkdownTOC -->

Installing WinDbg
-----------------

There are two versions of WinDbg available nowadays. The modern one, called WinDbgX or WinDbg Preview, and the old one. The modern WinDbg has many interesting features (support for Time-Travel debugging is one of them), so that's the version you probably want to use if you're on a supported system.

### WinDbgX (WinDbgNext, formely WinDbg Preview)

On modern systems download the [appinstaller](https://learn.microsoft.com/en-us/windows-hardware/drivers/debugger/) file and choose Install in the context menu. If you are on Windows Server 2019 and you don't see the Install option in the context menu, there is a big chance you're missing the App Installer package on your system. In that case, you may download and run [this PowerShell script](/assets/other/windbg-install.ps1.txt) ([created by @Izybkr](https://github.com/microsoftfeedback/WinDbg-Feedback/issues/19#issuecomment-1513926394) with my minor updates to make it work with latest WinDbg releases).

### Classic WinDbg

If you need to debug on an old system with no support for WinDbgX, you need to download Windows SDK and install the Debugging Tools for Windows feature. Executables will be in the Debuggers folder, for example, `c:\Program Files (x86)\Windows Kits\10\Debuggers`.

### Extensions

Some problems may require actions that are challenging to achieve using the default WinDbg commands. One solution is to create a debugger script using the [legacy scripting language](https://learn.microsoft.com/en-us/windows-hardware/drivers/debugger/command-tokens), the [dx command](https://learn.microsoft.com/en-us/windows-hardware/drivers/debugger/dx--display-visualizer-variables-), or the [JavaScript Debugger](https://learn.microsoft.com/en-us/windows-hardware/drivers/debugger/javascript-debugger-scripting). Another option is to search for an extension that may already have the desired feature implemented. Here's a list of extensions I use daily when troubleshooting user-mode issues:

- [PDE](https://onedrive.live.com/?authkey=%21AJeSzeiu8SQ7T4w&id=DAE128BD454CF957%217152&cid=DAE128BD454CF957) by Andrew Richards - contains lots of useful commands (run `!pde.help` to learn more)
- [lldext](https://github.com/lowleveldesign/lldext) - contains my utility commands and scripts
- [comon](https://github.com/lowleveldesign/comon) - contains commands to help debug COM services
- [MEX](https://www.microsoft.com/en-us/download/details.aspx?id=53304) - another extension with many helper commands (run `!mex.help` to list them)
- [dotnet-sos](https://learn.microsoft.com/en-us/dotnet/core/diagnostics/dotnet-sos) - to debug .NET applications

Additionally, you may also check the following repositories containing WinDbg scripts for various problems:

- [TimMisiak/WinDbgCookbook](https://github.com/TimMisiak/WinDbgCookbook)
- [hugsy/windbg_js_scripts](https://github.com/hugsy/windbg_js_scripts)
- [0vercl0k/windbg-scripts](https://github.com/0vercl0k/windbg-scripts)
- [yardenshafir/WinDbg_Scripts](https://github.com/yardenshafir/WinDbg_Scripts)

Configuring WinDbg
------------------

### Referencing extensions and scripts for easy access

When we use the `.load` or `.scriptload` commands, WinDbg will search for extensions in the following folders:

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

The `windbgx -I` command registers WinDbg as the automatic system debugger - it will launch anytime an application crashes. The modified AeDebug registry keys:

```
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AeDebug
HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows NT\CurrentVersion\AeDebug
```

However, we may also use configure those keys manually and use WinDbg to, for example, create a memory dump when the application crashes:

```
REG_SZ Debugger = "C:\Users\me\AppData\Local\Microsoft\WindowsApps\WinDbgX.exe" -c ".dump /ma /u C:\dumps\crash.dmp; qd" -p %ld -e %ld -g
REG_SZ Auto = 1
```

If you miss the -g option, WinDbg will inject a remote thread with a breakpoint instruction, which will hide our original exception. In such case, you might need to scan the stack to find the original exception record.

Controlling the debugging session
---------------------------------

### Enable local kernel-mode debugging

If you are a software developer, you may not have much experience with kernel debugging. But it can be very useful to know how to inspect kernel objects in some cases. For instance, you can troubleshoot thread waits in kernel-mode more effectively and find out the causes of dead-locks or hangs faster.

To do full kernel debugging (so to control the kernel code execution) you need another Windows machine. But if you just want to analyse the kernel internal memory, you can enable local kernel debugging on your own machine. This is how you do it:

```shell
bcdedit /debug on
```

After a restart, you should be able to attach to your local kernel from WinDbg.

Another option is to use [LiveKd](https://learn.microsoft.com/en-us/sysinternals/downloads/livekd) which creates a snaphost of the kernel memory and attaches a debugger to it. It is also capable of creating a kernel memory dump for later analysis. An example command to create such a dump looks as follows:

```shell
livekd -accepteula -b -vsym -k "c:\Program Files (x86)\Windows Kits\10\Debuggers\x64\kd.exe" -o c:\tmp\kernel.dmp
```

**You don't need to boot the system in debugging mode to use livekd.** So it is safe to use even in production environments.

### Setup Windows Kernel Debugging over network

Turn on network debugging (HOSTIP is the address of the machine on which we will run the debugger):

```sh
bcdedit /dbgsettings NET HOSTIP:192.168.0.2 PORT:60000
# Key=3ma3qyz02ptls.23uxbvnd0e2zh.1gnwiqb6v3mpb.mjltos9cf63x

bcdedit /debug {current} on
# The operation completed successfully.
```

Then on the host machine, run windbg, select **Attach to kernel** and fill the port and key textboxes.

When debugging a **Hyper-V Gen 2 VM** remember to turn off the secure booting:

```sh
Set-VMFirmware -VMName "Windows 2012 R2" -EnableSecureBoot Off -Confirm
```

If you are hosting your guest on **QEMU KVM** and want to use network debugging, you need to either create your VM as a Generic one (not Windows) or update the VM configuration XML, changing the vendor_id under the hyperv node, for example:

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

### Debugging system services (local remote debugging)

Attaching a debugger to a Windows service running in session 0 should not be a problem, assuming you have the SeDebugPrivilege and can access the service. However, debugging the service startup process can be challenging.

I typically use a WinDbg remote session over named pipes along with the Image File Execution Options registry key. The approach involves starting the service under a debugger (using the -server option), both running in session 0, and then connecting to the debugger server from a local debugger instance. Here is  an example registry configuration for a testservice.exe:

```
Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\myapp.exe]
"Debugger"="windbgx.exe -Q -server npipe:pipe=svcpipe"
```

When the testservice starts, the debugger server will wait for the client to connect. You may start the client with the following command:

```sh
windbgx -remote "npipe:pipe=svcpipe,server=localhost"
```

If the Windows Service Manager stops the service before you manage to connect to it, you may need to adjust the service start timeout. For example, to set it to 3 minutes (180000 ms), use the following registry configuration:

```
Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control]
"ServicesPipeTimeout"=dword:0002bf20
```

To terminate the entire session and exit the debugging server, use the `q` command. To exit from one debugging client without terminating the server, you must issue a command from that specific client. If this client is KD or CDB, use the CTRL+B key to exit. If you are using a script to run KD or CDB, use `.remote_exit`.

### Getting information about the debugging session

The `|` command displays a path to the process image. You may run `vercommand` to check how the debugger was launched. The `vertarget` command shows the OS version, the process lifetime, and more, for example, the dump time when debugging a memory dump. The `.time` command displays information about the system time variable (session time).

`.lastevent` shows the last reason why the debugger stopped and `.eventlog` displays the recent events.

Symbols and modules
-------------------

The `lm` command lists all modules with symbol load info. To examine a specific module, use `lmvm {module-name}`. To find out if a given address belongs to any of the loaded dlls you may use the `!dlls -c {addr}` command. Another way would be to use the `lma {addr}` command.

The `.sympath` command shows the symbol search path and allows its modification. Use `.reload /f {module-name}` to reload symbols for a given module.

The `x {module-name}!{function}` command resolves a function address, and `ln {address}` finds the nearest symbol.

In WinDbgX, we may also list and filter modules with the `@$curprocess.Modules` property. Some usage examples:

```shell
# Display information about the win32u module
dx @$curprocess.Modules["win32u.dll"]

# Show public exports of the win32u module
dx @$curprocess.Modules["win32u.dll"].Contents.Exports

# List modules with information if they have combase.dll as a direct import
dx -g @$curprocess.Modules.Select(m => new { Name = m.Name, HasCombase = m.Contents.Imports.Any(i => i.ModuleName == "combase.dll") })
```

**When we don't have access to the symbol server**, we may create a list of required symbols with `symchk.exe` (part of the Debugging Tools for Windows installation) and download them later on a different host. First, we need to prepare the manifest, for example:

```shell
symchk /id test.dmp /om test.dmp.sym /s C:\non-existing
```

Then copy it to the machine with the symbol server access, and download the required symbols, for example:

```shell
symchk /im test.dmp.sym /s SRV*C:\symbols*https://msdl.microsoft.com/download/symbols
```

If **you want to add a PDB file (or files) to an existing symbol store**, you may use the `symstore add` command, for example:

```sh
# /r – recursive, /o – verbose output, /f – a path to files to index (@ symbol before the name denotes a file which contains the list of files)
# /s – root directory of the store, /t – product name, /v – version, /c – comment
symstore add /r /o /f C:\src\myapp\bin /s \\symsrv\symbols\ /t myapp /v '1.0.1' /c 'rel 1.0.1'
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
# ...
```

Additionally, it can display regions of memory of specific type, for example:

```shell
!address -f:FileMap
#   BaseAddr EndAddr+1 RgnSize     Type       State                 Protect             Usage
# -----------------------------------------------------------------------------------------------
#   9a0000   9b0000    10000 MEM_MAPPED  MEM_COMMIT  PAGE_READWRITE                     MappedFile "PageFile"
#   9b0000   9b1000     1000 MEM_MAPPED  MEM_COMMIT  PAGE_READONLY                      MappedFile "PageFile"

!address -f:MEM_MAPPED
#   BaseAddr EndAddr+1 RgnSize     Type       State                 Protect             Usage
# -----------------------------------------------------------------------------------------------
#   9a0000   9b0000    10000 MEM_MAPPED  MEM_COMMIT  PAGE_READWRITE                     MappedFile "PageFile"
#   9b0000   9b1000     1000 MEM_MAPPED  MEM_COMMIT  PAGE_READONLY                      MappedFile "PageFile"
```

### Stack

Stack grows from high to low addresses. Thus, when you see addresses bigger than the frame base (such as ebp+C) they usually refer to the function arguments. Smaller addresses (such as ebp-20) usually refer to local function variables.

To display stack frames use the `k` command. The `kP` command will additionally print function arguments if private symbols are available. The `kbM` command outputs stack frames with first three parameters passed on the stack (those will be first three parameters of the function in x86).

When there are many threads running in a process it's common that some of them have the same call stacks. To better organize call stacks we can use the `!uniqstack` command. Adding -b parameter adds first three parameters to the output, -v displays all parameters (but requires private symbols).

To switch a local context to a different stack frame we can use the `.frame` command:

```shell
.frame [/c] [/r] [FrameNumber]
.frame [/c] [/r] = BasePtr [FrameIncrement]
.frame [/c] [/r] = BasePtr StackPtr InstructionPtr
```

The `!for_each_frame` extension command enables you to execute a single command repeatedly, once for each frame in the stack.

In WinDbgX, we may access the call stack frames using `@$curstack.Frames`, for example:

```shell
dx @$curstack.Frames
# @$curstack.Frames
#     [0x0]            : ntdll!LdrpDoDebuggerBreak + 0x30 [Switch To]
#     [0x1]            : ntdll!LdrpInitializeProcess + 0x1cfa [Switch To]

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

When you have private symbols you may list local variables with the `dv` command.

Additionally the `dt` command allows you to work with type symbols. You may either list them, eg.: `dt notepad!g_*` or dump a data address using a given type format, eg.: `dt nt!_PEB 0x13123`.

The `dx` command allows you to dump local variables or read them from any place in the memory. It uses a navigation expressions just like Visual Studio (you may define your own file .natvis files). You load the interesting .natvis file with the `.nvload` command.

`#FIELD_OFFSET(Type, Field)` is an interesting operator which returns the offset of the field in the type, eg. `? #FIELD_OFFSET(_PEB, ImageSubsystemMajorVersion)`.

### Strings

The `!du` command from the [PDE extension](https://onedrive.live.com/redir?resid=DAE128BD454CF957!7152&authkey=!AJeSzeiu8SQ7T4w&ithint=folder%2czip) shows strings up to 4GB (the default du command stops when it hits the range limit).

The PDE extension also contains the `!ssz` command to look for zero-terminated (either unicode or ascii) strings. To change a text in memory use `!ezu`, for example: `ezu  "test string"`. The extension works on committed memory.

Another interesting command is `!grep`, which allows you to filter the output of other commands: `!grep _NT !peb`.

### Fixed size arrays

Printing an array of a specific size with dx might be tricky. The code below shows two ways of printing a fixed-size char array:

```sh
dx (*((char (*)[16])0x31aa5526)),c
# (*((jvm!char (*)[16])0x31aa5526)),c                 [Type: char [16]]
#     [0]              : 106 'j' [Type: char]
#     ...
#     [15]             : 116 't' [Type: char]

dx ((char*)0x31aa5526),16c
# ((char*)0x31aa5526),16c                 : 0x31aa5526 [Type: char *]
#     [0]              : 106 'j' [Type: char]
#     ...
#     [15]             : 116 't' [Type: char]
```

Altenatively, we could use `db 0x31aa5526 L10`.

Analyzing exceptions and errors
-------------------------------

### Reading the exception record

The  `.ecxr` debugger command instructs the debugger to restore the thread context to its state when the initial fault happened. When dispatching a SEH exception, the OS builds an internal structure called an `exception record`. It also conveniently saves the thread context at the time of the initial fault in a context record structure.

```cpp
typedef struct _EXCEPTION_RECORD {
  DWORD                    ExceptionCode;
  DWORD                    ExceptionFlags;
  struct _EXCEPTION_RECORD *ExceptionRecord;
  PVOID                    ExceptionAddress;
  DWORD                    NumberParameters;
  ULONG_PTR                ExceptionInformation[EXCEPTION_MAXIMUM_PARAMETERS];
} EXCEPTION_RECORD;
```

`.lastevent` will also show you information about the last error that occured (if the debugger stopped because of an error). You may then examine the exception record using the `.exr` command, for example:

```sh
.lastevent
# Last event: 15ae8.133b4: CLR exception - code e0434f4d (first/second chance not available)
#   debugger time: Thu Jul 30 19:23:53.169 2015 (UTC + 2:00)

.exr -1
# ExceptionAddress: 000007fe9b17f963
#    ExceptionCode: e0434f4d (CLR exception)
#   ExceptionFlags: 00000000
# NumberParameters: 0
```

If we look at the raw memory, we will find that .exr changes the order of the EXCEPTION_RECORD fields, for example:

```sh
.exr 0430af24
# ExceptionAddress: abe8f04d
#    ExceptionCode: c0000005 (Access violation)
#   ExceptionFlags: 00000000
# NumberParameters: 2
#    Parameter[0]: 00000000
#    Parameter[1]: abe8f04d
```

```
0430af24  c0000005 <- exception code
0430af28  00000000
0430af2c  00000000
0430af30  abe8f04d <- exception address (code address)
0430af34  00000002 <- parameters number
0430af38  00000000
0430af3c  abe8f04d
```

### Find Windows Runtime Error message

If you need to diagnose Windows Runtime Error for example: `(2f88.3358): Windows Runtime Originate Error - code 40080201 (first chance)`, you may enable first chance notification for this error: `sxe 40080201`. When stopped, retrieve the exception context, and the third parameter should contain an error message:

```sh
.exr -1
# ExceptionAddress: 77942822 (KERNELBASE!RaiseException+0x00000062)
#    ExceptionCode: 40080201 (Windows Runtime Originate Error)
#   ExceptionFlags: 00000000
# NumberParameters: 3
#    Parameter[0]: 80040155
#    Parameter[1]: 00000052
#    Parameter[2]: 0dddf680

du 0dddf680
# 0dddf680  "Failed to find proxy registratio"
# 0dddf6c0  "n for IID: {xxxxxxxx-xxxx-xxxx-x"
# 0dddf700  "xxx-xxxxxxxxxxxx}."
```

We may automate this step by using the `$exr_param2` pseudo-register:

```sh
sxe -c "du @$exr_param2 L40; g" 40080201
```

### Find the C++ exception object in the SEH exception record

*(Tested on MSVC140)*

If it's the first chance exception, we can find the exception record at the top of the stack:

```sh
dps @esp
# 00f3fb28  7657ec52 KERNELBASE!RaiseException+0x62
# 00f3fb2c  00f3fb30
# 00f3fb30  e06d7363
# 00f3fb34  00000001
# 00f3fb38  00000000
# 00f3fb3c  7657ebf0 KERNELBASE!RaiseException
# 00f3fb40  00000003
# 00f3fb44  19930520
# 00f3fb48  00f3fbd8
# 00f3fb4c  009ab96c exceptions!_TI3?AVinvalid_argumentstd
```

With dx and the `MSVCP140D!EHExceptionRecord` symbol (without this symbol, we need to get the value from `.exr -1`), we may decode the exception record parameters:

```sh
dx -r2 (MSVCP140D!EHExceptionRecord*)0x00f3fb30
# (MSVCP140D!EHExceptionRecord*)0x00f3fb30                 : 0xf3fb30 [Type: EHExceptionRecord *]
#     [+0x000] ExceptionCode    : 0xe06d7363 [Type: unsigned long]
#     [+0x004] ExceptionFlags   : 0x1 [Type: unsigned long]
#     [+0x008] ExceptionRecord  : 0x0 [Type: _EXCEPTION_RECORD *]
#     [+0x00c] ExceptionAddress : 0x7657ebf0 [Type: void *]
#     [+0x010] NumberParameters : 0x3 [Type: unsigned long]
#     [+0x014] params           [Type: EHExceptionRecord::EHParameters]
#         [+0x000] magicNumber      : 0x19930520 [Type: unsigned long]
#         [+0x004] pExceptionObject : 0xf3fbd8 [Type: void *]
#         [+0x008] pThrowInfo       : 0x9ab96c [Type: _s_ThrowInfo *]
```

As you can see, the second parameter points to the C++ exception object. If we know its type, we may dump its properties, for example:

```sh
dx (exceptions!std::invalid_argument*)0x00f3fbd8 
#   [+0x004] _Data            : __std_exception_data

dx -r1 (*((exceptions!__std_exception_data *)0xf3fbdc))
# (*((exceptions!__std_exception_data *)0xf3fbdc))                 [Type: __std_exception_data]
#     [+0x000] _What            : 0x1449748 : "arg1" [Type: char *]
#     [+0x004] _DoFree          : true [Type: bool]
```

### Read the Last Windows Error value

To get the last error value for the current thread we may use the `!gle` or `!teb` command. `!gle` has an additional -all parameter which shows the last errors for all the threads:

```sh
!gle -all
# Last error for thread 0:
# LastErrorValue: (Win32) 0 (0) - The operation completed successfully.
# LastStatusValue: (NTSTATUS) 0xc0000034 - Object Name not found.
# 
# Last error for thread 1:
# LastErrorValue: (Win32) 0 (0) - The operation completed successfully.
# LastStatusValue: (NTSTATUS) 0 - STATUS_SUCCESS
```

### Scanning the stack for native exception records

Sometimes, when the memory dump was incorrectly collected, we may not see the exception information and the `.exr -1` does not work. When this happens, there is still a chance that the original exception is somewhere in the stack. Using the `.foreach` command, we may scan the stack and try all the addresses to see if any of them is a valid exception record. For example:

```sh
.foreach /ps1 ($addr { dp /c1 @$csp L100 }) { .echo $addr; .exr $addr }
# 0430af24
# ExceptionAddress: abe8f04d
#    ExceptionCode: c0000005 (Access violation)
#   ExceptionFlags: 00000000
# NumberParameters: 2
#    Parameter[0]: 00000000
#    Parameter[1]: abe8f04d
```

### Finding exception handlers

To list exception handlers for the currently running method use `!exchain` command.

Managed exception handlers can be listed using the `!EHInfo` command from the SOS extenaion. I present how to use this command to list ASP.NET MVC exception handlers [on my blog](https://lowleveldesign.wordpress.com/2013/04/26/life-of-exception-in-asp-net/).

In 32-bit application, pointer to the exception handler is kept in `fs:[0]`. The prolog for a method with exception handling has the following structure:

```
mov     eax,fs:[00000000]
push    eax
mov     fs:[00000000],esp
```

An Example session of retrieving the exception handler:

```sh
dd /c1 fs:[0]-8 L10
# 0053:fffffff8  00000000
# 0053:fffffffc  00000000
# 0053:00000000  0072ef74 <-- this is our first exception pointer to a handler
# 0053:00000004  00730000
# 0053:00000008  0072c000

dd /c1 0072ef74-8 L10
# 0072ef6c  0072eefc
# 0072ef70  74275582
# 0072ef74  0072f04c <-- previous handler
# 0072ef78  744048b9 <-- handler address
# 0072ef7c  2778008f
# 0072ef80  00000000
# 0072ef84  0072f058
# 0072ef88  744064f9
```

In 64-bit applications, information about exception handlers is stored in the PE file. We can list them using, for example, the `dumpbin /unwindinfo` command.

### Breaking on a specific exception event

The `sx-` commands define how WinDbg handles exception events that happen in the process lifetime. For example, to stop the debugger when a C++ exception is thrown (1st change exception) we would use the `sxe eh` command. If we only need information that an exception occurred, we could use the `sxn eh` command. Additionally, the -c parameter gives us a possibility to run our custom command on error:

```sh
sxe -c ".lastevent;!pe;!clrstack;g" clr
```

### Breaking on a specific Windows Error

There is a special global variable in ntdll, `g_dwLastErrorToBreakOn`, that you may set to cause a break whenever a given last error code is set by the application. For example, to break the application execution whenever it reports the `0x4cf` (ERROR_NETWORK_UNREACHABLE) error, run:

```sh
ed ntdll!g_dwLastErrorToBreakOn 0x4cf
```

You may find the list of errors in [the Windows documentation](https://docs.microsoft.com/en-us/windows/win32/debug/system-error-codes).

### Breaking on a function return

If we want to break when a function finishes, for example, to analyze its result, we may use a nested one-time breakpoint on the function return address, for example:

```sh
bp kernelbase!CreateFileW "bp /1 $ra \"r @rax\"; g"
```

### Decoding error numbers

If you receive an error message with a cryptic error number like this, for example: *Compiler Error Message: The compiler failed with error code -1073741502*, you may use the `!error` command:

```sh
!error c0000142
# Error code: (NTSTATUS) 0xc0000142 (3221225794) - {DLL Initialization Failed} Initialization of the dynamic link library %hs failed. The process is terminating abnormally.
```

Even more error codes and error messages are contained in the `!pde.err` command from the PDE extension.

If you need to convert HRESULT to Windows Error, the following pseudo-code might help:

```cpp
a = hresult & 0x1FF0000
if (a == 0x70000) {
    winerror = hresult & 0xFFFF
} else {
    winerror = hresult
}
```

Converting Windows Error to HRESULT is straightforward: `hresult = 0x80070000 | winerror`.

A great **command line tool** for decoding error number is [err.exe or Error Code Look-up](https://www.microsoft.com/en-us/download/details.aspx?id=985). It looks for the specific value in Windows headers, additionally performing the convertion to hex, for example:

```sh
err -1073741502
# for decimal -1073741502 / hex 0xc0000142 :
#  STATUS_DLL_INIT_FAILED                                        ntstatus.h
# {DLL Initialization Failed}
# Initialization of the dynamic link library %hs failed. The
# process is terminating abnormally.
# ...
```

There is also a subcommand in the Windows built-in `net` command to decode Windows error numbers (and only error numbers), for example:

```sh
net helpmsg 2
# The system cannot find the file specified.
```

Diagnosing dead-locks and hangs
-------------------------------

We usually start the analysis by looking at the threads running in a process. The call stacks help us identify blocked threads. We can use TTD, thread-time trace, or memory dumps to learn about what threads are doing. In the follow-up sections, I will describe how to find lock objects and relations between threads in memory dumps.

### Listing threads call stacks

To list native stacks for all the threads run: `~*k` or `!uniqstacks`.

### Finding locks in memory dumps

There are many types of objects that the thread can wait on. You usually see WaitOnMultipleObjects on many threads.

If you see `RtlWaitForCriticalSection` it might indicate that the thread is waiting on a critical section`. Its adress should be in the call stack. And we may list the critical sections using the `!cs` command. With the -s option, we may examine details of a specific critical section:

```sh
!cs -s 000000001a496f50
# -----------------------------------------
# Critical section   = 0x000000001a496f50 (+0x1A496F50)
# DebugInfo          = 0x0000000013c9bee0
# LOCKED
# LockCount          = 0x0
# WaiterWoken        = No
# OwningThread       = 0x0000000000001b04
# RecursionCount     = 0x1
# LockSemaphore      = 0x0
# SpinCount          = 0x00000000020007d0
```

LockCount tells you how many threads are currently waiting on a given cs. The OwningThread is a thread that owns the cs at the time the command is run. You can easily identify the thread that is waiting on a given cs by issuing kv command and looking for critical section identifier in the call parameters.

We can also look for **synchronization object handles** using the `!handle` command. For example, we may list all the Mutant objects in a process by using the `!handle 0 f Mutant` command.

System objects in the debugger
------------------------------

The `!object` command displays some basic information about a kernel object:

```sh
!object  ffffc30162f26080
# Object: ffffc30162f26080  Type: (ffffc30161891d20) Process
#     ObjectHeader: ffffc30162f26050 (new version)
#     HandleCount: 23  PointerCount: 582900
```

We may then analyze the object header to learn some more details about the object, for example:

```sh
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

Each time you break into the kernel-mode debugger, one of the processes will be active. You may learn which one by running the `!process -1 0` command. If you are going to work with user-mode memory space you need to reload the process modules symbols (otherwise you will see symbols from the last reload). You may do so while switching process context with `.process /i` (/i means invasive debugging and allows you to control the process from the kernel debugger) or `.process /r /p` (/r reloads user-mode symbols after the process context has been set (the behavior is the same as `.reload /user`), /p translates all transition page table entries (PTEs) for this process to physical addresses before access).

`!peb` shows loaded modules, environment variables, command line arg, and more.

The `!process 0 0 {image}` command finds a proces using its image name, e.g.: `!process 0 0 LINQPad.UserQuery.exe`.

When we know the process ID, we may use `!process {PID | address} 0x7` (the 0x7 flag will list all the threads with their stacks).

### Handles

There is a special debugger extension command `!handle` that allows you to find system handles reserved by a process.

To list all handles reserved by a process use -1 (in kernel mode) or 0 (in user-mode). You may filter the list by setting a type of a handle:

```shell
!handle 0 1 File
# ...
# Handle 1c0
#   Type          File
# 7 handles of type File
```

### Threads

The `!thread {addr}` command shows details about a specific thread. Each thread has its own register values. These values are stored in the CPU registers when the thread is executing and are stored in memory when another thread is executing. You can set the register context using .thread command:

```
.thread [/p [/r] ] [/P] [/w] [Thread]
```

or

```
.trap [Address]
.cxr [Options] [Address]
```

For **WOW64 processes**, the /w parameter (`.thread /w`) will additionally switch to the x86 context. After loading the thread context, the commands opearating on stack should start working (remember to be in the right process context).

**To list all threads** in a current process use the `~*`command (user-mode). Dot (.) in the first column signals a currently selected thread and hash (#) points to a thread on which an exception occurred.

`!runaway` shows the time consumed by each thread:

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

`~~[thread-id]` - in case you would like to use the system thread id you may with this syntax.

`!tls Slot` extension displays a thread local storage slot (or -1 for all slots)

### Critical sections

Display information about a particular critical section: `!critsec {address}`.

`!locks` extension in Ntsdexts.dll displays a list of critical sections associated with the current process.

`!cs -lso [Address]`  - display information about critical sections (-l - only locked critical sections, -o - owner's stack, -s  - initialization stack, if available)

`!critsec Address` - information about a specific critical section

```sh
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

To go up the funtion use `gu` command. We can go to a specified address using `ga [address]`. We can also step or trace to a specified address using accordingly `pa` and `ta` commands.

Useful commands are `pc` and `tc` which step or trace to the next call statement. `pt` and `tt` step or trace to the next return statement.

### Watch trace

`wt` is a very powerful command and might be excellent at revealing what the function under the cursor is doing, eg. (-oa displays the actual address of the call sites, -or displays the return register values):

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

If the `wt` command does not work, you may achieve similar results manually with the help of the target controlling commands:

- stepping until a specified address: `ta`, `pa`
- stepping until the next branching instruction: `th`, `ph`
- stepping until the next call instruction: `tc`, `pc`
- stepping until the next return: `tt`, `pt`
- stepping until the next return or call instruction: `tct`, `pct`


### Breaking when a specific function is in the call stack

```shell
bp Module!MyFunctionWithConditionalBreakpoint "r $t0 = 0;.foreach (v { k }) { .if ($spat(\"v\", \"*Module!ClassA:MemberFunction*\")) { r $t0 = 1;.break } }; .if($t0 = 0) { gc }"
```

### Breaking on a specific function enter and leave

The trick is to set a one-time breakpoint on the return address (`bp /1 @$ra`) when the main breakpoint is hit, for example:

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

`bp nt!PspInsertProcess`

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

WinDbg contains several meta-commands (starting with a dot) that allow you to control the debugger actions. The `.expr` command prints the expression evaluator (MASM or C++) that will be used when interpreting the symbols in the executed commands. You may use the /s to change it. The `?` command uses the default evaluator, and `??` always uses the C++ evaluator. Also, you can mix the evaluators in one expression by using `@@c++(expression)` or `@@masm(expression)` syntax, for example: `? @@c++(@$peb->ImageSubsystemMajorVersion) + @@masm(0y1)`.

When using `.if` and `.foreach`, sometimes the names are not resolved - use spaces between them. For example, the command would fail if there was no space between poi( and addr in the code below.

```shell
.foreach (addr {!DumpHeap -mt 71d75b24 -short}) { .if (dwo(poi( addr + 5c ) + c)) { !do addr } }
```

### Using the dx command

The [dx command](https://learn.microsoft.com/en-us/windows-hardware/drivers/debuggercmds/dx--display-visualizer-variables-) allows us to query the Debugger Object Model. There is a set of root objects from which we may start our query, including `@$cursession`, `@$curprocess`, `@$curthread`, `@$curstack`, or `@$curframe`.

`dx Debugger.State` shows the current state of the debugger. The -h parameter additionally displays help for the debugger objects, for example:

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

If we add the -v parameter, dx will print not only the values of the properties and fields but also the methods we may call on an object:

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

In our queries we may create anonymous objets, lambdas, arrays and objects of the Debugger Object Model types, for example:

```sh
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

We may also use variables and pseudo-registers available in the debugger context. You may list them by examining the `Debugger.State.DebuggerVariables`, `Debugger.State.PseudoRegisters`, and `Debugger.State.UserVariables` objects.

#### Using text files

The `FileSystem` API allows us to access the host file system. To have the full control over the lifetime of the opened file handle, I recommend using the file object explicitly. The following code is an example when we read all lines from a file to an array:

```cpp
dx @$file = Debugger.Utility.FileSystem.OpenFile("c:\\temp\\test.txt")
dx @$lines = Debugger.Utility.FileSystem.CreateTextReader(@$file).ReadLineContents().ToArray()
dx @$file.Close()
```

#### Example queries with explanations

```sh
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

Additionally, we may query **the managed heap** (the `ManagedHeap` property is a nice replacement for the `!DumpHeap` command):

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

The `.scriptproviders` command must include the JavaScript provider in the output.

Then we may run a script with the `.scriptrun` command or load it using the `.scriptload` command. The difference is that model modifications made by the `.scriptload` will stay in place until the call to `.scriptunload`. Also, `.scriptrun` will call the `invokeScript` JS function after the usual calls to the root code and the `initializeScript` function.

`.scriptlist` lists the loaded scripts.

#### Running a script

After loading a script file, we may find it in the `Debugger.State.Scripts` list (`.scriptlist` will show it, too):

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

The `@$scriptContents` variable is a shortcut to all the public functions from all the loaded scripts, so our call could be more compact:

```shell
dx @$scriptContents.logn("test")
# test

@$scriptContents.logn("test")
```

#### Working with types

The `Number` type in JavaScript has a 53-bit limitation, which prevents us from working with 64-bit types. Fortunately, WinDbg provides us with the `Int64` type with methods for operations on 64-bit numbers such as `getLowPart`, `getHighPart`, `bitwiseAnd`, or `bitwiseShiftLeft` (others in [the documentation](https://learn.microsoft.com/en-us/windows-hardware/drivers/debugger/javascript-debugger-scripting#work-with-64-bit-values-in-javascript-extensions)). It also has a properly implemented `toString` and can be safely used for hexadecimal conversion of data from the debugger, for example:

```js
function initializeScript()
{
    return [new host.apiVersionSupport(1, 7), new host.functionAlias(runTest, "runTest")]
}

function __hexString2(n) {
    return n.toString(16);
}

function runTest(n) {
    return __hexString2(n);
}
```

```shell
dx @$n = 0xffffffffffffffff
# @$n = 0xffffffffffffffff : -1

!runTest(@$n)
# @$runTest(@$n)   : ffffffffffffffff
#     Length           : 0x10
```

Additiona, the JS provider tracks created `Int64` objects and, if an object for a given value already exists, it will be returned, for example:

```js
const call = host.currentSession.TTD.Calls("combase!CoCreateInstance").First();

const ppv = call.Parameters.ppv.address;

call.TimeEnd.SeekTo();

const cobj = host.evaluateExpression(`*(void **)${ppv}`).address;
const i2 = new host.Int64(cobj);

const m = new Map();
m.set(i2, clsid);
m.set(cobj, clsid);
// the m size is 1
__logn(`m size : ${m.size}`);
```

#### Accessing the debugger engine objects

The `host.namespace` gives us access to the `debuggerRootNamespace` which we normally use with the `dx` command:

```shell
dx @$debuggerRootNamespace
# @$debuggerRootNamespace                
#     Debugger
```

```js
var ctl = host.namespace.Debugger.Utility.Control;   
ctl.ExecuteCommand(".process /p /r " + procId);
```

DML might pollute the command output. If that's the case, you may disable it with the `.prefer_dml 0` command.

#### Evaluating expressions in a debugger context

The `host.evaluateExpression` allows to evaluate expressions, for eaxmple:

```js
function exc(addr) {
    let exceptionRecord = host.evaluateExpression(`(_EXCEPTION_RECORD*)${addr}`);
    let exceptionCode = host.evaluateExpression(`(DWORD)${exceptionRecord.ExceptionCode}`)

    if (exceptionCode === 0xe06d7363) {
        println("== EH exception ==");
        exceptionRecord.
    } else {
        logn(`Other exception: ${exceptionCode}`)
    }
}
```

It is quite slow, so using it in frequently executed functions is not practical.

#### Debugging a script

After we loaded the script (`.scriptload`), we may also debug its parts thanks to the `.scriptdebug` command, for example:

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

The number of commands available in the inner JavaScript debugger is quite long and we may list them with the `.help` command. Especially, the evaluate expression (`?` or `??`) are very useful as they allow us to execute any JavaScript expressions and check their results:

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

We can also execute commands from a script file. We use the `$$` command family for that purpose. The -c option allows us to run a command on a debugger launch. So if we pass the `$$<` command with a file path, windbg will read the file and execute the commands from it as if they were entered manually, for example:

```shell
windbgx -c "$$<test.txt" notepad
```

And the test.txt content:

```shell
sxe -c ".echo advapi32; g" ld:advapi32
g
```

We may use the `$$>args<` command variant to pass arguments to our script.

When analyzing multiple files, I often use PowerShell to call WinDbg with the commands I want to run. In each WinDbg session, I pass the output of the commands to the windbg.log file, for example:

```shell
Get-ChildItem .\dumps | % { Start-Process -Wait -FilePath windbg-x64\windbg.exe -ArgumentList @("-loga", "windbg.log", "-y", "`"SRV*C:\dbg\symbols*https://msdl.microsoft.com/download/symbols`"", "-c", "`".exr -1; .ecxr; k; q`"", "-z", $_.FullName) }
```

To make a **comment**, you can use one of the comment commands: `$$ my comment` or `* my comment`. The difference between them is that `*` comments everything till the end of the line, while `$$` comments text till the semicolon (or end of a line), e.g., `r eax; $$ some text; r ebx; * more text; r ecx` will print eax, ebx but not ecx. The `.echo` command ends if the debugger encounters a semicolon (unless the semicolon occurs within a quoted string).

Time Travel Debugging (TTD)
---------------------------

[TTD](https://learn.microsoft.com/en-us/windows-hardware/drivers/debugger/time-travel-debugging-overview) is a fantastic way to debug application code. After collecting a debug trace, we may query process memory, function calls, going deeper and deeper into the call stacks if necessary, and jump through various process lifetime events.

### Installation

The collector is installed with WinDbgX and we may enable it when starting a WinDbgX debugging session.

Alternatively, we could [install the command-line TTD collector](https://learn.microsoft.com/en-us/windows-hardware/drivers/debuggercmds/time-travel-debugging-ttd-exe-command-line-util#how-to-download-and-install-the-ttdexe-command-line-utility-preferred-method). The PowerShell script published on the linked site is capable of installing TTD even on systems not supporting the MSIX installations. The command-line tool is probably the best option when collecting TTD traces on server systems. When done, you may uninstall the driver by using the -cleanup option.

### Collection

If you have WinDbgX, you may use TTD by checking the "Record with Time Travel Debugging" checkbox when you start a new process or attach to a running one. When you stop the TTD trace in WinDbgX it will terminate the target process (TTD.exe, described later, can detach from a process without killing it).

An alternative to WinDbgX is running the command-line TTD collector. Some usage examples:

```sh
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

```sh
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

The `@$curprocess.Events` collection contains [TTD Event objects](https://learn.microsoft.com/en-us/windows-hardware/drivers/debuggercmds/time-travel-debugging-event-objects). We can use the group query to learn what type of events we have in our trace:

```sh
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

```sh
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

The `Calls` method of the `TTD` objects allows us to query [function calls](https://learn.microsoft.com/en-us/windows-hardware/drivers/debuggercmds/time-travel-debugging-calls-objects) made in the trace. We may use either an address or a symbol name (even with wildcards) as a parameter to the Calls method:

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

TimeStart shows the position of a call in a trace and we may use it to jump between different places in the trace. SystemTimeStart shows the clock time of a given call:

```shell
dx -g @$cursession.TTD.Calls("user32!DialogBox*").Select(c => new { Function = c.Function, TimeStart = c.TimeStart, SystemTimeStart = c.SystemTimeStart })
# ==============================================================================================================
# =          = (+) Function                         = (+) TimeStart = (+) SystemTimeStart                      =
# ==============================================================================================================
# = [0x0]    - USER32!DialogBoxIndirectParamW       - 62E569:57     - Friday, February 2, 2024 16:03:39.391    =
# = [0x1]    - USER32!DialogBoxIndirectParamAorW    - 62E569:5C     - Friday, February 2, 2024 16:03:39.391    =
# = [0x2]    - USER32!DialogBox2                    - 631C23:102    - Friday, February 2, 2024 16:03:39.791    =
```

Each function call has a Parameters property that gives us access to the function parameters (without private symbols, we can access the first four parameters) of a call:

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

The [TTD Position object](https://learn.microsoft.com/en-us/windows-hardware/drivers/debuggercmds/time-travel-debugging-position-objects) describes a moment in time in the trace. Its `SeekTo` method allows us to jump to this moment and analyze the process state:

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

Alternatively, we could use `!tt 865B:4FE` to jump to a specific time position.

If we are troubleshooting an issue spanning multiple processes, we may simultaneously record TTD traces for all of them, and later, use the TTD Position objects to set the same moment in time in all the traces. It is a very effective technique when debugging locking issues.

### Examining memory access

The `Memory` and `MemoryForPositionRange` methods of the TTD Session object return [TTD Memory objects](https://learn.microsoft.com/en-us/windows-hardware/drivers/debuggercmds/time-travel-debugging-memory-objects) describing various operations on the memory. For example, the command below shows all the changes to the global GcInProgress variable in a .NET application:

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

The `MemoryForPositionRange` method allows us to additionally limit memory access queries to a specific time-range. It makes sense to use this method for scope-based addresses, such as function parameters or local variables. Below, you may see an example of a query when we list all the places in the CreateFileW function that read the file name (the first argument to the function):

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

When debugging a full memory dump (**/ma**), we may convert it to a smaller memory dump using again the `.dump` command, for example:

```shell
.dump /mpi c:\tmp\smaller.dmp
```

### Loading an arbitrary DLL into WinDbg for analysis

WinDbg allows analysis of an arbitrary PE file if we load it as a crash dump (the **Open dump file** menu option or the -z command-line argument), for example: `windbgx -z C:\Windows\System32\shell32.dll`. WinDbg will load a DLL/EXE as a data file.

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

You may use the `!injectdll` command from my [lldext](https://github.com/lowleveldesign/lldext) extension.

Or use the `.call` method, as shown in the shell32.dll example below. We start by allocating some space for the DLL name and filling it up:

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

### Save and reopen formatted WinDbg output

Sometimes you may want to persist debugger output while preserving DML tags. This is achieved using the **Save Window to File** button in the **Command** ribbon tab. The resulting file uses a .dml extension; opening it in a text editor confirms that the markup remains intact.

To reload this output into a new WinDbg command window, use the `.dml_start` command:

```shell
.dml_start C:\temp\test.dml
```

{% endraw %}
