
Windows Error Reporting
=======================

In this recipe:

- [WER settings](#settings)
  - [Collecting full-memory dumps](#fulldumps)
  - [Disabling WER](#disabling)
- [Error reporting for .NET applications](#clrapps)
- [Links](#links)

## <a name="settings">WER settings</a>

By default WER takes dump only when necessary, but this behavior can be configured and we can force WER to always create a dump by modifying `HKLM\Software\Microsoft\Windows\Windows Error Reporting\ForceQueue=1` or (`HKEY_CURRENT_USER\Software\Microsoft\Windows\Windows Error Reporting\ForceQueue`). The reports are usually saved at `%localAppData%\Microsoft\Windows\WER`, in 2 directories: `ReportArchive`, when a server is available or `ReportQueue`, when the server is not available.  If you want to keep the data locally, just set the server to a non-existing machine (`HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\Windows Error Reporting\CorporateWERServer=NonExistingServer`). For system processes you need to look at **c:\ProgramData\Microsoft\Windows\WER**. In Windows 2003 Server R2 Error Reporting stores errors in signed-in user's directory (ex. `C:\Documents and Settings\ssolnica\Local Settings\Application Data\PCHealth\ErrorRep`).

### <a name="fulldumps">Collecting full-memory dumps</a>

Starting with Windows Server 2008 and Windows Vista with Service Pack 1 (SP1), Windows Error Reporting can be configured so that full user-mode dumps are collected and stored locally after a user-mode application crashes. This is done by changing some registry values under `HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\Windows Error Reporting\LocalDumps` (more [here](http://msdn.microsoft.com/en-us/library/bb787181(VS.85).aspx)). Example configuration for generating full-memory dumps in the `%SYSTEMDRIVE%\dumps` folder when the test.exe application fails might look as follows (you may download the .reg file [here](wer-fulldumps-for-test.exe.reg)):

```
Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps]

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps\test.exe]
"DumpFolder"=hex(2):25,00,53,00,59,00,53,00,54,00,45,00,4d,00,44,00,52,00,49,\
  00,56,00,45,00,25,00,5c,00,64,00,75,00,6d,00,70,00,73,00,00,00
"DumpType"=dword:00000002

```

There is an API available for [WER](http://msdn.microsoft.com/en-us/library/bb513636(VS.85).aspx) so that you can write your own application that will force WER reports.

### <a name="disabling">Disabling WER</a>

Sometimes, for instance when you use the AeDebug setting, you may want to disable WER completely. To make it happen, create a DWORD Value under the `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\Windows Error Reporting` key, named `Disabled` and set its value to 1. For 32-bit apps use the `HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\Windows Error Reporting` key.

## <a name="clrapps">Error reporting for .NET applications</a>

Based on <http://blogs.msdn.com/b/oanapl/archive/2009/01/30/windows-error-reporting-wer-and-clr-integration.aspx>

When creating reports, WER generates some parameters to bucket-ize the failures. Since the OS doesn’t know anything about managed applications, CLR integrates WER and adds these parameters to create correct buckets:

- AppName - The filename of the EXE (e.g., “Explorer.exe”);
- AppVer – Assembly version number for an managed EXE (major.minor.build.revision) or the PE header version number (e.g. “2.0.40220.13”) for unmanged
- AppStamp - The timestamp on the executable.
- AsmAndModName – Assembly and module name if the module is part of a multi-module assembly (e.g., “MyAssembly+MyModule.dll”)
- AsmVer - Managed assembly version number of the faulting assembly (major.minor.build.revision)
- ModStamp - The timestamp of the faulting module.
- MethodDef - MethodDef token for the faulting method, after stripping off the high byte.
- Offset - The IL offset of the faulting instruction.
- ExceptionType -               The name of the type of the most-inner exception, with "Exception" removed from the end, if present. (E.g., "System.AccessViolation")

For my simple application:

    Problem signature
    Problem Event Name:	CLR20r3
    Problem Signature 01:	testthrow.exe
    Problem Signature 02:	0.0.0.0
    Problem Signature 03:	513cfa24
    Problem Signature 04:	TestThrow
    Problem Signature 05:	0.0.0.0
    Problem Signature 06:	513cfa24
    Problem Signature 07:	1
    Problem Signature 08:	b
    Problem Signature 09:	System.Exception
    OS Version:	6.2.9200.2.0.0.256.48
    Locale ID:	1045
    Additional Information 1:	29c8
    Additional Information 2:	29c8a45a4be8e6196a8b4c51db32dc31
    Additional Information 3:	ed0a
    Additional Information 4:	ed0ad491a5d29e8c56367bac9db2cadd

`Problem Signature 07` is a token of a method description that caused the fault and `Problem Signature 08` is the offset in method's MSIL body. We can figure out which method a given token corresponds to by using `!Token2EE TestThrow 6000001` (we need to add token number to `6000000`).

## <a name="links">Links</a>

- [Windows Error Reporting (WER) for developers](http://blogs.msdn.com/b/oanapl/archive/2009/01/28/windows-error-reporting-wer-for-developers.aspx)
- [Windows Error Reporting and CLR integration](http://blogs.msdn.com/b/oanapl/archive/2009/01/30/windows-error-reporting-wer-and-clr-integration.aspx)
- [Problems with CLR Windows Error Reporting (WER) Integration](http://blogs.msdn.com/b/oanapl/archive/2009/02/01/problems-with-clr-windows-error-reporting-wer-integration.aspx)
- [MSDN: WER Settings](http://msdn.microsoft.com/en-us/library/bb513638(VS.85).aspx)
- [SO: Is the INT3 breakpoint the root cause? - some info about WER internals](http://stackoverflow.com/questions/38019466/how-to-know-if-a-different-exception-is-hidden-behind-a-80000003-breakpoint-wer)
