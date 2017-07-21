
CLR general debugging tips
==========================

CLR debugging in WinDbg
-----------------------

### Loading SOS ###

You may use a great WinDbg plugin (**procdumpext**) by Andrew Richards for loading SOS:

```
0:000> .load c:\tools\diagnosing\Debugging Tools for Windows\_winext-x64\ProcDumpExt.dll
=========================================================================================
 ProcDumpExt v6.4 - Copyright 2013 Andrew Richards
=========================================================================================
0:000> !loadsos
```

However, recently I usually use any command from **netext** (eg. **!wver**) and make it load sos automatically, eg.:

```
0:000> .load netext
...
0:000> !wver
Runtime(s) Found: 1
0: Filename: mscordacwks_Amd64_Amd64_4.6.1080.00.dll Location: C:\Windows\Microsoft.NET\Framework64\v4.0.30319\mscordacwks.dll
.NET Version: v4.6.1080.00
NetExt (this extension) Version: 2.1.2.5000
0:000> .chain
Extension DLL search Path:
...
Extension DLL chain:
    netext: image 2.1.2.5000, API 1.0.0, built Thu Jan 21 17:33:00 2016
        [path: C:\tools\diag\Debugging Tools for Windows\_winext-x64\netext.dll]
    C:\Windows\Microsoft.NET\Framework64\v4.0.30319\SOS.dll: image 4.6.1080.0, API 1.0.0, built Tue Apr 12 03:02:38 2016
        [path: C:\Windows\Microsoft.NET\Framework64\v4.0.30319\sos.dll]
...
```

### Get help for commands in .NET WinDbg extensions ###

SOS commands sometimes get overriden by other extensions help files. In such a case just use `!sos.help <cmd>` command, eg.

    0:000> !sos.help !savemodule
    -------------------------------------------------------------------------------
    !SaveModule <Base address> <Filename>
    ...

SOSEX help can be seen using the `!sosexhelp [command]` command.

Netext help can be nicely rendered in the command window: `.browse !whelp`.

### Problems while loading mscordacwks.dll ###

Here are some links you may check in case you run into problems with mscordacwks:

- [Obtaining mscordacwks.dll for CLR Versions You Don't Have](http://blogs.microsoft.co.il/blogs/sasha/archive/2012/05/19/obtaining-mscordacwks-dll-for-clr-versions-you-don-t-have.aspx)
- [Automatically Load the Right SOS for the Minidump](http://www.wintellect.com/blogs/jrobbins/automatically-load-the-right-sos-for-the-minidump)
- [Failed to load data access DLL, 0x80004005 – OR – What is mscordacwks.dll?](http://blogs.msdn.com/b/dougste/archive/2009/02/18/failed-to-load-data-access-dll-0x80004005-or-what-is-mscordacwks-dll.aspx)
- [How to load the specified mscordacwks.dll for managed debugging when multiple .NET runtime are loaded in one process](http://blogs.msdn.com/b/asiatech/archive/2010/09/10/how-to-load-the-specified-mscordacwks-dll-for-managed-debugging-when-multiple-net-runtime-are-loaded-in-one-process.aspx)
- [Obtaining mscordacwks.dll for CLR Versions You Don’t Have](http://blogs.microsoft.co.il/blogs/sasha/archive/2012/05/19/obtaining-mscordacwks-dll-for-clr-versions-you-don-t-have.aspx)
- [[PL] Rozwiązywanie problemów z mscordacwks](http://zine.net.pl/blogs/mgrzeg/archive/2014/01/15/rozwi-zywanie-problem-w-z-mscordacwks.aspx)
- [Mscordacwks/SOS debugging archive - a list of all versions of mscordacwks and SOS](http://www.sos.debugging.wellisolutions.de/)

Controlling JIT optimization
----------------------------

Assemblies can be compiled as optimized - JIT compiler takes `DebuggableAttribute` into consideration while generating the native code to execute.

### DebuggableAttribute ###

The definition of the `DebuggingModes` flag sent to the constructor:

    [Flags]
    [ComVisible(true)]
    public enum DebuggingModes
    {
        None = 0x0,
        Default = 0x1,
        DisableOptimizations = 0x100,
        IgnoreSymbolStoreSequencePoints = 0x2,
        EnableEditAndContinue = 0x4
    }

**/debug:full /optimize-**

    [mscorlib]System.Diagnostics.DebuggableAttribute/DebuggingModes) = ( 01 00 07 01 00 00 00 00 )

    0x0107 = DisableOptimization | EnableEditAndContinue | IgnoreSymbolStoreSequencePoints | Default

**/debug:full /optimize+**

    [mscorlib]System.Diagnostics.DebuggableAttribute/DebuggingModes) = ( 01 00 03 00 00 00 00 00 )

    0x0003 = IgnoreSymbolStoreSequencePoints | Default

**/debug:pdbonly /optimize-**

    [mscorlib]System.Diagnostics.DebuggableAttribute/DebuggingModes) = ( 01 00 02 01 00 00 00 00 )

    0x0102 = DisableOptimization | IgnoreSymbolStoreSequencePoints

**/debug:pdbonly /optimize+**

    [mscorlib]System.Diagnostics.DebuggableAttribute/DebuggingModes) = ( 01 00 02 00 00 00 00 00 )

    0x0002 = IgnoreSymbolStoreSequencePoints

**<none>**

No Debuggable attribute emitted

### INI file ###

The ini file must have the same name as the executable with only extension changed to ini, eg. my.ini file will work with my.exe application.

    [.NET Framework Debugging Control]
    GenerateTrackingInfo=1
    AllowOptimize=0

