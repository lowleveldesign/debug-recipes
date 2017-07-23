
CLR general debugging tips
==========================

In this recipe:

- [CLR debugging in WinDbg](#clrwindbg)
- [Controlling JIT optimization](#jitoptimization)
- [Check framework version](#frameworkversion)
- [CLR Code Policies](#codepolicies)

## <a name="clrwindbg">CLR debugging in WinDbg</a>

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

## <a name="jitoptimization">Controlling JIT optimization</a>

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

## <a name="frameworkversion">Check framework version</a>

### Of running application or installed in the system ###

Show version of the framework loaded by a process with PID 5772:

    C:>clrver 5772
    v2.0.50727

Show installed framework versions:

    C:>clrver
    Versions installed on the machine:
    v2.0.50727
    v4.0.30319

Display all processes on the machine with their loaded framework versions:

    C:>clrver -all
    5772    Program.exe             v2.0.50727

### In memory dump or installed in the system ###

For .NET2.0 you could check the version of mscorwks in the file properties or, if in debugger, using lmmv:

    0:000> lmv m mscorwks
    start             end                 module name
    00000642`7f330000 00000642`7fcdc000   mscorwks   (deferred)
        Image path: C:\WINDOWS\Microsoft.NET\Framework64\v2.0.50727\mscorwks.dll
        Image name: mscorwks.dll
        Timestamp:        Wed May 12 00:13:32 2010 (4BEA38FC)
        CheckSum:         0099D95F
        ImageSize:        009AC000
        File version:     2.0.50727.4455
        Product version:  2.0.50727.4455
        File flags:       0 (Mask 3F)
        File OS:          4 Unknown Win32
        File type:        2.0 Dll
        File date:        00000000.00000000
        Translations:     0409.04b0
        CompanyName:      Microsoft Corporation
        ProductName:      Microsoft .NET Framework
        InternalName:     mscorwks.dll
        OriginalFilename: mscorwks.dll
        ProductVersion:   2.0.50727.4455
        FileVersion:      2.0.50727.4455 (QFE.050727-4400)
        FileDescription:  Microsoft .NET Runtime Common Language Runtime - WorkStation
        LegalCopyright:   Š Microsoft Corporation.  All rights reserved.
        Comments:         Flavor=Retail

For .NET4.x you need to check clr.dll (or the Release value under the `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full` key) and make use of the table below. Available .NET 4 Framework versions:

.NET Version | Clr.dll Build 4.0.30319.{build}
-------------|-----------------------------------
.NET 4.0     | 4.0.30319.0 to 4.0.30319.17000
.NET 4.5     | 4.0.30319.17001 to 4.0.3019.19000
.NET 4.5.1   | 4.0.3019.19001 to 4.0.30319.34000
.NET 4.5.2   | 4.0.30319.34000 to 4.0.30319.393295
.NET 4.6     | 4.0.30319.393295 (Windows 10) or 4.0.30319.393297 (All other OS versions)
.NET 4.6.1   | 4.0.30319.394256

## <a name="codepolicies">CLR Code Policies</a>

List groups:

    caspol -l

Remove groups

    caspol remgroup 1.1.2.


Add FullTrust for a given path:

    caspol -m -q -ag All_Code -url c:\panel\bin\* FullTrust

To analyze policies applied to the assembly you may run (according to <http://msdn.microsoft.com/en-us/library/vstudio/tx1dts55(v=vs.100).aspx>):

    caspol all resolveperm assembly-file

    caspol enterprise resolveperm assembly-file
    caspol machine resolveperm assembly-file
    caspol user resolveperm assembly-file

