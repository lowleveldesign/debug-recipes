
Check framework version
-----------------------

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
        ProductName:      Microsoft® .NET Framework
        InternalName:     mscorwks.dll
        OriginalFilename: mscorwks.dll
        ProductVersion:   2.0.50727.4455
        FileVersion:      2.0.50727.4455 (QFE.050727-4400)
        FileDescription:  Microsoft .NET Runtime Common Language Runtime - WorkStation
        LegalCopyright:   © Microsoft Corporation.  All rights reserved.
        Comments:         Flavor=Retail

For .NET4.x you need to check clr.dll (or the Release value under the `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full` key) and make use of the table below:

|.NET Version|Clr.dll Build 4.0.30319.{build}
|-----------------------------------------------
|.NET 4.0    |4.0.30319.0 to 4.0.30319.17000
|.NET 4.5    |4.0.30319.17001 to 4.0.3019.19000
|.NET 4.5.1  |4.0.3019.19001 to 4.0.30319.34000
|.NET 4.5.2  |4.0.30319.34000 to 4.0.30319.393295
|.NET 4.6    |4.0.30319.393295 (Windows 10) or 4.0.30319.393297 (All other OS versions)
|.NET 4.6.1  |4.0.30319.394256


Examine GAC
-----------

### Find assembly in cache ###

Work only with full assembly name provided. If no name is provided lists all the assemblies in cache.

    gacutil /l System.Core

    The Global Assembly Cache contains the following assemblies:
      System.Core, Version=3.5.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089, processorArchitecture=MSIL
      System.Core, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089, processorArchitecture=MSIL

    Number of items = 2

### Uninstall assembly from cache ###

    gacutil /u MyTest.exe

CLR Code Policies
-----------------

FIXME

List groups:

    caspol -l

Remove groups

    caspol –remgroup 1.1.2.


Add FullTrust for a given path:

    caspol -m -q -ag All_Code -url \\trader-zrodla.srv.trader.pl\zrodla\prod\autotrader.pl\www\panel\bin\* FullTrust

To analyze policies applied to the assembly you may run (according to <http://msdn.microsoft.com/en-us/library/vstudio/tx1dts55(v=vs.100).aspx>):

    caspol –all –resolveperm assembly-file

    caspol –enterprise –resolveperm assembly-file
    caspol –machine –resolveperm assembly-file
    caspol –user –resolveperm assembly-file

Links
-----

- <http://stackoverflow.com/questions/1362687/the-net-2-0-sdk-programs-what-does-each-tool-do>
- [.NET Framework Repair Tool](http://support.microsoft.com/kb/2698555)

