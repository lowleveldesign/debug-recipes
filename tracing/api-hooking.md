
API hooking
===========

Debugging Tools for Windows
---------------------------

We can also enable call tracing in windbg using `logi`, `loge` commands and disable with `logd`.

Logger.exe is based on the debugging API. It allows you to hook into the API calls and so analyze what exactly the application is doing.

Tools
-----

- [IAT Patcher](http://hasherezade.net/IAT_patcher/)
- [API Monitor](http://www.rohitab.com/)
- [SpyStudio](http://linkis.com/www.nektra.com/produ/6f3SS)
- [Frida - hook javascript code into native apps on Windows, Mac, Linux and iOS](http://www.frida.re/)
- [Ntrace - it shows you the calls made through ntdll.dll library](http://www.howzatt.demon.co.uk/NtTrace/)
- [PowerLoaderEx](https://github.com/BreakingMalware/PowerLoaderEx)

Libraries
---------

### C++ ###

- [minhook](https://github.com/TsudaKageyu/minhook)
- [Detours](http://research.microsoft.com/en-us/projects/detours/)
- [EasyHook](http://easyhook.codeplex.com/)
- [Deviare in Process](https://github.com/nektra/Deviare-InProc/)
- [A library for intercepting native functions by hooking KiFastSystemCall](https://github.com/MalwareTech/FstHook)
- [InjectCode - code for injecting remote thread into a process](https://github.com/EvilKnight1986/InjectCode)
- [Blackbone - Windows memory hacking library - has some options to hook code by a remote thread](https://github.com/DarthTon/Blackbone)

### Python ###

- [Spooky-hook.py is an API call hooking tool based on WinAppDbg for the Windows platform](https://github.com/nitram2342/spooky-hook)

Links
-----

- [Research on how to Kaspersky hooks into processes](https://quequero.org/2014/10/kaspersky-hooking-engine-analysis/)
- [Inline Hooking for Programmers (Part 1: Introduction)](http://www.malwaretech.com/2015/01/inline-hooking-for-programmers-part-1.html)
- [Inline Hooking for Programmers (Part 2: Writing a Hooking Engine)](http://www.malwaretech.com/2015/01/inline-hooking-for-programmers-part-2.html?m=1)
- [Injecting a DLL into a process on load time with the ability to hook the process' entrypoint from the DLL](http://www.mulliner.org/blog/blosxom.cgi/windows/dll_injection_with_entrypoint_hook_aslr.html)
- [Injecting code into remote process](http://www.tuxmealux.net/2015/03/10/code-injection/)
- [Automatyzacja analizy złośliwego oprogramowania](http://malware.prevenity.com/2015/03/automatyzacja-analizy-zosliwego.html)
- [Section Based Code Injection and Its Detection](http://standa-note.blogspot.ca/2015/03/section-based-code-injection-and-its.html)
- [Syscall Hooking Under WoW64: Introduction (1/2)](http://www.codereversing.com/blog/archives/243)
- [Syscall Hooking Under WoW64: Implementation (2/2)](http://www.codereversing.com/blog/archives/246)

