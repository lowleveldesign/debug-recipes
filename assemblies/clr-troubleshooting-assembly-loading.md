
Troubleshooting assemblies loading
==================================

Using ETW (in Perfview)
-----------------------

I think that currently the most efficient way to diagnose problems with assembly loading is to collect ETW events from the .NET ETW provider. There is a bunch of them under the **Microsoft-Windows-DotNETRuntimePrivate/Binding/** category.

For this purpose you may use the [**PerfView**](https://www.microsoft.com/en-us/download/details.aspx?id=28567) util. Just make sure that you have the .NET check box selected in the collection dialog (it should be by default). Start collection and stop it after the loading exception occurs. Then open the .etl file, go to the **Events** screen and filter them by *binding* as you can see on the screenshot below:

![events](perfview-binding-events.png)

Select all of the events and press ENTER. PerfView will immediately print the instances of the selected events in the grid on the right. You may later search or filter the grid with the help of the search boxes above it.

Fusion log
----------

Fusion log is available in all versions of .NET Framework. There is a tool named **fuslogvw** which you may use to set the fusion log configuration but this tool might not be available on a server. In such a case just apply the registry settings described below.

The root of all the Fusion log settings is `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Fusion`.

### Log to exception text ###

    HKEY_LOCAL_MACHINE\software\microsoft\fusion
        EnableLog    REG_DWORD    0x1

Command:

    reg delete HKLM\Software\Microsoft\Fusion /va
    reg add HKLM\Software\Microsoft\Fusion /v EnableLog /t REG_DWORD /d 0x1

### Log failures to disk ###

    HKEY_LOCAL_MACHINE\software\microsoft\fusion
        LogFailures    REG_DWORD    0x1
        LogPath    REG_SZ    c:\logs\fuslogvw

Command:

    reg delete HKLM\Software\Microsoft\Fusion /va
    reg add HKLM\Software\Microsoft\Fusion /v LogFailures /t REG_DWORD /d 0x1
    reg add HKLM\Software\Microsoft\Fusion /v LogPath /t REG_SZ /d "C:\logs\fuslogvw"

### Log all binds to disk ###

    HKEY_LOCAL_MACHINE\software\microsoft\fusion
        LogPath    REG_SZ    c:\logs\fuslogvw
        ForceLog    REG_DWORD    0x1

Command:

    reg delete HKLM\Software\Microsoft\Fusion /va
    reg add HKLM\Software\Microsoft\Fusion /v ForceLog /t REG_DWORD /d 0x1
    reg add HKLM\Software\Microsoft\Fusion /v LogPath /t REG_SZ /d "C:\logs\fuslogvw"

### Log disabled ###

    HKEY_LOCAL_MACHINE\software\microsoft\fusion
        LogPath    REG_SZ    c:\logs\fuslogvw

Command:

    reg delete HKLM\Software\Microsoft\Fusion /va

Links
-----

- [How to enable assembly bind failure logging (Fusion) in .NET](http://stackoverflow.com/questions/255669/how-to-enable-assembly-bind-failure-logging-fusion-in-net)
