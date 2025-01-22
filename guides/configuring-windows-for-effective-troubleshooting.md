---
layout: page
title: Configuring Windows for effective troubleshooting
date: 2023-10-11 08:00:00 +0200
---

**Table of contents:**

<!-- MarkdownTOC -->

- [Configuring debug symbols](#configuring-debug-symbols)
- [Replacing Task Manager with System Informer](#replacing-task-manager-with-system-informer)
- [Installing and configuring Sysinternals Suite](#installing-and-configuring-sysinternals-suite)
- [Configuring post-mortem debugging](#configuring-post-mortem-debugging)

<!-- /MarkdownTOC -->

## Configuring debug symbols

Staring at raw hex numbers is not very helpful for troubleshooting. Therefore, it's essential to take the time to properly configure debug symbols on our system. One effective method is to set the **\_NT\_SYMBOL\_PATH** environment variable. Most troubleshooting tools read its value and utilize the specified symbol stores. I usually configure it to point only to the official Microsoft symbol server, resulting in the following value for the \_NT\_SYMBOL\_PATH variable on my system: `SRV*C:\symbols\dbg*https://msdl.microsoft.com/download/symbols`. Here, `C:\symbols` serves as a cache folder for storing downloaded symbols. I also use `C:\symbols\dbg` if I need to index PDB files for my applications. For further information about the \_NT\_SYMBOL\_PATH variable, refer to [the official documentation](https://learn.microsoft.com/en-us/windows-hardware/drivers/debugger/symbol-path).

The symbol path variable is one essential component required for successful symbol resolution. Another critical aspect is the version of **dbghelp.dll** that can work with symbol servers. Unfortunately, the version preinstalled with Windows lacks this feature. To overcome this issue, you can install the **Debugging Tools for Windows** from the [Windows SDK](https://developer.microsoft.com/en-us/windows/downloads/windows-sdk/). Make sure to install both the x86 and x64 versions to enable debugging of both 32- and 64-bit applications. Once installed, certain tools (e.g., Symbol Informer) will automatically select the appropriate dbghelp.dll version, while others will require some configuration, as we'll explore in later sections.

## Replacing Task Manager with System Informer

My long time favorite tool to observe system and processes running on it, is [System Informer](https://www.systeminformer.com/), formerly known as Process Hacker. It has so many great features that deserves a guide on its own. The process tree, which shows the process creation and termination events, is much more readable than the flat process list in Task Manager or Resource Monitor. Moreover, System Informer lets you manage services and drivers, and view live network connections. Therefore, I highly recommend to open the Options dialog and replace Task Manager with it. System Informer does not have an option to set the dbghelp.dll path in its settings, but it will detect it if you have Debugging Tools for Windows installed. So please install them to have Windows stacks correctly resolved.

If you have reasons not to use System Informer, you can try [Process Explorer](https://learn.microsoft.com/en-us/sysinternals/downloads/process-explorer). It does not have as many functionalities as System Informer, but it is still a powerful system monitor.

## Installing and configuring Sysinternals Suite

[Sysinternals tools](https://learn.microsoft.com/en-us/sysinternals/) help me diagnose and fix various issues on Windows systems. Most often I use [Process Monitor](https://learn.microsoft.com/en-us/sysinternals/downloads/procmon) to capture and analyze system events, and sometimes that's the only tool I need to solve the problem! Other Sysinternals tools that I frequently use are [DebugView](https://learn.microsoft.com/en-us/sysinternals/downloads/debugview), [ProcDump](https://learn.microsoft.com/en-us/sysinternals/downloads/procdump), and [LiveKd](https://learn.microsoft.com/en-us/sysinternals/downloads/livekd). You can get the entire suite or individual tools from the [SysInternals website](https://learn.microsoft.com/en-us/sysinternals/downloads/) or from [live.sysinternals.com](https://live.sysinternals.com). However, these methods require manual updates when new versions are available. A more convenient way to keep the tools up to date is to install them from [Microsoft Store](https://www.microsoft.com/store/apps/9p7knl5rwt25).

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

```shell
procdump -i C:\Dumps
```

These dumps can take up a lot of disk space over time, so you should either delete the old files periodically, or set up a task scheduler job that does it for you.
