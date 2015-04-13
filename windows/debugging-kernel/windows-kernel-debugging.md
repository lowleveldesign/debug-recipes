
Debugging kernel
================

Gathering machine information
-----------------------------

### Read Kernel Processor Control Region and Control Block (KPCR and KPRCB) ###

The kernel uses a data structure called the processor control region, or KPCR, to store processor-specific data.

    0: kd> !pcr
    *** ERROR: Module load completed but symbols could not be loaded for LiveKdD.SYS
    KPCR for Processor 0 at 82d32c00:
        Major 1 Minor 1
            NtTib.ExceptionList: a7985a9c
                NtTib.StackBase: 00000000
               NtTib.StackLimit: 00000000
             NtTib.SubSystemTib: 801de000
                  NtTib.Version: 0016e417
              NtTib.UserPointer: 00000001
                  NtTib.SelfTib: 7ffde000

                        SelfPcr: 82d32c00
                           Prcb: 82d32d20
                           Irql: 00000002
                            IRR: 00000000
                            IDR: ffffffff
                  InterruptMode: 00000000
                            IDT: 80b95400
                            GDT: 80b95000
                            TSS: 801de000

                  CurrentThread: 8604b280
                     NextThread: 00000000
                     IdleThread: 82d3c380

                      DpcQueue:

Or we can examine the `_KPCR` manually:

    0: kd> dt nt!_KPCR  82d32c00
       +0x000 NtTib            : _NT_TIB
       +0x000 Used_ExceptionList : 0xa7985a9c _EXCEPTION_REGISTRATION_RECORD
       +0x004 Used_StackBase   : (null)
       +0x008 Spare2           : (null)
       +0x00c TssCopy          : 0x801de000 Void
       +0x010 ContextSwitches  : 0x16e417
       +0x014 SetMemberCopy    : 1
       +0x018 Used_Self        : 0x7ffde000 Void
       +0x01c SelfPcr          : 0x82d32c00 _KPCR
       +0x020 Prcb             : 0x82d32d20 _KPRCB
       +0x024 Irql             : 0x2 ''
       +0x028 IRR              : 0
       +0x02c IrrActive        : 0
       +0x030 IDR              : 0xffffffff
       +0x034 KdVersionBlock   : 0x82d31c00 Void
       +0x038 IDT              : 0x80b95400 _KIDTENTRY
       +0x03c GDT              : 0x80b95000 _KGDTENTRY
       +0x040 TSS              : 0x801de000 _KTSS
       +0x044 MajorVersion     : 1
       +0x046 MinorVersion     : 1
       +0x048 SetMember        : 1
       +0x04c StallScaleFactor : 0x63c
       +0x050 SpareUnused      : 0 ''
       +0x051 Number           : 0 ''
       +0x052 Spare0           : 0 ''
       +0x053 SecondLevelCacheAssociativity : 0x10 ''
       +0x054 VdmAlert         : 0
       +0x058 KernelReserved   : [14] 0
       +0x090 SecondLevelCacheSize : 0x80000
       +0x094 HalReserved      : [16] 0
       +0x0d4 InterruptMode    : 0
       +0x0d8 Spare1           : 0 ''
       +0x0dc KernelReserved2  : [17] 0
       +0x120 PrcbData         : _KPRCB

Kernel Processor Control Region has a special structure embedded into it, called Control Region Block which is used internally by kernel for scheduling purposes:

    0: kd> !prcb
    PRCB for Processor 0 at 82d32d20:
    Current IRQL -- 0
    Threads--  Current 8604b280 Next 00000000 Idle 82d3c380
    Processor Index 0 Number (0, 0) GroupSetMember 1
    Interrupt Count -- 000d9a28
    Times -- Dpc    000000b2 Interrupt 00000044
             Kernel 00009a30 User      000054fc

Having the address in memory of this data structure we can also list it raw content. For instance to check the clock speed of the first processor we can run:

    0: kd> dt nt!_KPRCB 807c4120 Mhz
       +0x3c0 MHz : 0x63c
    0: kd> ? 0x63c
    Evaluate expression: 1596 = 0000063c

Work with user sessions
-----------------------

The **!session** extension displays all logon sessions or changes the current session context. The session context is used by the **!sprocess** and **!spoolused** extensions when the session number is entered as "-2". When the session context is changed, the process context is automatically changed to the active process for that session.

Profiling kernel
----------------

### Using kernrate ###

You can use the Kernel Profiler tool (Kernrate) to enable the system-profiling timer, collect samples of the code that is executing when the timer fires, and display a summary showing the frequency distribution across image files and functions. It can be used to track CPU usage consumed by individual processes and/or time spent in kernel mode independent of processes (for example, interrupt service routines). Kernel profiling is useful when you want to obtain a breakdown of where the system is spending time.

    C:\WinDDK\7600.16385.1\tools\Other\i386>kernrate.exe

    ...
    ------------Overall Summary:--------------

    P0     K 0:00:00.000 ( 0.0%)  U 0:00:00.234 ( 4.7%)  I 0:00:04.789 (95.3%)
    DPC 0:00:00.000 ( 0.0%)  Interrupt 0:00:00.000 ( 0.0%)
           Interrupts= 9254, Interrupt Rate= 1842/sec.

    P1     K 0:00:00.031 ( 0.6%)  U 0:00:00.140 ( 2.8%)  I 0:00:04.851 (96.6%)
    DPC 0:00:00.000 ( 0.0%)  Interrupt 0:00:00.000 ( 0.0%)
           Interrupts= 7051, Interrupt Rate= 1404/sec.

    TOTAL  K 0:00:00.031 ( 0.3%)  U 0:00:00.374 ( 3.7%)  I 0:00:09.640 (96.0%)
    DPC 0:00:00.000 ( 0.0%)  Interrupt 0:00:00.000 ( 0.0%)
           Total Interrupts= 16305, Total Interrupt Rate= 3246/sec.


    Total Profile Time = 5023 msec


                                           BytesStart          BytesStop        BytesDiff.
        Available Physical Memory   ,      1716359168,      1716195328,         -163840
        Available Pagefile(s)       ,      5973733376,      5972783104,         -950272
        Available Virtual           ,      2122145792,      2122145792,               0
        Available Extended Virtual  ,               0,               0,               0
        Committed Memory Bytes      ,      1665404928,      1666355200,          950272
        Non Paged Pool Usage Bytes  ,        66211840,        66211840,               0
        Paged Pool Usage Bytes      ,       189083648,       189087744,            4096
        Paged Pool Available Bytes  ,       150593536,       150593536,               0
        Free System PTEs            ,           37322,           37322,               0

                                      Total          Avg. Rate
        Context Switches     ,        30152,         6003/sec.
        System Calls         ,       110807,         22059/sec.
        Page Faults          ,          226,         45/sec.
        I/O Read Operations  ,          730,         145/sec.
        I/O Write Operations ,         1038,         207/sec.
        I/O Other Operations ,          858,         171/sec.
        I/O Read Bytes       ,      2013850,         2759/ I/O
        I/O Write Bytes      ,        28212,         27/ I/O
        I/O Other Bytes      ,        19902,         23/ I/O

    -----------------------------

    Results for Kernel Mode:
    -----------------------------

    OutputResults: KernelModuleCount = 167
    Percentage in the following table is based on the Total Hits for the Kernel

    Time   3814 hits, 25000 events per hit --------
    Module                                Hits       msec  %Total  Events/Sec
    NTKRNLPA                              3768       5036    98 %    18705321
    NVLDDMKM                                12       5036     0 %       59571
    HAL                                     12       5036     0 %       59571
    WIN32K                                  10       5037     0 %       49632
    DXGKRNL                                  9       5036     0 %       44678
    NETW4V32                                 2       5036     0 %        9928
    FLTMGR                                   1       5036     0 %        4964

    ================================= END OF RUN ==================================
    ============================== NORMAL END OF RUN ==============================

Additionally you may zoom the results to only specific drivers by applying `-z` option:

     C:\WinDDK\7600.16385.1\tools\Other\i386>kernrate.exe -z ntkrnlpa -z win32k
     /==============================\
    <         KERNRATE LOG           >
     \==============================/
    Date: 2011/03/09   Time: 16:49:56

    Time   4191 hits, 25000 events per hit --------
    Module                                 Hits       msec  %Total  Events/Sec
    NTKRNLPA                               3623       5695    86 %    15904302
    WIN32K                                  303       5696     7 %     1329880
    INTELPPM                                141       5696     3 %      618855
    HAL                                      61       5695     1 %      267778
    CDD                                      30       5696     0 %      131671
    NVLDDMKM                                 13       5696     0 %       57057

    ----- Zoomed module WIN32K.SYS (Bucket size = 16 bytes, Rounding Down) --------
    Module                                 Hits       msec  %Total  Events/Sec
    BltLnkReadPat                            34       5696    10 %      149227
    memmove                                  21       5696     6 %       92169
    vSrcTranCopyS8D32                        17       5696     5 %       74613
    memcpy                                   12       5696     3 %       52668
    RGNOBJ::bMerge                           10       5696     3 %       43890
    HANDLELOCK::vLockHandle                   8       5696     2 %       35112

    ----- Zoomed module NTKRNLPA.EXE (Bucket size = 16 bytes, Rounding Down) --------
    Module                                 Hits       msec  %Total  Events/Sec
    KiIdleLoop                             3288       5695    87 %    14433713
    READ_REGISTER_USHORT                     95       5695     2 %      417032
    READ_REGISTER_ULONG                      93       5695     2 %      408252
    RtlFillMemoryUlong                       31       5695     0 %      136084
    KiFastCallEntry                          18       5695     0 %       79016

Diagnosing BugCheck
-------------------

You may need to check what was the IRQL using `!irql` command. Current IRQL is also saved in a Processor Control Region (PCR) which we can examine using `!pcr` command.

Links
-----

- Tools that speed up the kernel debugging process (eg. VirtualKD)
  <http://virtualkd.sysprogs.org/>
- Windows 8 kernel debugging: New protocols and certification requirements
  <http://channel9.msdn.com/Events/Build/BUILD2011/HW-98P>
- Fun with Windows Kernel Flaw - Part 2: Hunting the important part
  <http://security.my/post/76395059266/fun-with-windows-kernel-flaw-part-2-hunting-the>
