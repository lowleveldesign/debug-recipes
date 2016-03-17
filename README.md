
Debug Recipes
=============

This is a repository of my notes collected while debugging various .NET and Windows problems. You can find here commands with example usages, scripts and other debugging materials.  It is still being constructed so some notes might not be finished - use on your own responsiblity. Try using the project search box while looking for a particular subject.

I hope you will find them useful. Any contribution is welcome.

------------------------------------

Recipes grouped by types of problems
------------------------------------

### Memory issues

- [CLR Memory model](memory/clr-memory.md)
- [Investigate .NET memory issues in dumps](dumps/dotnet-process-memory-dumps.md)
- [Diagnose native memory leaks](memory/native-memory-leaks.md)

### Threading problems

- [Analysing locks in .NET](threading/analysing-locks-in-net.md)

### Network issues

- [Collect and analyze network traces](network/network-tracing.md)
- [Identify network problems in memory dumps](network/network-problems-in-dumps.md)
- [Diagnosing faulty HTTP requests](network/network-faulty-http-requests.md)

### Exceptions

- [Collecting exception information in production](exceptions/collecting-exceptions-info.md)
- [Analyzing exceptions](exceptions/analyzing-exceptions.md)
- [Windows Error Reporting](exceptions/wer/wer-usage.md)
- [Aedebug](exceptions/aedebug/aedebug.md)
- [Adplus usage](exceptions/adplus/adplus.md)
- [DebugDiag](exceptions/debugdiag/debugdiag.md)

### Diagnosing ASP.NET

- [Debugging ASP.NET applications](asp.net/asp.net-debugging.md)
- [Profiling ASP.NET applications](asp.net/asp.net-profiling.md)
- [Troubleshooting IIS](asp.net/iis-troubleshooting.md)

### Diagnosing Nancy

- [Diagnosing Nancy applications](nancy/nancy-diagnostics.md)

### Troubleshooting IIS

- [Troubleshooting IIS 6](iis/iis6.md)
- [Troubleshooting IIS 7 and newer](iis/iis7up.md)
- [Troubleshooting IIS Express](iis/iisexpress.md)
- [IIS WMI API](iis/wmi/iis-wmi.md)
- [Other resources (including Powershel LLDIIS module)](iis/README.md)

### Diagnosing ADO.NET

- [ETW tracing in ADO.NET](ado.net/ado.net-etw-tracing.md)
- [Debugging ADO.NET](ado.net/ado.net-debugging.md)

### Diagnosing problems with .NET assmeblies

- [.NET assemblies - some general info](assemblies/clr-assemblies.md)
- [Troubleshooting assemblies loading](assemblies/clr-troubleshooting-assembly-loading.md)

### General .NET & Windows

- [.NET version/GAC/caspol](clr-information.md)
- [JIT configuration for debugging](jit-configuration-for-debugging.md)
- [Windows debugging configuration](windows-debugging-configuration.md)
- [PDB files](pdb-files.md)

### Troubleshooting databases

- [MS SQL Server](databases/mssqlserver/README.md)
- [MySQL](databases/mysql/README.md)

----------------

Tools, libraries & technics
---------------------------

### General

- [How to debug effectively?](howto.md)

### Debugging kernel

- [Debugging Windows kernel - setup](debugging-kernel/windows-kernel-debugging-setup.md)
- [Debugging Windows kernel - basics](debugging-kernel/windows-kernel-debugging.md)

### Memory dumps

- [Collect and analyze process memory dumps](dumps/windows-process-memory-dumps.md)
- [Collect and analyze .NET process memory dumps](dumps/dotnet-process-memory-dumps.md)
- [Collect and analyze kernel memory dumps](dumps/windows-kernel-memory-dumps.md)

### Event Tracing for Windows (ETW)

- [CLR ETW tracing](etw/clr-etw-tracing.md)

### Debuggers

- [Debuging using Visual Studio](debugging-using-vs/README.md)
- [Debugging using mdbg](debugging-using-mdbg/mdbg.exe.md)
- [Debugging in WinDbg - tips](debugging-using-windbg/windbg-debugging.md)
- [Debugging .NET apps using windbg](debugging-using-windbg/windbg-clr-debugging.md)

### Profilers

- [PerfView](profiling-tools/perfview/perfview.exe.md)

### Libraries

- [.NET libraries for app diagnostics](profiling-tools/clr-diaglibs.md)

### Tracing

- [API hooking in Windws](api-hooking.md)

-----

Links
-----

- [.NET Debugging Quick Start -  a list of links for different parts of a .net debugging infrastructure](http://blogs.msdn.com/b/arvindsh/archive/2012/03/14/net-debugging-quick-start.aspx)
- [.NET Debugging for the Production Environment](http://channel9.msdn.com/Series/-NET-Debugging-Stater-Kit-for-the-Production-Environment)
- [.NET Debugging Starter Kit: for the Production Environment - 6 great videos about .NET and native debugging](http://channel9.msdn.com/Series/-NET-Debugging-Stater-Kit-for-the-Production-Environment)
- [Intersting library that binds github sources with solution](https://github.com/GeertvanHorrik/GitHubLink)
- [Defrag Tools #109 - Writing a CLR Debugger Extension Part 1](http://channel9.msdn.com/Shows/Defrag-Tools/Defrag-Tools-109-Writing-a-CLR-Debugger-Extension-Part-1)
- [Defrag Tools #110 - Writing a CLR Debugger Extension Part 2](http://channel9.msdn.com/Shows/Defrag-Tools/Defrag-Tools-110-Writing-a-CLR-Debugger-Extension-Part-2)
