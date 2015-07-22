
Automatic debugging configuration
------------------------------

### System crashes ###

The `HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CrashControl` key configures what should be done when system stops responding. An example configuration that creates a dump on system hang looks as follows:

    Windows Registry Editor Version 5.00

    [HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CrashControl]
    "DumpFilters"=hex(7):64,00,75,00,6d,00,70,00,66,00,76,00,65,00,2e,00,73,00,79,\
      00,73,00,00,00,00,00
    "LogEvent"=dword:00000001
    "Overwrite"=dword:00000001
    "AutoReboot"=dword:00000001
    "DumpFile"=hex(2):25,00,53,00,79,00,73,00,74,00,65,00,6d,00,52,00,6f,00,6f,00,\
      74,00,25,00,5c,00,4d,00,45,00,4d,00,4f,00,52,00,59,00,2e,00,44,00,4d,00,50,\
      00,00,00
    "CrashDumpEnabled"=dword:00000007
    "MinidumpsCount"=dword:00000032
    "MinidumpDir"=hex(2):25,00,53,00,79,00,73,00,74,00,65,00,6d,00,52,00,6f,00,6f,\
      00,74,00,25,00,5c,00,4d,00,69,00,6e,00,69,00,64,00,75,00,6d,00,70,00,00,00

    [HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CrashControl\StorageTelemetry]
    "StorageTCCode_3"=dword:69696969
    "StorageTCCode_2"=dword:0000007b
    "StorageTCCode_1"=dword:0000007a
    "StorageTCCode_0"=dword:00000077
    "DeviceDumpEnabled"=dword:00000001

### Application debugging configuration ###

The configuration of the user-mode debugger is stored under the `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AeDebug\` key. The `Debugger` `REG_SZ` string specifies the command line for the debugger. The string should include the fully qualified path to the debugger executable. Indicate the process ID and event handle with "%ld" parameters to the debugger command line. Different debuggers may have their own parameter syntaxes for indicating these values. When the debugger is invoked, the first "%ld" is replaced with the process ID and the second "%ld" is replaced with the event handle.

If you want the debugger to be invoked without user interaction, add or edit the Auto value, using a REG\_SZ string that specifies whether the system should display a dialog box to the user before the debugger is invoked. The string "1" disables the dialog box; the string "0" enables the dialog box.

Additionally you can decide which applications should not be dumped by using `AutoExclusionList`.

Example configuration that uses procdump to create a dump for process might look as follows:

    Windows Registry Editor Version 5.00

    [HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AeDebug]
    "UserDebuggerHotKey"=dword:00000000
    "Debugger"="\"D:\\temp\\procdump\\procdump.exe\" -ma -j \"d:\\dumps\" %ld %ld %p"
    "Auto"="1"

    [HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AeDebug\AutoExclusionList]
    "DWM.exe"=dword:00000001

