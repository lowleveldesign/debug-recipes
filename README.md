
Debug Recipes
=============

This is a repository of my notes collected while debugging various .NET and Windows problems. You can find here commands with example usages, scripts and other debugging materials.  It is still being constructed so some notes might not be finished - use on your own responsiblity. Try using **the project search box** while looking for a particular subject.

I hope you will find them useful. Any contribution is welcome.

## General advice

Make sure you have [valid symbols configuration](windows-debugging-configuration.md) in your system. You may also have a look at a list of my [debugging tips](howto.md). If you are debugging a .NET application you may first [make some adjustments in the JIT configuration](jit-configuration-for-debugging.md).

## What is the problem about?

Columns: "Type of a faulty application"
Rows: "Type of a problem"

|    | ASP.NET | Nancy | .NET console/windows |
| -- | ------- | ----- | ---------------------|
| Exception | X | X | X |
| Memory leak | X | X | X |
| High CPU usage | X | X | X |
| Deadlocks | X | X | X |
| Slow database queries | X | X | X |
| Slow requests | X | X | |

### Databases

|    | MS SQL Server | MySQL |
| -- | ------------- | ----- |
| FIXME

## Tools tutorials

- [Visual Studio (debugging)](debugging-using-vs/README.md) |
- [mdbg (debugger)](debugging-using-mdbg/mdbg.exe.md) |
- [WinDbg (debugger)](debugging-using-windbg/windbg-debugging.md) |
- [PerfView (profiler)](profiling-tools/perfview/perfview.exe.md)



### Obsolete


| [.NET version/GAC/caspol](clr-information.md) |

- [Debugging .NET apps using windbg](debugging-using-windbg/windbg-clr-debugging.md) |



| Exceptions | Memory issues | Threading problems |
| --- | --- | ---
| [Collecting exception information in production](exceptions/collecting-exceptions-info.md) | [CLR Memory model](memory/clr-memory.md) | [Analysing locks in .NET](threading/analysing-locks-in-net.md)
| [Analyzing exceptions](exceptions/analyzing-exceptions.md) | [Investigate .NET memory issues in dumps](dumps/dotnet-process-memory-dumps.md) |
| [Windows Error Reporting](exceptions/wer/wer-usage.md) | [Diagnose native memory leaks](memory/native-memory-leaks.md) |
| [Aedebug](exceptions/aedebug/aedebug.md) | | |
| [Adplus usage](exceptions/adplus/adplus.md) | | |
| [DebugDiag](exceptions/debugdiag/debugdiag.md) | | |


| Network issues | .NET Assemblies |
| --- | --- |
| [Collect and analyze network traces](network/network-tracing.md) | [.NET assemblies - some general info](assemblies/clr-assemblies.md) |
| [Identify network problems in memory dumps](network/network-problems-in-dumps.md) | [Troubleshooting assemblies loading](assemblies/clr-troubleshooting-assembly-loading.md) |
| [Diagnosing faulty HTTP requests](network/network-faulty-http-requests.md) | |


### Tools, libraries & technics

| IIS | ASP.NET | Nancy
| --- | --- | ---
| [Troubleshooting IIS 6](iis/iis6.md) | [Debugging ASP.NET applications](asp.net/asp.net-debugging.md) | [Diagnosing Nancy applications](nancy/nancy-diagnostics.md)
| [Troubleshooting IIS 7 and newer](iis/iis7up.md) | [Profiling ASP.NET applications](asp.net/asp.net-profiling.md) |
| [Troubleshooting IIS Express](iis/iisexpress.md) | [Troubleshooting IIS](asp.net/iis-troubleshooting.md) |
| [IIS WMI API](iis/wmi/iis-wmi.md) | | |
| [Other resources (including Powershel LLDIIS module)](iis/README.md) | | |

| ADO.NET | Diagnostics libraries |
| --- | ---
| [ETW tracing in ADO.NET](ado.net/ado.net-etw-tracing.md) | [.NET libraries for app diagnostics](profiling-tools/clr-diaglibs.md)
| [Debugging ADO.NET](ado.net/ado.net-debugging.md) | [API hooking in Windws](api-hooking.md)

### HOWTOs

| Debugging kernel | Memory dumps | Event Tracing for Windows (ETW) |
| --- | --- | --- |
| [Debugging Windows kernel - setup](debugging-kernel/windows-kernel-debugging-setup.md) | [Collect and analyze process memory dumps](dumps/windows-process-memory-dumps.md) | [CLR ETW tracing](etw/clr-etw-tracing.md) |
| [Debugging Windows kernel - basics](debugging-kernel/windows-kernel-debugging.md) | [Collect and analyze .NET process memory dumps](dumps/dotnet-process-memory-dumps.md) | |
| | [Collect and analyze kernel memory dumps](dumps/windows-kernel-memory-dumps.md) | |

