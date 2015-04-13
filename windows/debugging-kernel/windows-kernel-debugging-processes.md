## Work with processes and threads in the kernel mode

### List processes running in the system

    !process [/s Session] [/m Module] [Process [Flags]]
    !process [/s Session] [/m Module] 0 Flags ImageName

This command lists all processes running currently on the system:

    lkd> !process 0 0
    **** NT ACTIVE PROCESS DUMP ****
    PROCESS fffffa80052071d0
        SessionId: none  Cid: 0004    Peb: 00000000  ParentCid: 0000
        DirBase: 00187000  ObjectTable: fffff8a0000018d0  HandleCount: 905.
        Image: System
    ...

You can now focus on one of the processes, eg.:

    lkd> !process fffffa8006aac080
    PROCESS fffffa8006aac080
        SessionId: 0  Cid: 0300    Peb: 7fffffd9000  ParentCid: 0250
        DirBase: 14efef000  ObjectTable: fffff8a001012be0  HandleCount: 364.
        Image: svchost.exe
        VadRoot fffffa8007227cf0 Vads 107 Clone 0 Private 815. Modified 83. Locked 0.
        DeviceMap fffff8a000008b30
        Token                             fffff8a00102f9e0
        ElapsedTime                       00:48:46.664
        UserTime                          00:00:00.608
        KernelTime                        00:00:01.014
        QuotaPoolUsage[PagedPool]         0
        QuotaPoolUsage[NonPagedPool]      0
        Working Set Sizes (now,min,max)  (2382, 50, 345) (9528KB, 200KB, 1380KB)
        PeakWorkingSetSize                2448
        VirtualSize                       44 Mb
        PeakVirtualSize                   49 Mb
        PageFaultCount                    3582
        MemoryPriority                    BACKGROUND
        BasePriority                      8
        CommitCharge                      1031

            ...
            THREAD fffffa80079fa080  Cid 0300.0320  Teb: 000007fffffac000 Win32Thread: 0000000000000000 WAIT: (UserRequest) UserMode Alertable
                fffffa800522b0c8  SynchronizationEvent
            ...

To display information about a specific thread (with its call stack) use the **!thread address** command. By default it will display kernel-mode stacks only, but you may combine both worlds by switching the process context with the **.process /r /p** command.

### Find process by its image name ###

    0: kd> !process 0 0 Test.exe
    PROCESS 85551cc0  SessionId: 1  Cid: 0128    Peb: 7f823000  ParentCid: 0d08
    FreezeCount 1
        DirBase: dcd75740  ObjectTable: f3db2840  HandleCount: <Data Not Accessible>
        Image: Test.exe

### Set process context ###

During kernel-mode debugging, you can set the process context by using the **.process** (Set Process Context) command. Use this command to select which process's page directory is used to interpret virtual addresses. After you set the process context, you can use this context in any command that takes addresses.

    .process [/i] [/p [/r] ] [/P] [Process]

**/i** means invasive debugging and allows you to control the process from the kernel debugger. **/r** reloads user-mode symbols after the process context has been set (the behavior is the same as **.reload /user**). **/p** translates all transition page table entries (PTEs) for this process to physical addresses before access. Example:

    lkd> .process /p /r fffffa8006aac080
    Implicit process is now fffffa80`06aac080
    Loading User Symbols
    .................................Missing image name, possible paged-out or corrupt data.
    .*** WARNING: Unable to verify timestamp for Unknown_Module_00000000`00000000
    Unable to add module at 00000000`00000000
    ..............Missing image name, possible paged-out or corrupt data.
    .*** WARNING: Unable to verify timestamp for Unknown_Module_00000000`00000000
    Unable to add module at 00000000`00000000

### Set register context ###

Each thread has its own register values. These values are stored in the CPU registers when the thread is executing and are stored in memory when another thread is executing. You can set the register context using **.thread** command:

    .thread [/p [/r] ] [/P] [/w] [Thread]

or

    .trap [Address]
    .cxr [Options] [Address]

### Display currently executed code in all threads (!stacks) ###

FIXME

