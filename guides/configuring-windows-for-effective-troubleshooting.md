---
layout: page
title: Configuring Windows for effective troubleshooting
date: 2023-10-11 08:00:00 +0200
---

**Table of contents:**

<!-- MarkdownTOC -->

- [Configuring debug symbols](#configuring-debug-symbols)
- [Installing Windows debugger \(WinDbg\)](#installing-windows-debugger-windbg)
    - [WinDbg extensions](#windbg-extensions)
- [Enabling local kernel-mode debugging](#enabling-local-kernel-mode-debugging)
- [Replacing Task Manager with System Informer](#replacing-task-manager-with-system-informer)
- [Installing and configuring Sysinternals Suite](#installing-and-configuring-sysinternals-suite)
- [Configuring post-mortem debugging](#configuring-post-mortem-debugging)
- [Installing ETW tools](#installing-etw-tools)

<!-- /MarkdownTOC -->

## Configuring debug symbols

Staring at raw hex numbers is not very helpful for troubleshooting. Therefore, it's essential to take the time to properly configure debug symbols on our system. One effective method is to set the **\_NT\_SYMBOL\_PATH** environment variable. Most troubleshooting tools read its value and utilize the specified symbol stores. I usually configure it to point only to the official Microsoft symbol server, resulting in the following value for the \_NT\_SYMBOL\_PATH variable on my system: `SRV*C:\symbols\dbg*https://msdl.microsoft.com/download/symbols`. Here, `C:\symbols` serves as a cache folder for storing downloaded symbols. I also use `C:\symbols\dbg` if I need to index PDB files for my applications. For further information about the \_NT\_SYMBOL\_PATH variable, refer to [the official documentation](https://learn.microsoft.com/en-us/windows-hardware/drivers/debugger/symbol-path).

The symbol path variable is one essential component required for successful symbol resolution. Another critical aspect is the version of **dbghelp.dll** that can work with symbol servers. Unfortunately, the version preinstalled with Windows lacks this feature. To overcome this issue, you can install the **Debugging Tools for Windows** from the [Windows SDK](https://developer.microsoft.com/en-us/windows/downloads/windows-sdk/). Make sure to install both the x86 and x64 versions to enable debugging of both 32- and 64-bit applications. Once installed, certain tools (e.g., Symbol Informer) will automatically select the appropriate dbghelp.dll version, while others will require some configuration, as we'll explore in later sections.

## Installing Windows debugger (WinDbg)

There are two versions of WinDbg available nowadays. The modern one, called WinDbgX or WinDbg Preview, and the old one. The modern one is available either through a Microsoft Store or through the [appinstall package](https://aka.ms/windbg/download), while the old one is distributed with [Windows SDK](https://developer.microsoft.com/en-us/windows/downloads/windows-sdk/) as a part of the Debugging Tools for Windows. The modern WinDbg has many interesting features (support for Time-Travel debugging is one of them), so that's the version you probably want to use if you're on a supported system (if you're on Windows Server 2019, you may still try to install the modern WinDbg by following the steps described in the later section).

There are currently two versions of WinDbg available. The modern one, known as WinDbgX or WinDbg Preview, and the older version. You can obtain the modern version either through the Microsoft Store or by using the [appinstall package](https://aka.ms/windbg/download). The older version is included with the Debugging Tools for Windows package in [Windows SDK](https://developer.microsoft.com/en-us/windows/downloads/windows-sdk/). The modern WinDbg has an intuitive UI, supports Time-Travel debugging, and has a much better support for automation. Therefore, if you're using a supported system, I recommend using the modern version (even if you are on Windows Server 2019 missing the App Installer package, you can still install the modern WinDbg by following the steps outlined in [this guide](https://gist.github.com/lowleveldesign/50057e213aba366393c6d7fe0eb37c3a)).

### WinDbg extensions

Some problems may require actions that are challenging to achieve using the default WinDbg commands. One solution is to create a debugger script using the [legacy scripting language](https://learn.microsoft.com/en-us/windows-hardware/drivers/debugger/command-tokens), the [dx command](https://learn.microsoft.com/en-us/windows-hardware/drivers/debugger/dx--display-visualizer-variables-), or the [JavaScript Debugger](https://learn.microsoft.com/en-us/windows-hardware/drivers/debugger/javascript-debugger-scripting). Another option is to search for an extension that may already have the desired feature implemented. Here's a list of extensions I use daily when troubleshooting user-mode issues:

- [PDE](https://onedrive.live.com/?authkey=%21AJeSzeiu8SQ7T4w&id=DAE128BD454CF957%217152&cid=DAE128BD454CF957) by Andrew Richards - contains lots of useful commands (run **!pde.help** to learn more)
- [MEX](https://www.microsoft.com/en-us/download/details.aspx?id=53304) - another extension with many helper commands (run **!mex.help** to list them)
- [comon](https://github.com/lowleveldesign/comon) - contains commands to help debug COM services
- [dotnet-sos](https://learn.microsoft.com/en-us/dotnet/core/diagnostics/dotnet-sos) - to debug .NET applications

Additionally, you may also check the following repositories containing WinDbg scripts for various problems:

- [TimMisiak/WinDbgCookbook](https://github.com/TimMisiak/WinDbgCookbook)
- [hugsy/windbg_js_scripts](https://github.com/hugsy/windbg_js_scripts)
- [0vercl0k/windbg-scripts](https://github.com/0vercl0k/windbg-scripts)
- [yardenshafir/WinDbg_Scripts](https://github.com/yardenshafir/WinDbg_Scripts)

## Enabling local kernel-mode debugging

If you are a software developer, you may not have much experience with kernel debugging. But it can be very useful to know how to inspect kernel objects in some cases. For instance, you can troubleshoot thread waits in kernel-mode more effectively and find out the causes of dead-locks or hangs faster.

To do full kernel debugging (so to control the kernel code execution) you need another Windows machine. But if you just want to analyse the kernel internal memory, you can enable local kernel debugging on your own machine. This is how you do it:

```
bcdedit /debug on
```

After a restart, you should be able to attach to your local kernel from WinDbg.

Another option is to use [LiveKd](https://learn.microsoft.com/en-us/sysinternals/downloads/livekd) which creates a snaphost of the kernel memory and attaches a debugger to it. It is also capable of creating a kernel memory dump for later analysis. An example command to create such a dump looks as follows:

```
livekd -accepteula -b -vsym -k "c:\Program Files (x86)\Windows Kits\10\Debuggers\x64\kd.exe" -o c:\tmp\kernel.dmp
```

What's important to mention is that you don't need to boot the system in debugging mode to use livekd. So it is safe to use even in production environments.

## Replacing Task Manager with System Informer

My long time favorite tool to observe system and processes running on it, is [System Informer](https://www.systeminformer.com/), formerly known as Process Hacker. It has so many great features that deserves a guide on its own. The process tree, which shows the process creation and termination events, is much more readable than the flat process list in Task Manager or Resource Monitor. Moreover, System Informer lets you manage services and drivers, and view live network connections. Therefore, I highly recommend to open the Options dialog and replace Task Manager with it. System Informer does not have an option to set the dbghelp.dll path in its settings, but it will detect it if you have Debugging Tools for Windows installed. So please install them to have Windows stacks correctly resolved.

If you have reasons not to use System Informer, you can try [Process Explorer](https://learn.microsoft.com/en-us/sysinternals/downloads/process-explorer). It does not have as many functionalities as System Informer, but it is still a powerful system monitor.

## Installing and configuring Sysinternals Suite

[Sysinternals tools](https://learn.microsoft.com/en-us/sysinternals/) help me diagnose and fix various issues on Windows systems. Most often I use [Process Monitor](https://learn.microsoft.com/en-us/sysinternals/downloads/procmon) to capture and analyze system events, and sometimes that's the only tool I need to solve the problem! Other Sysinternals tools that I frequently use are [DebugView](https://learn.microsoft.com/en-us/sysinternals/downloads/debugview), [ProcDump](https://learn.microsoft.com/en-us/sysinternals/downloads/procdump), and [LiveKd](https://learn.microsoft.com/en-us/sysinternals/downloads/livekd). There are many other Sysinternals tools I use daily, such as . You can get the entire suite or individual tools from the [SysInternals website](https://learn.microsoft.com/en-us/sysinternals/downloads/) or from [live.sysinternals.com](https://live.sysinternals.com). However, these methods require to manually update the tools when new versions are available. A more convenient way to keep the tools up to date is to install them from [Microsoft Store](https://www.microsoft.com/store/apps/9p7knl5rwt25).


To get the most out of Process Monitor and Process Explorer, you need to set up symbol resolution correctly. The default settings do not use the Microsoft symbol store, so you need to adjust them in the options or import the registry keys shown below (after installing Debugging Tools for Windows):

```
[HKEY_CURRENT_USER\Software\Sysinternals\Process Explorer]
"DbgHelpPath"="C:\\Program Files (x86)\\Windows Kits\\10\\Debuggers\\x64\\dbghelp.dll"
"SymbolPath"="SRV*C:\\symbols\\dbg*http://msdl.microsoft.com/download/symbols"

[HKEY_CURRENT_USER\Software\Sysinternals\Process Monitor]
"DbgHelpPath"="C:\\Program Files (x86)\\Windows Kits\\10\\Debuggers\\x64\\dbghelp.dll"
"SymbolPath"="SRV*C:\\symbols\\dbg*http://msdl.microsoft.com/download/symbols"
```

## Configuring post-mortem debugging

We all experience application failures from time to time. When it happens, Windows collectes some data about a crash and saves it to the event log. It usually lacks details required to fully understand the root cause of an issue. Fortunately, we have options to replace this scarse report with, for example, a memory dump. One way to accomplish that is by configuring **Windows Error Reporting** . The commands below will enable minidump collection to a C:\Dumps folder on a process failure:

```shell
reg.exe add "HKLM\Software\Microsoft\Windows\Windows Error Reporting\LocalDumps" /v DumpType /t REG_DWORD /d 1 /f
reg.exe add "HKLM\Software\Microsoft\Windows\Windows Error Reporting\LocalDumps" /v DumpFolder /t REG_EXPAND_SZ /d C:\dumps /f
```

The available settings are listed and explained in the [WER documentation](https://learn.microsoft.com/en-us/windows/win32/wer/collecting-user-mode-dumps). Note, that by creating a subkey with an application name (for example, `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps\test.exe`), you may customize WER settings per individual applications.

[ProcDump](https://learn.microsoft.com/en-us/sysinternals/downloads/procdump) is an alternative to WER. You could install it as an [automatic debugger](https://learn.microsoft.com/en-us/windows/win32/debug/configuring-automatic-debugging), which Windows will run whenever a critical error occurs in an application. Example install command (-u to uninstall):

```
procdump -i C:\Dumps
```

These dumps can take up a lot of disk space over time, so you should either delete the old files periodically, or set up a task scheduler job that does it for you.

## Installing ETW tools

The last set of utilities I want to mention in this guide are tools for working with [Event Tracing for Windows (ETW)](https://learn.microsoft.com/en-us/windows-hardware/drivers/devtest/event-tracing-for-windows--etw-). Using ETW traces is a powerful way to learn how the system and processes operate. **Windows Performance Toolkit**, available as part of the [Windows SDK](https://developer.microsoft.com/en-us/windows/downloads/windows-sdk/), includes collectors such as xperf.exe and wpr.exe, as well as viewers like wpa.exe. It has a bit steep learning curve, so you may also want to check out [PerfView](https://github.com/microsoft/perfview/releases), [UIforETW](https://github.com/google/UIforETW/releases), and [wtrace](https://github.com/lowleveldesign/wtrace/releases) (especially the last one!) which provide more approachable interface to ETW events collection and analysis in the supported troubleshooting scenarios.
