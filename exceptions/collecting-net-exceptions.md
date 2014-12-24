
Collecting .NET exceptions in production
========================================

Using procdump
--------------

From some time procdump filtering works on .NET exception names. Each exception name is prefixed with CLR exception code (E0434F4D) and contains the full name of the exception type. Look at the example below which does nothing but prints 1st chance exceptions occurring in the process 8012:

    C:\Utils> procdump -e 1 -f "" 8012

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

To create a full memory dump when `NullReferenceException` occurs use the following command: 

```
procdump -ma -e 1 -f "E0434F4D.System.NullReferenceException" 8012
```
