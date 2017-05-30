
Debugging .NET using WinDbg
===========================

I prepared a cheatsheet for most common WinDbg commands used to diagnose managed application. You may get it [here](windbg-clr-cheatsheet.pdf). I also published a more detailed tutorial on Debugging .NET with WinDbg, which you may find on [my Google Drive](https://docs.google.com/document/d/1yMQ8NAQZEBtsfVp7AsFLSA_MkIKlYNuSowG72_nU0ek).

CLR debugging setup
-------------------

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

For you convenience I also extracted the text help files from those extensions: [SOS](sos.help.txt), [SOSEX](sosex.help.txt), [netext](netext.help.txt).

Usage examples
--------------

### Save a module from a dump (!savemodule) [SOS] ###

    !SaveModule <Base address> <Filename>

This command allows you to save a module from a memory dump to a disk. The base address can be found by using `lm` command. Example:

    0:000> lm
    start    end        module name
    00d50000 00d96000   log4net    (deferred)
    00e70000 00e7e000   Products_Service   (deferred)
    ...
    0:000> !SaveModule 00e70000 c:\temp\Products.Service.dll
    3 sections in file
    section 0 - VA=2000, VASize=66e4, FileAddr=200, FileSize=6800
    section 1 - VA=a000, VASize=3b0, FileAddr=6a00, FileSize=400
    section 2 - VA=c000, VASize=c, FileAddr=6e00, FileSize=200

To save all modules in a given dump you may use **!for\_each\_module** command:

    !for_each_module !savemodule @#Base C:\path_to_save\${@#ModuleName}.dll

### Break when specific exception occurs [SOS] ###

Break when `NullReferenceException` is thrown:

    !sxe -c "!soe System.NullReferenceException 1;.if (@$t1 != 1) { g; }" clr

### Find a value of a static field [SOSEX,Netext] ###

In **SOSEX** you might just call `!mdt <MT-address>` and the static class fields will be shown.

If you have an instance of a given type, the `!wdo` command from **netext** will show static fields values next to the instance fields values.

In SOS you need to first find the EEClass address for a given type (by calling for instance `!DumpMT`) and then use `!DumpClass`:

    0:000> !DumpClass /d 00c1af5c
    Class Name:      LowLevelDesign.Diagnostics.Musketeer.Config.SharedInfoAboutApps
    mdToken:         02000011
    File:            c:\tools\musketeer\Musketeer.exe
    Parent Class:    698239a4
    Module:          002c2edc
    Method Table:    00be97c0
    Vtable Slots:    9
    Total Method Slots:  b
    Class Attributes:    100101
    Transparency:        Critical
    NumInstanceFields:   4
    NumStaticFields:     2
          MT    Field   Offset                 Type VT     Attr    Value Name
    689a45c8  4000044        4 ...derWriterLockSlim  0 instance           lck
    0359001c  4000045        8 ...Info, Musketeer]]  0 instance           appPathToAppInfoMap
    03590440  4000046        c ...eer]], mscorlib]]  0 instance           workerProcessIdToAppInfoMap
    035907fc  4000047       10 ...eer]], mscorlib]]  0 instance           logsPathToAppInfoMap
    69c23e18  4000042       40        System.String  0   static 00e21598 MachineName
    69be0cbc  4000043       44      System.Object[]  0   static 00e215b0 NoApps

### Find a type or method ###

We may use the `!mx <Filter String>` command from **SOSEX**, eg.:

    0:005> !mx *TestWorker
    AppDomain 74c76670 (Shared Domain)
    ---------------------------------------------------------

    AppDomain 00483040 (TopshelfHang.exe)
    ---------------------------------------------------------
    module: TopshelfHang
      class: TopshelfHang.TestWorker

Another option is the `!Name2EE` command from **SOS**, eg.:

    0:000> !Name2EE * System.Diagnostics.EventLog.SourceExists
    ...
    --------------------------------------
    Module: 000007fc0d741000 (System.Configuration.dll)
    --------------------------------------
    Module: 000007fbff201000 (System.dll)
    Token: 0x00000000060038fd
    MethodDesc: 000007fbff308070
    Name: System.Diagnostics.EventLog.SourceExists(System.String)
    JITTED Code Address: 000007fbff996ec0
    -----------------------
    Token: 0x00000000060038fe
    MethodDesc: 000007fbff308090
    Name: System.Diagnostics.EventLog.SourceExists(System.String, System.String)
    JITTED Code Address: 000007fbff996d70
    --------------------------------------
    ...

### Show GC roots for all objects found with !wfrom [Netext] ###

Example for dumping GC roots for IP address objects:

    .foreach (t { !wfrom -nofield -nospace -type System.Net.IPAddress select $addr(); }) { !GCRoot ${t} }

### Dump all objects with thin locks set ###

Thin lock is set on a object if the object header hasn't been used and we call `Monitor.Enter` on this object. The thin lock in this case contains the thread id which acquired the object. To dump all the objects from the heap with the thin locks use the `!DumpHeap -thinlock` command.

Work with types
--------------

### Decode a value object (eg. DateTime, TimeSpan, Guid) ###

The `!wdo` command from netext nicely decode Guids. If necessary you may use the `!weval` and `$toguid` function. Also the `!mdt <addr>` command from **SOSEX** is very good at decoding value objects.

For datetime you may also use the `dateData` field value and `!weval` function (netext):

```
0:023> !weval $tickstodatetime(0n634915192800000000)
calculated: 2012-12-19 13:08:00
```
For timestamps copy the `_ticks` field and use `!weval`:

```
0:023> !weval $tickstotimespan(0xb2d05e00)
calculated: 00:05:00
```

Powershell:

```powershell
> new-object System.DateTime 634915192800000000

19 grudnia 2012 13:08:00
```

If you only have the address of the value object, dump it with `!wdo -mt <MT> <addr>` or `!mdt <MT> <addr>`, eg.:

```
0:023> !wdo -mt 000007fef84d9360 000000042b700da8
...
Assembly Name: C:\Windows\Microsoft.Net\assembly\GAC_64\mscorlib\v4.0_4.0.0.0__b77a5c561934e089\mscorlib.dll
Inherits: System.ValueType System.Object (000007FEF84D3390 000007FEF84D13E8)
000007fef84eb350                                     System.Int64 +0000                                   _ticks b2d05e00 (0n3000000000)
...
```

### Dump MemoryCache content ###

select memory cache stores: `!wfrom -type System.Runtime.Caching.MemoryCache select _stores`

for each store choose buckets: `!wselect _entries.buckets from {store-addr}`

for each found bucket: `!wselect key._key,val._value.m_value from {bucket-addr}`

Links
-----

- [Identifying Specific Reference Type Arrays with SOS](http://blogs.microsoft.co.il/sasha/2014/05/01/identifying-specific-reference-type-arrays-sos/)
- [A Motivating Example of WinDbg Scripting for .NET Developers](http://blogs.microsoft.co.il/sasha/2014/08/05/motivating-example-windbg-scripting-net-developers/)
- [How to display a DateTime in WinDbg using SOS](http://blogs.iis.net/carlosag/archive/2014/10/24/how-to-display-a-datetime-in-windbg-using-sos.aspx)
- [Andrew Richard's onedrive](https://onedrive.live.com/?authkey=!AJeSzeiu8SQ7T4w&id=DAE128BD454CF957!7152&cid=DAE128BD454CF957)
- [Using SoS to debug 32-bit code in a 64-bit dump with WinDbg](https://poizan.dk/blog/2015/10/15/using-sos-to-debug-32-bit-code-in-a-64-bit-dump-with-windbg/)
- [How to list stowed exceptions?](http://stackoverflow.com/questions/34462048/sos-debugging-extensions-for-microsoft-net-coreruntime/34470061#34470061)

### loading mscordacwks.dll ###

- [Obtaining mscordacwks.dll for CLR Versions You Don't Have](http://blogs.microsoft.co.il/blogs/sasha/archive/2012/05/19/obtaining-mscordacwks-dll-for-clr-versions-you-don-t-have.aspx)
- [Automatically Load the Right SOS for the Minidump](http://www.wintellect.com/blogs/jrobbins/automatically-load-the-right-sos-for-the-minidump)
- <http://blogs.msdn.com/b/dougste/archive/2009/02/18/failed-to-load-data-access-dll-0x80004005-or-what-is-mscordacwks-dll.aspx>
- <http://blogs.msdn.com/b/asiatech/archive/2010/09/10/how-to-load-the-specified-mscordacwks-dll-for-managed-debugging-when-multiple-net-runtime-are-loaded-in-one-process.aspx>
- <http://blogs.microsoft.co.il/blogs/sasha/archive/2012/05/19/obtaining-mscordacwks-dll-for-clr-versions-you-don-t-have.aspx?utm_source=feedburner&utm_medium=feed&utm_campaign=Feed%3A+sashag+%28All+Your+Base+Are+Belong+To+Us%29&utm_content=Google+Reader>
- [Rozwiązywanie problemów z mscordacwks](http://zine.net.pl/blogs/mgrzeg/archive/2014/01/15/rozwi-zywanie-problem-w-z-mscordacwks.aspx)
- [Mscordacwks/SOS debugging archive - a list of all versions of mscordacwks and SOS](http://www.sos.debugging.wellisolutions.de/)
