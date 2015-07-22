
Analyzing exceptions
====================

## Read exception context ##

The  `.ecxr` debugger command instructs the debugger to restore the register context to what it was when the initial fault that led to the SEH exception took place. When an SEH exception is dispatched, the OS builds an internal structure called an exception record  It also conveniently saves the register context at the time of the initial fault in a context record structure.

    0:003> dt ntdll!_EXCEPTION_RECORD
       +0x000 ExceptionCode    : Int4B
       +0x004 ExceptionFlags   : Uint4B
       +0x008 ExceptionRecord  : Ptr32 _EXCEPTION_RECORD
       +0x00c ExceptionAddress : Ptr32 Void
       +0x010 NumberParameters : Uint4B
       +0x014 ExceptionInformation : [15] Uint4B
    0:003> dt ntdll!_CONTEXT

To list exception handlers for the currently running method use **!exchain** command, eg.:

    0072ef74: clr!_except_handler4+0 (744048b9)
      CRT scope  0, filter: clr!RaiseTheExceptionInternalOnly+233 (74405e1c)
                    func:   clr!RaiseTheExceptionInternalOnly+263 (7451c86b)
    0072f04c: clr! ?? ::FNODOBFM::`string'+2a7f9 (74405714)
    0072f0d0: clr!COMPlusFrameHandler+0 (7440619f)
    0072f108: clr!_except_handler4+0 (744048b9)
      CRT scope  1, func:   clr!CallDescrWorkerWithHandler+7e (742715d8)
      CRT scope  0, filter: clr!CallDescrWorkerWithHandler+84 (745b019d)
                    func:   clr!CallDescrWorkerWithHandler+90 (745b01a9)

### x86 applications ###

Pointer to the exception handler is kept in fs:[0]. The prolog for a method with exception handling has the following structure:

    mov     eax,fs:[00000000]
    push    eax
    mov     fs:[00000000],esp

Example session of retrieving the exception handler:

    0:000> dd /c1 fs:[0]-8 L10
    0053:fffffff8  00000000
    0053:fffffffc  00000000
    0053:00000000  0072ef74 <-- this is our first exception pointer to a handler
    0053:00000004  00730000
    0053:00000008  0072c000

    0:000> dd /c1 0072ef74-8 L10
    0072ef6c  0072eefc
    0072ef70  74275582
    0072ef74  0072f04c <-- previous handler
    0072ef78  744048b9 <-- handler address
    0072ef7c  2778008f
    0072ef80  00000000
    0072ef84  0072f058
    0072ef88  744064f9


To get the last error value for the current thread you may use the **!gle** command (or **!teb**). An additional **-all** parameter shows the last errors for all the threads, eg.

    0:001> !gle -all
    Last error for thread 0:
    LastErrorValue: (Win32) 0 (0) - The operation completed successfully.
    LastStatusValue: (NTSTATUS) 0xc0000034 - Object Name not found.

    Last error for thread 1:
    LastErrorValue: (Win32) 0 (0) - The operation completed successfully.
    LastStatusValue: (NTSTATUS) 0 - STATUS_SUCCESS

Based on <http://blogs.msdn.com/b/friis/archive/2012/09/19/c-compiler-or-visual-basic-net-compilers-fail-with-error-code-1073741502-when-generating-assemblies-for-your-asp-net-site.aspx>

If you receive an error message with an error number like this:

    Compiler Error Message: The compiler failed with error code -1073741502.

you can run windbg starting any process you like, eg. `windbg notepad.exe` and get heximal number of an error:

    0:000> .formats -0n1073741502
    Evaluate expression:
    Hex: c0000142
    Decimal: -1073741502
    Octal: 30000000502
    Binary: 11000000 00000000 00000001 01000010
    Chars: ...B
    Time: ***** Invalid
    Float: low -2.00008 high -1.#QNAN
    Double: -1.#QNAN

Then find an error description using the hex error number:

    0:000> !error c0000142
    Error code: (NTSTATUS) 0xc0000142 (3221225794) - {DLL Initialization Failed} Initialization of the dynamic link library %hs failed. The process is terminating abnormally.

Another way is to lookup errnum message using **net** command:

    > net helpmsg 2

    The system cannot find the file specified.

or **errmsg**:

    PS Windows> errmsg.exe 2

    Error: 2 (0x00000002) (02)
    The system cannot find the file specified.

## Links ##

- <http://support.microsoft.com/kb/313109>
- <http://blogs.msdn.com/b/ntdebugging/archive/2013/01/30/case-of-the-unexplained-services-exe-termination.aspx>
- <http://blogs.msdn.com/b/junfeng/archive/2008/03/03/getting-the-right-exception-context-from-a-memory-dump.aspx>

