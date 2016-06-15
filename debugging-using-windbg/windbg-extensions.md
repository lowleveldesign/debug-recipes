
Windbg extensions
=================

Extensions for managed debugging
--------------------------------

### SOSEX ###

From <http://www.stevestechspot.com/>

Great extension with a log of useful commands for .NET debugging. More [here](windbg-clr-debugging.md).

### Netext ###

.NET plugin for WinDbg with interesting commands: <http://netext.codeplex.com/>. Some articles about it:

- <http://blogs.msdn.com/b/rodneyviana/archive/2013/10/30/hardcore-debugging-for-net-developers-not-for-the-faint-of-heart.aspx>
- [Getting started with NetExt](http://blogs.msdn.com/b/rodneyviana/archive/2015/03/10/getting-started-with-netext.aspx)
- [The case of the non-responsive MVC Web Application](http://blogs.msdn.com/b/rodneyviana/archive/2015/03/27/the-case-of-the-non-responsive-mvc-web-application.aspx)
- [Debugging - NetExt WinDbg Extension](http://www.debugthings.com/2015/03/31/netext-windbg/)
- [NetExt – SOS on steroids](https://lowleveldesign.wordpress.com/2015/07/09/netext-sos-on-steroids/)

### SOSWOW64 ###

From: <https://github.com/poizan42/soswow64>

Makes SOS work on 64-bit dumps taken from a 32-bit processes on Win64.

Extensions for managed and native debugging
-------------------------------------------

### PDE ###

from [Andrew Richard's onedrive](https://onedrive.live.com/?authkey=!AJeSzeiu8SQ7T4w&id=DAE128BD454CF957!7152&cid=DAE128BD454CF957)

A lot of very useful commands which make work with the process memory much easier. An extract of the help can be found [here](pde.help.txt).

### Python extension for WinDbg ###

from <http://pykd.codeplex.com/>

There is also an UI for pykd: <https://karmadbg.codeplex.com/>

Scripts:

- [vtfinder - script to dynamically find vtables on heap](https://github.com/iSECPartners/vtfinder)
- [Heap tracing with WinDbg and Python](https://labs.mwrinfosecurity.com/blog/heap-tracing-with-windbg-and-python/)

### SwishDbgExt ###

from <http://www.msuiche.net/?wpdmact=process&did=MS5ob3RsaW5r>

SwishDbgExt aims at making life easier for kernel developers, troubleshooters and security experts with a series of debugging, incident response and memory forensics commands.

Links:

- [That’s so Swish !](http://www.msuiche.net/2014/07/16/thats-so-swish/)
- [SwishDbgExt: Update (0.6.20140817)](http://www.msuiche.net/2014/08/19/swishdbgext-update-0-6-20140817/)
- [SwishDbgExt - source code](https://github.com/msuiche/SwishDbgExt)

### DbgKit ###

<http://www.andreybazhan.com/dbgkit.html>

DbgKit is the first GUI extension for Debugging Tools for Windows (WinDbg, KD, CDB, NTSD). It will show you hierarchical view of processes and detailed information about each process including its full image path, command line, start time, memory statistics, vads, handles, threads, security attributes, modules, environment variables and more.

### !exploitable ###

<https://msecdbg.codeplex.com/>

!exploitable (pronounced “bang exploitable”) is a Windows debugging extension (Windbg) that provides automated crash analysis and security risk assessment. The tool first creates hashes to determine the uniqueness of a crash and then assigns an exploitability rating to the crash: Exploitable, Probably Exploitable, Probably Not Exploitable, or Unknown.

Other extensions
----------------

- [PSExt - Powershell extension for WinDbg](https://github.com/powercode/PSExt/blob/master/README.md)
- [Dumpfiles - extension to extract file from Cache Manager](https://github.com/JumpCallPop/dumpfiles)
- [Extensions by Sasha Goldstein: tracer, wct, heap\_stat.py, bkb.py, traverse\_map.py, traverse\_vector.py](https://github.com/goldshtn/windbg-extensions)
- [wdbgark - an extension to analyze anomalies in Windows kernel using kernel debugger](https://github.com/swwwolf/wdbgark/blob/master/README.md)
- [DmpExt - crash dump analysis](http://crashdmp.wordpress.com/2014/10/08/dmpext-windbg-extension/)

Developing extensions
---------------------

Sample Windbg extension to recurse, filter and pipe commands: <http://blogs.msdn.com/b/nicd/archive/2008/12/18/windbg-extension-to-easily-recurse-filter-and-pipe-commands.aspx>. There is also some interesting extensions written by Nynaeve at <http://www.nynaeve.net/?page_id=240>.

Tutorial on writing WinDbg extensions (using exteng):

- <http://www.msuiche.net/2014/01/12/extengcpp-part-1/>
- <http://www.msuiche.net/2014/01/15/developing-windbg-extengcpp-extension-in-c-com-interface/>
- <http://www.msuiche.net/2014/01/20/developing-windbg-extengcpp-extension-in-c-memory-debugger-markup-language-dml-part-3/>
- <http://www.msuiche.net/2014/04/28/developing-windbg-extengcpp-extension-in-c-symbols-part-4/>

Tutorial on writing WinDbg extensions (using dbgeng):

- [Debugger APIs - Writing a Debugging Tools for Windows Extension](https://msdn.microsoft.com/en-us/magazine/gg650659.aspx)
- [Debugger Engine API - Writing a Debugging Tools for Windows Extension, Part 2: Output](https://msdn.microsoft.com/en-us/magazine/hh148143.aspx)
- [Debugger Engine API - Writing a Debugging Tools for Windows Extension, Part 3: Clients and Callbacks](https://msdn.microsoft.com/en-us/magazine/hh205613.aspx)

A series on Defrag show how to write a WinDbg extension:

- <http://channel9.msdn.com/Shows/Defrag-Tools/Defrag-Tools-96-Writing-a-Debugger-Extension-Part-1>
- <http://channel9.msdn.com/Shows/Defrag-Tools/Defrag-Tools-97-Writing-a-Debugger-Extension-Part-2>
- <http://channel9.msdn.com/Shows/Defrag-Tools/Defrag-Tools-98-Writing-a-Debugger-Extension-Part-3>
- <http://channel9.msdn.com/Shows/Defrag-Tools/Defrag-Tools-99-Writing-a-Debugger-Extension-Part-4>
- <http://channel9.msdn.com/Shows/Defrag-Tools/Defrag-Tools-101-Writing-a-Debugger-Extension-Part-5>
- <http://channel9.msdn.com/Shows/Defrag-Tools/Defrag-Tools-102-Writing-a-Debugger-Extension-Part-6>
- <http://channel9.msdn.com/Shows/Defrag-Tools/Defrag-Tools-103-Writing-a-Debugger-Extension-Part-7>
- <http://channel9.msdn.com/Shows/Defrag-Tools/Defrag-Tools-104-Writing-a-Debugger-Extension-Part-8>
- <http://channel9.msdn.com/Shows/Defrag-Tools/Defrag-Tools-105-Writing-a-Debugger-Extension-Part-9>

How to write WinDbg extensions in C#:

- [Defrag Tools #109 - Writing a CLR Debugger Extension Part 1](https://channel9.msdn.com/Shows/Defrag-Tools/Defrag-Tools-109-Writing-a-CLR-Debugger-Extension-Part-1)
- [Defrag Tools #110 - Writing a CLR Debugger Extension Part 2](https://channel9.msdn.com/Shows/Defrag-Tools/Defrag-Tools-110-Writing-a-CLR-Debugger-Extension-Part-2)
- [WinDBG Extension written completely in C#](https://blogs.msdn.microsoft.com/rodneyviana/2016/05/18/windbg-extension-written-completely-in-c/)
