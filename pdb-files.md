
PDB files usage
===============

Downloading symbols for binary files
------------------------------------

### Using symchk.exe ###

Get symbols for ConsoleApplication1.exe:

    > symchk.exe /v ConsoleApplication1.exe /s ".;%_NT_SYMBOL_PATH%"

Get symbols for notepad.exe that is currently running:

    > symchk /v /os /fm notepad.exe /ie notepad.exe

    DBGHELP: Symbol Search Path: SRV*C:\Symbols\MSS*http://referencesource.microsoft.com/symbols;SRV*C:\Symbols\MSS*http://m
    sdl.microsoft.com/download/symbols
    [SYMCHK] Using search path "SRV*C:\Symbols\MSS*http://referencesource.microsoft.com/symbols;SRV*C:\Symbols\MSS*http://ms
    dl.microsoft.com/download/symbols"
    DBGHELP: No header for C:\Windows\system32\notepad.exe.  Searching for image on disk
    DBGHELP: C:\Windows\system32\notepad.exe - OK
    DBGHELP: notepad - public symbols
             C:\Symbols\MSS\notepad.pdb\36CFD5F9888C4483B522B9DB242D84782\notepad.pdb
    [SYMCHK] MODULE64 Info ----------------------
    [SYMCHK] Struct size: 1680 bytes
    [SYMCHK] Base: 0x0000000100000000
    [SYMCHK] Image size: 217088 bytes
    [SYMCHK] Date: 0x4a5bc9b3
    [SYMCHK] Checksum: 0x0003e749
    [SYMCHK] NumSyms: 0
    [SYMCHK] SymType: SymPDB
    [SYMCHK] ModName: notepad
    [SYMCHK] ImageName: C:\Windows\system32\notepad.exe
    [SYMCHK] LoadedImage: C:\Windows\system32\notepad.exe
    [SYMCHK] PDB: "C:\Symbols\MSS\notepad.pdb\36CFD5F9888C4483B522B9DB242D84782\notepad.pdb"
    [SYMCHK] CV: RSDS
    [SYMCHK] CV DWORD: 0x53445352
    [SYMCHK] CV Data:  notepad.pdb
    [SYMCHK] PDB Sig:  0
    [SYMCHK] PDB7 Sig: {36CFD5F9-888C-4483-B522-B9DB242D8478}
    [SYMCHK] Age: 2
    [SYMCHK] PDB Matched:  TRUE
    [SYMCHK] DBG Matched:  TRUE
    [SYMCHK] Line nubmers: FALSE
    [SYMCHK] Global syms:  FALSE
    [SYMCHK] Type Info:    FALSE
    [SYMCHK] ------------------------------------
    SymbolCheckVersion  0x00000002
    Result              0x00030001
    DbgFilename
    DbgTimeDateStamp    0x4a5bc9b3
    DbgSizeOfImage      0x00035000
    DbgChecksum         0x0003e749
    PdbFilename         C:\Symbols\MSS\notepad.pdb\36CFD5F9888C4483B522B9DB242D84782\notepad.pdb
    PdbSignature        {36CFD5F9-888C-4483-B522-B9DB242D8478}
    PdbDbiAge           0x00000002
    [SYMCHK] [ 0x00000000 - 0x00030001 ] Checked "C:\Windows\system32\notepad.exe"

    SYMCHK: FAILED files = 0
    SYMCHK: PASSED + IGNORED files = 1

Get symbols for notepad.exe that is currently running (its PID is 3188):

    > symchk /v /ods /fm notepad.exe /ip 3188

    DBGHELP: Symbol Search Path: SRV*C:\Symbols\MSS*http://referencesource.microsoft.com/symbols;SRV*C:\Symbols\MSS*http://m
    sdl.microsoft.com/download/symbols
    [SYMCHK] Using search path "SRV*C:\Symbols\MSS*http://referencesource.microsoft.com/symbols;SRV*C:\Symbols\MSS*http://ms
    dl.microsoft.com/download/symbols"
    DBGHELP: No header for C:\Windows\system32\notepad.exe.  Searching for image on disk
    DBGHELP: C:\Windows\system32\notepad.exe - OK
    DBGHELP: notepad - public symbols
             C:\Symbols\MSS\notepad.pdb\36CFD5F9888C4483B522B9DB242D84782\notepad.pdb
    [SYMCHK] MODULE64 Info ----------------------
    [SYMCHK] Struct size: 1680 bytes
    [SYMCHK] Base: 0x0000000100000000
    [SYMCHK] Image size: 217088 bytes
    [SYMCHK] Date: 0x4a5bc9b3
    [SYMCHK] Checksum: 0x0003e749
    [SYMCHK] NumSyms: 0
    [SYMCHK] SymType: SymPDB
    [SYMCHK] ModName: notepad
    [SYMCHK] ImageName: C:\Windows\system32\notepad.exe
    [SYMCHK] LoadedImage: C:\Windows\system32\notepad.exe
    [SYMCHK] PDB: "C:\Symbols\MSS\notepad.pdb\36CFD5F9888C4483B522B9DB242D84782\notepad.pdb"
    [SYMCHK] CV: RSDS
    [SYMCHK] CV DWORD: 0x53445352
    [SYMCHK] CV Data:  notepad.pdb
    [SYMCHK] PDB Sig:  0
    [SYMCHK] PDB7 Sig: {36CFD5F9-888C-4483-B522-B9DB242D8478}
    [SYMCHK] Age: 2
    [SYMCHK] PDB Matched:  TRUE
    [SYMCHK] DBG Matched:  TRUE
    [SYMCHK] Line nubmers: FALSE
    [SYMCHK] Global syms:  FALSE
    [SYMCHK] Type Info:    FALSE
    [SYMCHK] ------------------------------------
    SymbolCheckVersion  0x00000002
    Result              0x00030001
    DbgFilename
    DbgTimeDateStamp    0x4a5bc9b3
    DbgSizeOfImage      0x00035000
    DbgChecksum         0x0003e749
    PdbFilename         C:\Symbols\MSS\notepad.pdb\36CFD5F9888C4483B522B9DB242D84782\notepad.pdb
    PdbSignature        {36CFD5F9-888C-4483-B522-B9DB242D8478}
    PdbDbiAge           0x00000002
    [SYMCHK] [ 0x00000000 - 0x00030001 ] Checked "C:\Windows\system32\notepad.exe"
    SYMCHK: notepad.exe          PASSED  - PDB: C:\Symbols\MSS\notepad.pdb\36CFD5F9888C4483B522B9DB242D84782\notepad.pdb DBG
    : <N/A>

    SYMCHK: FAILED files = 0
    SYMCHK: PASSED + IGNORED files = 1

### using dumpbin.exe ###

With this switch on, dumpbin will look for a PDB file that will match the examined exe/dll file, eg.

    c:\Windows\System32>dumpbin /pdbpath:verbose WWanAPI.dll
    Microsoft (R) COFF/PE Dumper Version 10.00.40219.01
    Copyright (C) Microsoft Corporation.  All rights reserved.


    Dump of file WWanAPI.dll

    File Type: DLL
      PDB file 'c:\Windows\System32\wwanapi.pdb' checked.  (File not found)
      PDB file 'c:\Windows\System32\wwanapi.pdb' checked.  (File not found)
      PDB file found at 'c:\symbols\MSS\wwanapi.pdb\9862E0172237487BBFEF6C1B3EBEE58A1\wwanapi.pdb'

      Summary

            1000 .data
            5000 .reloc
            E000 .rsrc
           33000 .text

Examine symbol files using DBH
-------------------------------

Start dbh loading a log4net module file:

    dbh -n -s:log4net.dll

Enumerate loaded modules:

    log4net [1000000]: enummod

    0x0000000001000000 log4net

Show symbols in a given module:

    log4net [1000000]: enum

     index            address     name
        cd            1012b87 :   Add
        ce            100899e :   Add
        cf            1009067 :   Add
        d0            100e3b0 :   Add
        d1            10121ac :   Add
        d2            1009278 :   Add
        d3            1009208 :   Add
        d4            10091fc :   Add
        d5            1001813 :   Add
        d6            100e276 :   Add
        d7            1001f49 :   Add
        d8            1012965 :   Add
        d9            100dbad :   Add
        da            100f118 :   get_LoggerFactory
        ...

Show detailed information about a symbol at address ce:

      log4net [1000000]: index ce

         name : Add
         addr :  100899e
         size : 5b
        flags : 60000
         type : 0
      modbase :  1000000
        value :  60002cd
          reg : 0
        scope : SymTagNull (0)
          tag : SymTagFunction (5)
        index : ce

Look for symbols that represent types:

    log4net [1000000]: srch tag=2

     index            address                             name
         1                  0   SymTagCompiland         : log4net.Appender.AppenderSkeleton
         2                  0   SymTagCompiland         : log4net.Appender.BufferingAppenderSkeleton
         3                  0   SymTagCompiland         : log4net.Appender.AdoNetAppender
         4                  0   SymTagCompiland         : log4net.Appender.AdoNetAppenderParameter
         5                  0   SymTagCompiland         : log4net.Appender.AnsiColorTerminalAppender
         6                  0   SymTagCompiland         : log4net.Util.LevelMappingEntry
         7                  0   SymTagCompiland         : log4net.Appender.AnsiColorTerminalAppender.LevelColors
         8                  0   SymTagCompiland         : log4net.Appender.AppenderCollection
         9                  0   SymTagCompiland         : log4net.Appender.AppenderCollection.Enumerator
    ...

Display info about one of the types:

    log4net [1000000]: index  10

       name : log4net.Appender.DebugAppender
       addr :        0
       size : 0
      flags : 0
       type : 0
    modbase :  1000000
      value :        0
        reg : 0
      scope : SymTagNull (0)
        tag : SymTagCompiland (2)
      index : 10

List all source lines connected with symbols in a given source file:

    log4net [1000000]: elines *\Core\LevelCollection.cs

    OBJ:log4net.Core.LevelCollection
       c:\work\svn_root\apache\log4net\tags\log4net-1.2.10-rc2\build\package\log4net-1.2.10\src\Core\LevelCollection.cs
          82 83 83 85 86 67 68 96 97 98 99 67 68 108 109 110
          111 67 68 118 119 120 121 122 67 68 129 130 131 132 133 67
          68 140 141 142 143 144 67 68 162 163 164 165 175 175 175 184
          185 186 195 196 197 198 201 202 210 210 210 218 218 218 237 238
          239 240 242 243 244 245 246 255 256 257 258 259 261 262 264 265
          271 272 273 274 275 282 283 284 285 286 288 289 297 298 299 300
          301 302 304 298 298 305 306 318 319 320 321 322 323 325 319 319
          326 327 340 341 343 344 345 346 348 349 350 351 353 354 355 356
          366 367 368 369 370 373 374 375 387 388 390 392 393 394 395 400
          401 402 403 411 411 411 420 420 420 432 433 434 446 447 448 450
          451 452 453 454 456 457 458 459 460 461 462 463 465 466 467 468
          469 478 479 480 481 482 484 485 486 488 489 497 498 499 500 501
          503 504 505 507 508 516 517 518 519 520 522 522 522 523 524 525
          522 527 528 534 535 536 548 549 550 558 559 560 561 562 564 567
          568 569 570 571 572 574 575 582 583 584 592 592 592 593 593 593
          597 598 599 602 603 604 607 608 609 612 613 614 617 618 619 622
          623 624 631 632 633
    OBJ:log4net.Core.LevelCollection.Enumerator 658 659 660 661 662 663 674 674 674 688 689
          690 691 694 695 696 702 703 704 712 712 712
    OBJ:log4net.Core.LevelCollection.ReadOnlyLevelCollection 732 733 734 735 742
          743 744 747 748 749 752 752 752 757 757 757 762 762 762 771 771
          771 772 772 776 777 781 782 786 787 788 791 792 793 796 797 801
          802 806 807 812 812 812 817 817 817 825 826 827 836 836 836 837
          837 841 842 846 847

### Useful commands

    verbose [on|off]
    sympath [Path]
    symopt [+|-]Options (FIXME link to msdn with symbol options - print the useful ones here)

    load File - loads the specified module (either the executable or symbol file)
    unload - unloads the current module

    name [Module!]Symbol - displays detailed information about a given module
    mod Address - changes the default module to the module with the specified base address [PROCESS]
    info - displays information about currently loaded module

    index Value - displays detailed information about a symbol at a specified index
    addr Address - displays detailed information about symbols at a given address

    epmod PID - enumerates all the modules loaded for the specified process
    enummod - enumerates all loaded modules
    enum [Module!Symbol] - enumerates symbols in a given module. Both module and symbol parts accept wildcards
    enumaddr Address - enumerates symbols at a given address
    dump - displays a complete list of all symbol information in the target file

    type TypeName - displays detailed information about a given type
    etypes - enumerates all data types
    obj Mask - lists all types associated with the default module the match the specified pattern (wildcards can be used)

    srch [mask=Symbol] [index=Index] [tag=Tag] [addr=Address] [globals] - searches for all symbols that match the specified masks

    laddr Address - displays the source file and line number corresponding to the symbol located at the specified address
    src Mask - like obj but instead locates the source files
    srclines File LineNum
    line File#LineNum - finds a symbol connected with a given file and line number. Changes the current line number.
    elines [Source[Obj]] - enumerates all sources lines matching the specified source mask and object mask

    locals Function [Mask] - display local variables declared in a given function

Get source information from the PDB files
-----------------------------------------

**Displaying raw source files information**

    >srctool.exe -r refpath\CommonServiceLocator\Microsoft.Practices.ServiceLocation.pdb

    c:\Home\Chris\Projects\CommonServiceLocator\main\Microsoft.Practices.ServiceLocation\ActivationException.cs
    c:\Home\Chris\Projects\CommonServiceLocator\main\Microsoft.Practices.ServiceLocation\ActivationException.Desktop.cs
    c:\Home\Chris\Projects\CommonServiceLocator\main\Microsoft.Practices.ServiceLocation\Properties\Resources.Designer.cs
    c:\Home\Chris\Projects\CommonServiceLocator\main\Microsoft.Practices.ServiceLocation\ServiceLocator.cs
    c:\Home\Chris\Projects\CommonServiceLocator\main\Microsoft.Practices.ServiceLocation\ServiceLocatorImplBase.cs

**Extracts filtered files to a specific directory**

    >srctool -l:*Exception* refpath\CommonServiceLocator\Microsoft.Practices.ServiceLocation.pdb -x -d:temp

    temp\main\Microsoft.Practices.ServiceLocation\ActivationException.cs
    temp\main\Microsoft.Practices.ServiceLocation\ActivationException.Desktop.cs

    refpath\CommonServiceLocator\Microsoft.Practices.ServiceLocation.pdb: 2 source files were extracted

**Extracts filtered files to a specific directory (no subdirectories)**

    >srctool -l:*Exception* refpath\CommonServiceLocator\Microsoft.Practices.ServiceLocation.pdb -x -f -d:temp

    temp\ActivationException.cs
    temp\ActivationException.Desktop.cs

    refpath\CommonServiceLocator\Microsoft.Practices.ServiceLocation.pdb: 2 source files were extracted


Symbol and source server
------------------------

Symbols in deployment

If our source versioning system is supported by debugging tools we already have all the needed scripts to perform symbol indexing. For example for subversion, we should call command:

    svnindex /debug /symbols="Publish\Win32" /Source="Source;Dll\Source"

To check if a pdbfile contains the source stream you may use srctool.exe or pdbstr.exe:

    pdbstr -r -p:NetApp.pdb -s:srcsrv .

To debug using source server you need to use `_NT_SOURCE_PATH` variable set to `SRV*c:\symbols` - after the asterisk comes directory that you want to use as your local symbol cache store. When you debug for the first time with source server, a warning popup will show up indicating that you the source server command is going to be called. You can configure this behavior though the registry settings in `HKEY_CURRENT_USER\Software\Microsoft\Source Server\Warning`. If Srvsrc.ini has the version control command in its [trusted commands] section it will not display the security alert, eg.

    [trusted commands]
    ss.exe=C:\VSNET8\Microsoft Visual SourceSafe\ss.exe

In Visual Studio it's impossible to select "I trust this server" option so you need to manually copy the srcsrv.ini file to the `Visual_Studio_Install_Directory\Common7\IDE` directory.

### Symbol Store ###

Is it based on Windows file sharing. You need to create a SYMBOLS folder which will hold all types of symbols. Within it it's a good idea to have two subdirectories: OSSYMBOLS and PRODUCTSYMBOLS. First, for OS symbols which you will download from Microsoft public servers and second, with you application symbols and binaries.

SymStore (symstore.exe) is a tool for creating symbol stores. It is included in the Debugging Tools for Windows package.

Each operation on the symbol store creates a new transaction. There is a special 000admin directory which contains one file per transaction as well as the log files server.txt and history.txt.

Multiple versions of .pdb symbol files (for example, public and private versions) cannot be stored on the same server, because they each contain the same signature and age.

### Example of usage

Let's assume that the symbol server will have \\SYMBOLS address. To add your project files to it, you need to execute:

    symstore add /r /o /f "c:\depl\TRAIN\TnE.Web_2.1.0629.00\bin" /s \\SSYMBOLS\PRODUCTSYMBOLS /t TnE /v "v2.1.0629.00" /c "TRAIN”

On the symbols path a new directory will be created 000Admin with history.txt file that holds a history of all symbol store transactions. To delete files uploaded in a given transaction use command:

    symstore del /i 0000000009 /s \\SSYMBOLS\PRODUCTSYMBOLS

where 0000000009 is a transaction number from history.txt file.

### HTTP access for symbol store ###

Making debug symbols accessible through HTTP is a very simple task. You just need to create a virtual directory for the symbols directory (and choose the authentication method). Then you need to ensure that authenticated users are able to browse the directory on the system (use Security settings for a directory). Finally set MIME type to "application/octet-stream" for all files served by the symbol store. In HTTP Headers tab add a new MIME type with "Extension" set to "\*" and "Mime type" set to "application/octet-stream".

Interesting Symbol Servers
-------------------------

Based on <http://zine.net.pl/blogs/mgrzeg/archive/2014/03/03/serwery-symboli-dla-znanych-produkt-w-nie-ms.aspx>

- Firefox ([source](https://developer.mozilla.org/en-US/docs/Using_the_Mozilla_symbol_server)) - private `SRV*c:\websymbols*http://symbols.mozilla.org/firefox
- Chrome ([source](http://www.chromium.org/developers/how-tos/debugging)) - private: `SRV*c:\websymbols*http://chromium-browser-symsrv.commondatastorage.googleapis.com`
- Citrix ([source](http://support.citrix.com/article/CTX118622)) - `SRV*c:\websymbols*http://ctxsym.citrix.com/symbols`
- SymbolSource ([more info](http://www.symbolsource.org/Public/Wiki/Using)) - `SRV*c:\websymbols\*http://srv.symbolsource.org/pdb/Public`, `SRV*c:\websymbols\*http://srv.symbolsource.org/pdb/MyGet`

Links
-----

- [GitHub Source Symbol Indexer](http://hamishgraham.net/post/GitHub-Source-Symbol-Indexer.aspx)
- [The RSDS pdb format](http://www.godevtool.com/Other/pdb.htm)
- [Microsoft repo containing information about PDB](https://github.com/Microsoft/microsoft-pdb)
