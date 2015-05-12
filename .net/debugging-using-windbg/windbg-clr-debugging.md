
Debugging .NET using WinDbg
===========================

Usage examples
--------------

### Save a module from a dump (!savemodule) ###

    !SaveModule <Base address> <Filename>

This command allows you to save a module from a memory dump to a disk. The base address can be found by using `lm` command. Example:

    0:000> lm
    start    end        module name
    00400000 0040c000   trader_products_service_host   (deferred)
    00d50000 00d96000   log4net    (deferred)
    00e70000 00e7e000   Trader_Products_Service   (deferred)
    ...
    0:000> !SaveModule 00e70000 c:\temp\Trader.Products.Service.dll
    3 sections in file
    section 0 - VA=2000, VASize=66e4, FileAddr=200, FileSize=6800
    section 1 - VA=a000, VASize=3b0, FileAddr=6a00, FileSize=400
    section 2 - VA=c000, VASize=c, FileAddr=6e00, FileSize=200

To save all modules in a given dump you may use **!for\_each\_module** command:

    !for_each_module !savemodule @#Base C:\path_to_save\${@#ModuleName}.dll

### Display .NET objects ###

Based on <http://www.wintellect.com/blogs/jrobbins/displaying-multiple-.net-objects-with-windbg%E2%80%99s-command-language>

We can show detail information on each object found in a heap using WinDbg meta commands and SOSEX `mdt`:

    0:013> .foreach (addr {!dumpheap -type FontFamily -short}) { !mdt addr; .echo }
    000000b45faff460 (System.Drawing.FontFamily)
        __identity:NULL (System.Object)
        nativeFamily:000000b6aaad8f40 (System.IntPtr)
        createDefaultOnFail:false (System.Boolean)

    000000b45faff630 (System.Drawing.FontFamily)
        __identity:NULL (System.Object)
        nativeFamily:000000b6aaad8f40 (System.IntPtr)
        createDefaultOnFail:false (System.Boolean)

A DumpType.txt script is available in \scripts folder which automize this process. Example usage:

    0:013> $$>a<c:\junk\DumpType.txt
    Usage: $$>>a<DumpType.txt type

    0:013> $$>a<c:\junk\DumpType.txt FontFamily
    000000b45faff460 (System.Drawing.FontFamily)
        __identity:NULL (System.Object)
        nativeFamily:000000b6aaad8f40 (System.IntPtr)
        createDefaultOnFail:false (System.Boolean)

    000000b45faff630 (System.Drawing.FontFamily)
        __identity:NULL (System.Object)
        nativeFamily:000000b6aaad8f40 (System.IntPtr)
        createDefaultOnFail:false (System.Boolean)

### Break when specific exception occurs ###

Break when `NullReferenceException` is thrown:

    !sxe -c "!soe System.NullReferenceException 1;.if (@$t1 != 1) { g; }" clr

### Find a value of a static field ###

SOS does not display the address of the field. Use `!sosex.mdt` instead.

    !sosex.mdt windbg_static_test.StaticTest

### Find a type or method (Name2EE) ###

**Name2EE** searches through all the domains and lists matching methods and types, eg.

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

Work with types
--------------

### Decode a GUID value ###

Copy the output from the dd command to the `Get-GuidFromDwords` powershell command.

An example application and its debugging session:

    public static void Main(String[] args) {
        Guid g = Guid.NewGuid();
        Console.WriteLine("GUID created: {0}", g);
        Console.ReadKey();
    }

    0:000> !CLRStack -a
    ...
    00000000001feae0 000007ff001401b2 Program.Main(System.String[])*** WARNING: Unable to verify checksum for C:\temp\guidtest.exe
     [c:\temp\guidtest.cs @ 8]
        PARAMETERS:
            args (0x00000000001feb60) = 0x0000000002421438
        LOCALS:
            0x00000000001feb00 = 0x48da0ccf7d6500fb
    ...

    // GUID created: 7d6500fb-0ccf-48da-bc3f-58e9febd2653

    0:000> dd 0x00000000001feb00
    00000000`001feb00  7d6500fb 48da0ccf e9583fbc 5326bdfe
    ...
    0:000> dq 0x00000000001feb00
    00000000`001feb00  48da0ccf`7d6500fb 5326bdfe`e9583fbc
    ...

Then in powershell:

    PS tabor> Get-GuidFromDwords "7d6500fb 48da0ccf e9583fbc 5326bdfe"
    7d6500fb-0ccf-48da-bc3f-58e9febd2653

### Decode a DateTime value ###

SQL Parameter `_value` field was set to `09443a74`. After dumping object at this address it appeared that this is a DateTime instance:

    0:019> !do 09443a74
    Name: System.DateTime
    MethodTable: 79308184
    EEClass: 790e0564
    Size: 16(0x10) bytes
     (C:\WINDOWS\assembly\GAC_32\mscorlib\2.0.0.0__b77a5c561934e089\mscorlib.dll)
    Fields:
          MT    Field   Offset                 Type VT     Attr    Value Name
    79309428  40000f4        4        System.UInt64  1 instance 634915192800000000 dateData
    79332cc0  40000f0       30       System.Int32[]  0   shared   static DaysToMonth365
        >> Domain:Value  0015f7c8:01082d10 <<
    79332cc0  40000f1       34       System.Int32[]  0   shared   static DaysToMonth366
        >> Domain:Value  0015f7c8:01082d50 <<
    79308184  40000f2       28      System.DateTime  1   shared   static MinValue
        >> Domain:Value  0015f7c8:01082cf0 <<
    79308184  40000f3       2c      System.DateTime  1   shared   static MaxValue
        >> Domain:Value  0015f7c8:01082d00 <<

When an object has a DateTime property, eg.

    0:005> !do 01627c90
    Name:        Trader.Domiporta.Zolas.Model.AllAds.FlapiSyncStatus
    MethodTable: 03e2fb54
    EEClass:     040eb534
    Size:        56(0x38) bytes
    File:        C:\TraderPlatform\Trader.Domiporta.Zolas\Trader.Domiporta.Zolas.exe
    Fields:
          MT    Field   Offset                 Type VT     Attr    Value Name
    7376224c  40001db        4        System.String  0 instance 01627310 <EntityName>k__BackingField
    73752cfc  40001dc        c ...eTime, mscorlib]]  1 instance ! <LastProcessingDate>k__BackingField
    73752cfc  40001dd       18 ...eTime, mscorlib]]  1 instance 01627ca8 <LastProcessedItemModifyDate>k__BackingField
    73792dfc  40001de       24 ...Int64, mscorlib]]  1 instance 01627cb4 <LastProcessedItemId>k__BackingField
    7375813c  40001df        8       System.Boolean  1 instance        1 <IsMigrationFinished>k__BackingField

we need to use `!DumpVC`, eg. `!DumpVC 73752cfc 01627ca8`.

To decode the datetime value we may use powershell:

    > new-object System.DateTime 634915192800000000

    19 grudnia 2012 13:08:00

CLR debugging setup
-------------------

### Get help for a SOS command ###

SOS commands sometimes get overriden by other extensions help files. In such a case just use `!sos.help <cmd>` command, eg.

    0:000> !sos.help !savemodule
    -------------------------------------------------------------------------------
    !SaveModule <Base address> <Filename>
    ...

### Loading SOS using procdumpext ###

Andrew Richards created a great WinDbg plugin for loading SOS: **procdumpext**:

    0:000> !procdumpext.help
    [CIAP]
      !loadsos        - Runs .cordll and .loadby sos
      !loadpsscor     - Runs .cordll and .load psscor2/4
      !loadsosex      - Runs .cordll and .load sosex
                      - Note, sosex is loaded with sos or psscor2/4

      Define PROCDUMPEXT_LOADCORDLL to choose the extension at load
                      0 = Disabled
                      1 = SOS + SOSEX
                      2 = PSSCORx + SOSEX (default)

Using it makes it really simple to load SOS:

    0:000> .load c:\tools\diagnosing\Debugging Tools for Windows\_winext-x64\ProcDumpExt.dll
    =========================================================================================
     ProcDumpExt v6.4 - Copyright 2013 Andrew Richards
    =========================================================================================
    0:000> !loadsos

Plugins
-------

- .NET plugin for WinDbg with interesting commands: <http://netext.codeplex.com/>. Some articles about it:
  - <http://blogs.msdn.com/b/rodneyviana/archive/2013/10/30/hardcore-debugging-for-net-developers-not-for-the-faint-of-heart.aspx>
  - [Getting started with NetExt](http://blogs.msdn.com/b/rodneyviana/archive/2015/03/10/getting-started-with-netext.aspx)
  - [The case of the non-responsive MVC Web Application](http://blogs.msdn.com/b/rodneyviana/archive/2015/03/27/the-case-of-the-non-responsive-mvc-web-application.aspx)
  - [Debugging - NetExt WinDbg Extension](http://www.debugthings.com/2015/03/31/netext-windbg/)

Links
-----

- [Identifying Specific Reference Type Arrays with SOS](http://blogs.microsoft.co.il/sasha/2014/05/01/identifying-specific-reference-type-arrays-sos/)
- [A Motivating Example of WinDbg Scripting for .NET Developers](http://blogs.microsoft.co.il/sasha/2014/08/05/motivating-example-windbg-scripting-net-developers/)
- [How to display a DateTime in WinDbg using SOS](http://blogs.iis.net/carlosag/archive/2014/10/24/how-to-display-a-datetime-in-windbg-using-sos.aspx)
- [Andrew Richard's onedrive](https://onedrive.live.com/?cid=dae128bd454cf957&id=DAE128BD454CF957!7152&ithint=folder,zip&authkey=!ALq3LqMcfgs8JoM)

### loading mscordacwks.dll ###

- [Obtaining mscordacwks.dll for CLR Versions You Don’t Have](http://blogs.microsoft.co.il/blogs/sasha/archive/2012/05/19/obtaining-mscordacwks-dll-for-clr-versions-you-don-t-have.aspx)
- [Automatically Load the Right SOS for the Minidump](http://www.wintellect.com/blogs/jrobbins/automatically-load-the-right-sos-for-the-minidump)
- <http://blogs.msdn.com/b/dougste/archive/2009/02/18/failed-to-load-data-access-dll-0x80004005-or-what-is-mscordacwks-dll.aspx>
- <http://blogs.msdn.com/b/asiatech/archive/2010/09/10/how-to-load-the-specified-mscordacwks-dll-for-managed-debugging-when-multiple-net-runtime-are-loaded-in-one-process.aspx>
- <http://blogs.microsoft.co.il/blogs/sasha/archive/2012/05/19/obtaining-mscordacwks-dll-for-clr-versions-you-don-t-have.aspx?utm_source=feedburner&utm_medium=feed&utm_campaign=Feed%3A+sashag+%28All+Your+Base+Are+Belong+To+Us%29&utm_content=Google+Reader>
- [Rozwi¹zywanie problemów z mscordacwks](http://zine.net.pl/blogs/mgrzeg/archive/2014/01/15/rozwi-zywanie-problem-w-z-mscordacwks.aspx)

