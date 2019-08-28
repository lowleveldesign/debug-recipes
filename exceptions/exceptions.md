
# Troubleshooting exceptions and Windows errors

In this recipe:

- [Collecting exceptions info in production](#collecting-exceptions-info-in-production)
  - [Using procdump](#using-procdump)
  - [Automatic dumps using AeDebug registry key](#automatic-dumps-using-aedebug-registry-key)
  - [Break on a specific Windows Error in a debugger](#break-on-a-specific-windows-error-in-a-debugger)
- [Analyzing exceptions](#analyzing-exceptions)
  - [Read managed exception information](#read-managed-exception-information)
  - [Read exception context](#read-exception-context)
  - [Read Last Windows Error](#read-last-windows-error)
  - [Exception handlers](#exception-handlers)
    - [x86 applications](#x86-applications)
  - [Decoding error numbers](#decoding-error-numbers)
  - [Convert HRESULT to Windows Error](#convert-hresult-to-windows-error)
- [Links](#links)

## Collecting exceptions info in production

### Using procdump

From some time procdump uses a managed debugger engine when attaching to .NET processes. This is great because we can filter exceptions based on their nice names. Unfortunately, that works only for 1st chance exceptions (at least for .NET 4.0). 2nd chance exceptions are raised out of the .NET Framework and must be handled by a native debugger. Starting from .NET 4.0 it is no longer possible to attach both managed and native engine to the same process. Thus, if we want to make a dump on the 2nd chance exception for a .NET application, we need to use the **-g** option in order to force procdump to use the native engine.

It is often a good way to start diagnosing, by observing 1st chance exceptions occurring in a process. At this point we don't want to collect any dumps, only logs. We may achieve this by specyfing a non-existing exception name in the filter command, eg.:

    C:\Utils> procdump -e 1 -f "DoesNotExist" 8012

    ProcDump v7.1 - Writes process dump files
    Copyright (C) 2009-2014 Mark Russinovich
    Sysinternals - www.sysinternals.com
    With contributions from Andrew Richards

    Process:               w3wp.exe (8012)
    CPU threshold:         n/a
    Performance counter:   n/a
    Commit threshold:      n/a
    Threshold seconds:     10
    Hung window check:     Disabled
    Log debug strings:     Disabled
    Exception monitor:     First Chance+Unhandled
    Exception filter:      Display Only
    Terminate monitor:     Disabled
    Cloning type:          Disabled
    Concurrent limit:      n/a
    Avoid outage:          n/a
    Number of dumps:       1
    Dump folder:           C:\Utils\
    Dump filename/mask:    PROCESSNAME_YYMMDD_HHMMSS


    Press Ctrl-C to end monitoring without terminating the process.

    CLR Version: v4.0.30319

    [09:03:27] Exception: E0434F4D.System.NullReferenceException ("Object reference not set to an instance of an object.")
    [09:03:28] Exception: E0434F4D.System.NullReferenceException ("Object reference not set to an instance of an object.")

We may also observe the logs in procmon. In order to see the procdump log events in **procmon** remember to add procdump.exe and procdump64.exe to the accepted process names in procmon filters.

To create a full memory dump when `NullReferenceException` occurs use the following command:

    procdump -ma -e 1 -f "E0434F4D.System.NullReferenceException" 8012

### Automatic dumps using AeDebug registry key

There is a special **AeDebug** key in the registry, which allows you to define what will happen when an unhandled exception occurs in an application. You may find it under the `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion` key (or `HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows NT\CurrentVersion` for 32-bit apps). The important values under this key are:

- `Debugger` : `REG_SZ` - application which will be called to handle the problematic process (example value: `"c:\sysinternals\procdump.exe" -accepteula -j "c:\dumps" %ld %ld %p`), the first `%ld` parameter is replaced with the process ID and the second with the event handle
- `Auto` : `REG_SZ` - defines if the debugger runs automatically, without prompting the user (example value: 1)
- `UserDebuggerHotKey` : `REG_DWORD` - not sure, but it looks it enables the Debug button on the exception handling message box (example value: 1)

To set WinDbg as your default AeDebug debugger, run: `windbg -I`. Although I prefer to use procdump as my system debugger. The command line to install it is `procdump -mp -i c:\dumps`, where c:\dumps is the folder where I would like to store the dumps of crashing apps.

### Break on a specific Windows Error in a debugger

There is a special global variable in ntdll: **g\_dwLastErrorToBreakOn** that you may set to cause a break whenever a given last error code is set by the application. For example, to break the application execution whenever it reports the 0x4cf (ERROR\_NETWORK\_UNREACHABLE) error run:

    ed ntdll!g_dwLastErrorToBreakOn 0x4cf

## Analyzing exceptions

### Read managed exception information

First make sure with the **!Threads** command (SOS) that your current thread is the one with the exception context:

    0:000> !Threads
    ThreadCount:      2
    UnstartedThread:  0
    BackgroundThread: 1
    PendingThread:    0
    DeadThread:       0
    Hosted Runtime:   no
                                                                                                            Lock
           ID OSID ThreadOBJ           State GC Mode     GC Alloc Context                  Domain           Count Apt Exception
       0    1 1ec8 000000000055adf0    2a020 Preemptive  0000000002253560:0000000002253FD0 00000000004fb970 0     Ukn System.ArgumentException 0000000002253438
       5    2 1c74 00000000005851a0    2b220 Preemptive  0000000000000000:0000000000000000 00000000004fb970 0     Ukn (Finalizer)

In the snippet above we can see that the exception was thrown on the thread no. 0 and this is our currently selected thread (in case it's not we would use **~0s** command) so we may use the **!PrintException** command from SOS (alias **!pe**), example:

    0:000> !pe
    Exception object: 0000000002253438
    Exception type:   System.ArgumentException
    Message:          v should not be null
    InnerException:   <none>
    StackTrace (generated):
    <none>
    StackTraceString: <none>
    HResult: 80070057

Another option is the **!wpe** command from the netext plugin. To see the full managed call stack, use the **!CLRStack** command. By default, the debugger will stop on an unhandled exception. If you want to stop at the moment when an exception is thrown (first-chance exception), run the **sxe clr** command at the beginning of the debugging session.

### Read exception context

The  `.ecxr` debugger command instructs the debugger to restore the register context to what it was when the initial fault that led to the SEH exception took place. When an SEH exception is dispatched, the OS builds an internal structure called an exception record  It also conveniently saves the register context at the time of the initial fault in a context record structure.

    0:003> dt ntdll!_EXCEPTION_RECORD
       +0x000 ExceptionCode    : Int4B
       +0x004 ExceptionFlags   : Uint4B
       +0x008 ExceptionRecord  : Ptr32 _EXCEPTION_RECORD
       +0x00c ExceptionAddress : Ptr32 Void
       +0x010 NumberParameters : Uint4B
       +0x014 ExceptionInformation : [15] Uint4B
    0:003> dt ntdll!_CONTEXT

**.lastevent** will also show you information about the last error that occured (if the debugger stopped because of the exception). You may then examine the exception record using the **.exr** command, eg.:

    0:049> .lastevent
    Last event: 15ae8.133b4: CLR exception - code e0434f4d (first/second chance not available)
      debugger time: Thu Jul 30 19:23:53.169 2015 (UTC + 2:00)
    0:049> .exr -1
    ExceptionAddress: 000007fe9b17f963
       ExceptionCode: e0434f4d (CLR exception)
      ExceptionFlags: 00000000
    NumberParameters: 0

### Read Last Windows Error

To get the last error value for the current thread you may use the **!gle** command (or **!teb**). An additional **-all** parameter shows the last errors for all the threads, eg.

    0:001> !gle -all
    Last error for thread 0:
    LastErrorValue: (Win32) 0 (0) - The operation completed successfully.
    LastStatusValue: (NTSTATUS) 0xc0000034 - Object Name not found.

    Last error for thread 1:
    LastErrorValue: (Win32) 0 (0) - The operation completed successfully.
    LastStatusValue: (NTSTATUS) 0 - STATUS_SUCCESS

Based on <http://blogs.msdn.com/b/friis/archive/2012/09/19/c-compiler-or-visual-basic-net-compilers-fail-with-error-code-1073741502-when-generating-assemblies-for-your-asp-net-site.aspx>

### Exception handlers

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

Managed exception handlers can be listed using the SOS **!EHInfo** - example of how to list ASP.NET MVC exception handlers can be found [on my blog](https://lowleveldesign.wordpress.com/2013/04/26/life-of-exception-in-asp-net/).

For 64-bit binaries we can list all exception handlers offline using **dumpbin /unwindinfo** command.

#### x86 applications

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

### Decoding error numbers

If you receive an error message with a cryptic error number like this:

```
Compiler Error Message: The compiler failed with error code -1073741502.
```

You need to find its corresponding error message. An invaluable tool for this purpose is [**err.exe or Error Code Look-up**](https://www.microsoft.com/en-us/download/details.aspx?id=985). It looks for the specific value in Windows headers, additionally performing the convertion to hex, for example:

      PS me> err -1073741502
    # for decimal -1073741502 / hex 0xc0000142 :
      STATUS_DLL_INIT_FAILED                                        ntstatus.h
    # {DLL Initialization Failed}
    # Initialization of the dynamic link library %hs failed. The
    # process is terminating abnormally.
    ...

If you are in WinDbg, you may use the **!error** command:

    0:000> !error c0000142
    Error code: (NTSTATUS) 0xc0000142 (3221225794) - {DLL Initialization Failed} Initialization of the dynamic link library %hs failed. The process is terminating abnormally.

Even more error codes and error messages are contained in the **!pde.err** command from the PDE extension.

Finally, there is a subcommand in the **net** command to decode Windows error numbers (and only error numbers):

    > net helpmsg 2
    The system cannot find the file specified.

### Convert HRESULT to Windows Error

The pseudo-code to convert HRESULT to Windows Error looks as follows:

    a = hresult & 0x1FF0000
    if (a == 0x70000) {
    	winerror = hresult & 0xFFFF
    } else {
    	winerror = hresult
    }

Converting Windows Error to HRESULT is straightforward: `hresult = 0x80070000 | winerror`.

## Links

- [Debug exceptions using AdPlus](http://lowleveldesign.wordpress.com/2012/01/16/adplus-managed-exceptions)
- [Decoding the parameters of a thrown C++ exception (0xE06D7363)](http://blogs.msdn.com/b/oldnewthing/archive/2010/07/30/10044061.aspx)
- [HOW TO: Find the Problem Exception Stack When You Receive an UnhandledExceptionFilter Call in the Stack Trace](http://support.microsoft.com/kb/313109)
- [Case of the Unexplained Services exe Termination](http://blogs.msdn.com/b/ntdebugging/archive/2013/01/30/case-of-the-unexplained-services-exe-termination.aspx)
- [Getting the right exception context from a memory dump](http://blogs.msdn.com/b/junfeng/archive/2008/03/03/getting-the-right-exception-context-from-a-memory-dump.aspx)
