
Dump files on Windows
=====================

Collecting a dump file
----------------------

### Create a dump of a running process ###

To create 20 dumps when exceptions are thrown use the **-e** switch (adding *after space* 1 will create a dump also for the first chance exceptions), eg.

    procdump -accepteula -e 1 -n 20 TestProgram.exe C:\dumps\

    procdump -e TestProgram.exe

Create a full dump of a process

    procdump -ma 9112

Collect a dump every 3 minutes and stop after 3 dumps were written:

    procdump -ma -n 3 -s 180 8096 c:\Platform\Dumps\emails.dmp

### Create process and dump it ###

Start a `NServiceBus.Host.exe` process and make a full dump when exception is thrown:

    > procdump -ma -e -x c:\diag\dumps c:\temp\worker\NServiceBus.Host.exe

### Create a dump when a performance counter threshold is reached ###

    > C:\diag\dumps>c:\diag\procdump -ma -p "\Process(w3wp_6176)\Private bytes" 1500000000 6176

    ProcDump v6.00 - Writes process dump files
    Copyright (C) 2009-2013 Mark Russinovich
    Sysinternals - www.sysinternals.com
    With contributions from Andrew Richards

    Process:               w3wp.exe (6176)
    CPU threshold:         n/a
    Performance counter:   \Process(w3wp_6176)\Private bytes
    Performance threshold: >= 1500000000
    Commit threshold:      n/a
    Threshold seconds:     10
    Number of dumps:       1
    Hung window check:     Disabled
    Exception monitor:     Disabled
    Exception filter:      *
    Terminate monitor:     Disabled
    Dump file:             C:\diag\dumps\w3wp_YYMMDD_HHMMSS.dmp

### Install procdump as a post-mortem debugger ###

The -i option allows you to install procdump as a system post-mortem debugger. If you pass a folder as an argument, dumps will be created with default procdump settings. If an argument is a file the dump, it will be the name and path of the dump.

    PS temp> procdump\procdump.exe -ma -i d:\dumps

    ProcDump v5.13 - Writes process dump files
    Copyright (C) 2009-2013 Mark Russinovich
    Sysinternals - www.sysinternals.com
    With contributions from Andrew Richards

    Set:
      HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AeDebug
        (REG_SZ) Auto     = 1
        (REG_SZ) Debugger = "D:\temp\procdump\procdump.exe" -ma -j "d:\dumps" %ld %ld %p

      HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows NT\CurrentVersion\AeDebug
        (REG_SZ) Auto     = 1
        (REG_SZ) Debugger = "D:\temp\procdump\procdump.exe" -ma -j "d:\dumps" %ld %ld %p

    ProcDump is now set as the Just-in-time (AeDebug) debugger.

Analyzing collected dump files
------------------------------

### Show infomation about dump session ###

To display information about the dump session (time when dump was taken) use **vertarget** command, eg.:

    0:012> vertarget
    Windows 7 Version 7601 (Service Pack 1) MP (8 procs) Free x64
    Product: Server, suite: TerminalServer SingleUserTS
    kernel32.dll version: 6.1.7601.18409 (win7sp1_gdr.140303-2144)
    Machine Name:
    Debug session time: Thu Apr  9 10:53:08.000 2015 (UTC + 2:00)
    System Uptime: 1 days 17:37:49.480
    Process Uptime: 1 days 17:36:49.000
      Kernel time: 0 days 0:00:05.000
      User time: 0 days 0:00:37.000

Additionally when dump is loaded into windbg it will print the comment (if any) embedded into it.

### Show information on what dump contains ###

Great tool to display information about the collected dump is **dmpchk.exe**. Example excerpt of the command output:

```
................................................................
............
Loading unloaded module list
..
----- User Mini Dump Analysis

MINIDUMP_HEADER:
Version         A793 (61B1)
NumberOfStreams 13
Flags           1826
                0002 MiniDumpWithFullMemory
                0004 MiniDumpWithHandleData
                0020 MiniDumpWithUnloadedModules
                0800 MiniDumpWithFullMemoryInfo
                1000 MiniDumpWithThreadInfo

Streams:
Stream 0: type ThreadListStream (3), size 00000514, RVA 000001DC
  27 threads
  RVA 000001E0, ID 24F0, Teb:000007FFFFFDD000
  RVA 00000210, ID 1678, Teb:000007FFFFFDB000
  ...
Stream 7: type SystemInfoStream (7), size 00000038, RVA 000000BC
  ProcessorArchitecture   0009 (PROCESSOR_ARCHITECTURE_AMD64)
  ProcessorLevel          0006
  ProcessorRevision       2501
  NumberOfProcessors      02
  MajorVersion            00000006
  MinorVersion            00000001
  BuildNumber             00001DB1 (7601)
  PlatformId              00000002 (VER_PLATFORM_WIN32_NT)
  CSDVersionRva           00024DC4
                            Length: 28
                            Buffer: {'Service Pack 1'}
  Product: Server, suite: TerminalServer DataCenter SingleUserTS
Stream 8: type MiscInfoStream (15), size 000000E8, RVA 000000F4
Stream 9: type HandleDataStream (12), size 00000010, RVA 0003BC58
  0 descriptors, header size is 16, descriptor size is 40
Stream 10: type UnusedStream (0), size 00000000, RVA 00000000
Stream 11: type UnusedStream (0), size 00000000, RVA 00000000
Stream 12: type UnusedStream (0), size 00000000, RVA 00000000


Windows 7 Version 7601 (Service Pack 1) MP (2 procs) Free x64
Product: Server, suite: TerminalServer DataCenter SingleUserTS
kernel32.dll version: 6.1.7601.18409 (win7sp1_gdr.140303-2144)
Machine Name:
Debug session time: Fri Jan 16 12:56:26.000 2015 (UTC + 1:00)
System Uptime: 0 days 21:06:05.234
Process Uptime: 0 days 0:18:18.000
  Kernel time: 0 days 0:00:02.000
  User time: 0 days 0:00:49.000
PEB at 000007fffffdf000
```

In **WinDbg**:

```
0:000> ||
.  0 Full memory user mini dump: D:\diag\20150116_flapi-memory-memory-problem\w3wp.exe.dmp
0:000> |
.  0	id: 24ac	examine	name: c:\Windows\System32\inetsrv\w3wp.exe
```

You can examine content of the streams in the dump file using the **.dumpdebug** command (the output is quite similar to the one above).


### Check bitness of a dump ###

You can look at the registers available, on x86 architecture we will see eax, on x64 it should be rax, eg.:

    0:000> r
    eax=00000000 ebx=00000000 ecx=00000000 edx=00000000 esi=003241e8 edi=002df108
    eip=7d61c876 esp=002defd8 ebp=002df03c iopl=0         nv up ei pl nz na po nc
    cs=0023  ss=002b  ds=002b  es=002b  fs=0053  gs=002b             efl=00000202
    ntdll!NtReadFile+0x15:
    7d61c876 c22400

