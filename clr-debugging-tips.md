
CLR general debugging tips
==========================

In this recipe:

- [Debugging/tracing a containerized .NET application (Docker)](#debuggingtracing-a-containerized-net-application-docker)
- [CLR debugging in WinDbg](#clr-debugging-in-windbg)
  - [Loading SOS](#loading-sos)
  - [Get help for commands in .NET WinDbg extensions](#get-help-for-commands-in-net-windbg-extensions)
  - [Loading symbol files for .NET Core](#loading-symbol-files-for-net-core)
- [Controlling JIT optimization](#controlling-jit-optimization)
  - [DebuggableAttribute](#debuggableattribute)
  - [Disabling JIT optimization (.NET Core)](#disabling-jit-optimization-net-core)
  - [Disabling JIT optimization (.NET Framework)](#disabling-jit-optimization-net-framework)
- [Decode managed stacks in Sysinternals](#decode-managed-stacks-in-sysinternals)
- [Check framework version (Old .NET Framework)](#check-framework-version-old-net-framework)
- [CLR Code Policies (obsolete)](#clr-code-policies-obsolete)

## Debugging/tracing a containerized .NET application (Docker)

With the introduction of EventPipes in .NET Core 2.1, the easiest approach is to create a shared `/tmp` volume and use a sidecar diagnostics container. I prepared a [Dockerfile.netdiag](docker/Dockerfile.netdiag) which you may use to create a .NET diagnostics Docker image, for example:

```
$ docker build -t netdiag -f .\Dockerfile.netdiag .
```

Then, create a `/tmp` volume and mount it into your .NET application container, for example:

```
$ docker volume create dotnet-tmp

$ docker run --rm --name helloserver --mount "source=dotnet-tmp,target=/tmp" -p 13000:13000 helloserver 13000
```

And you are ready to run the diagnostics container and diagnose the remote application:

```
$ docker run --rm -it --mount "source=dotnet-tmp,target=/tmp" --pid=container:helloserver netdiag

root@d4bfaa3a9322:/# dotnet-trace ps
         1 dotnet     /usr/share/dotnet/dotnet 
```

If you only want to trace the application with **dotnet-trace**, consider using the [Dockerfile.nettrace](docker/Dockerfile.nettrace) file. The nettrace container will automatically start the tracing session enabling the providers from the input.rsp file. It also assumes the destination process name is dotnet:

```
$ docker build -t nettrace -f .\Dockerfile.nettrace .

$ docker run --rm --pid=container:helloserver --mount "source=dotnet-tmp,target=/tmp" -v "$pwd/:/work" -it nettrace

Provider Name                           Keywords            Level               Enabled By
Microsoft-Windows-DotNETRuntime         0x00000014C14FCCBD  Informational(4)    --providers
Microsoft-DotNETCore-SampleProfiler     0x0000F00000000000  Informational(4)    --providers

Process        : /usr/share/dotnet/dotnet
Output File    : /work/trace.nettrace
[00:00:00:02]   Recording trace 261.502  (KB)
Press <Enter> or <Ctrl+C> to exit...11   (KB)
Stopping the trace. This may take up to minutes depending on the application being traced.
```

## CLR debugging in WinDbg

### Loading SOS

When you are debugging on the same machine on which you collected the dump use the following commands:

```
.loadby sos mscorwks (.NET 2.0/3.5)
.loadby sos clr      (.NET 4.0+)
.loadby sos coreclr  (.NET Core)
```

Windbg Preview should load the SOS extension automatically for .NET Core apps/dumps. Check with the `.chain` command if it is there.

If it's not loaded, try using `!analyze -v`. On latest windbg versions it should detect a managed application and load the correct SOS version. If it does not work, load SOS from your .NET installation and try to download a correct mscordacwks as described [here](http://blogs.microsoft.co.il/blogs/sasha/archive/2012/05/19/obtaining-mscordacwks-dll-for-clr-versions-you-don-t-have.aspx).

Other issues:

- [Failed to load data access DLL, 0x80004005 – OR – What is mscordacwks.dll?](http://blogs.msdn.com/b/dougste/archive/2009/02/18/failed-to-load-data-access-dll-0x80004005-or-what-is-mscordacwks-dll.aspx)
- [How to load the specified mscordacwks.dll for managed debugging when multiple .NET runtime are loaded in one process](http://blogs.msdn.com/b/asiatech/archive/2010/09/10/how-to-load-the-specified-mscordacwks-dll-for-managed-debugging-when-multiple-net-runtime-are-loaded-in-one-process.aspx)

### Get help for commands in .NET WinDbg extensions

SOS commands sometimes get overriden by other extensions help files. In such a case just use `!sos.help <cmd>` command, eg.

    0:000> !sos.help !savemodule
    -------------------------------------------------------------------------------
    !SaveModule <Base address> <Filename>
    ...

SOSEX help can be seen using the `!sosexhelp [command]` command.

Netext help can be nicely rendered in the command window: `.browse !whelp`.

### Manually loading symbol files for .NET Core

I noticed that sometimes Microsoft public symbol servers do not have .NET Core dlls symbols. That does not allow WinDbg to decode native .NET stacks. Fortunately, we may solve this problem by precaching symbol files using the [dotnet-symbol](https://github.com/dotnet/symstore/tree/master/src/dotnet-symbol) tool. Assuming we set our `_NT_SYMBOL_PATH` to `SRV*C:\symbols\dbg*http://msdl.microsoft.com/download/symbols`, we need to run dotnet-symbol with the **--cache-directory** parameter pointing to our symbol cache folder (for example, `C:\symbols\dbg`):

```
dotnet-symbol --recurse-subdirectories --cache-directory c:\symbols\dbg -o C:\temp\toremove "C:\Program Files\dotnet\shared\Microsoft.NETCore.App\3.0.0\*"
```

We may later remove the `C:\temp\toremove` folder as all PDB files are indexed in the cache directory. The output folder contains both DLL and PDB files, takes lots of space, and is often not required.

## Controlling JIT optimization

Assemblies can be compiled as optimized - JIT compiler takes `DebuggableAttribute` into consideration while generating the native code to execute.

### DebuggableAttribute

The definition of the `DebuggingModes` flag sent to the constructor:

    [Flags]
    [ComVisible(true)]
    public enum DebuggingModes
    {
        None = 0x0,
        Default = 0x1,
        DisableOptimizations = 0x100,
        IgnoreSymbolStoreSequencePoints = 0x2,
        EnableEditAndContinue = 0x4
    }

**/debug:full /optimize-**

    [mscorlib]System.Diagnostics.DebuggableAttribute/DebuggingModes) = ( 01 00 07 01 00 00 00 00 )

    0x0107 = DisableOptimization | EnableEditAndContinue | IgnoreSymbolStoreSequencePoints | Default

**/debug:full /optimize+**

    [mscorlib]System.Diagnostics.DebuggableAttribute/DebuggingModes) = ( 01 00 03 00 00 00 00 00 )

    0x0003 = IgnoreSymbolStoreSequencePoints | Default

**/debug:pdbonly /optimize-**

    [mscorlib]System.Diagnostics.DebuggableAttribute/DebuggingModes) = ( 01 00 02 01 00 00 00 00 )

    0x0102 = DisableOptimization | IgnoreSymbolStoreSequencePoints

**/debug:pdbonly /optimize+**

    [mscorlib]System.Diagnostics.DebuggableAttribute/DebuggingModes) = ( 01 00 02 00 00 00 00 00 )

    0x0002 = IgnoreSymbolStoreSequencePoints

**\*nothing\***

No Debuggable attribute emitted

### Disabling JIT optimization (.NET Core)

For .NET Core, set the `COMPlus_JITMinOpts` variable:

```
export COMPlus_JITMinOpts=1
```

### Disabling JIT optimization (.NET Framework)

You need to create an ini file. The ini file must have the same name as the executable with only extension changed to ini, eg. my.ini file will work with my.exe application.

    [.NET Framework Debugging Control]
    GenerateTrackingInfo=1
    AllowOptimize=0

## Decode managed stacks in Sysinternals

As of version 16.22 version, **Process Explorer** understands managed stacks and should display them correctly when you double click on a thread in a process.

**Process Monitor**, unfortunately, lacks this feature. Pure managed modules will appear as `<unknown>` in the call stack view. However, we may fix the problem for the ngened assemblies. First, you need to generate a .pdb file for the ngened assembly, for example, `ngen createPDB c:\Windows\assembly\NativeImages_v4.0.30319_64\mscorlib\e2c5db271896923f5450a77229fb2077\mscorlib.ni.dll c:\symbols\private`. Then make sure you have this path in your `_NT_SYMBOL_PATH` variable, for example, `C:\symbols\private;SRV*C:\symbols\dbg*http://msdl.microsoft.com/download/symbols`. If procmon still does not resolve the symbols, go to Options - Configure Symbols and reload the dbghelp.dll. I observe this issue in version 3.50.

## Check framework version (Old .NET Framework)

For .NET2.0 you could check the version of mscorwks in the file properties or, if in debugger, using lmmv:

    0:000> lmv m mscorwks
    start             end                 module name
    00000642`7f330000 00000642`7fcdc000   mscorwks   (deferred)
        Image path: C:\WINDOWS\Microsoft.NET\Framework64\v2.0.50727\mscorwks.dll
        Image name: mscorwks.dll
        Timestamp:        Wed May 12 00:13:32 2010 (4BEA38FC)
        CheckSum:         0099D95F
        ImageSize:        009AC000
        File version:     2.0.50727.4455
        Product version:  2.0.50727.4455
        File flags:       0 (Mask 3F)
        File OS:          4 Unknown Win32
        File type:        2.0 Dll
        File date:        00000000.00000000
        Translations:     0409.04b0
        CompanyName:      Microsoft Corporation
        ProductName:      Microsoft .NET Framework
        InternalName:     mscorwks.dll
        OriginalFilename: mscorwks.dll
        ProductVersion:   2.0.50727.4455
        FileVersion:      2.0.50727.4455 (QFE.050727-4400)
        FileDescription:  Microsoft .NET Runtime Common Language Runtime - WorkStation
        LegalCopyright:   Š Microsoft Corporation.  All rights reserved.
        Comments:         Flavor=Retail

For .NET4.x you need to check clr.dll (or the Release value under the `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full` key) and find it in the [Microsoft Docs](https://docs.microsoft.com/en-us/dotnet/framework/migration-guide/versions-and-dependencies).

## CLR Code Policies (obsolete)

List groups:

    caspol -l

Remove groups

    caspol remgroup 1.1.2.

Add FullTrust for a given path:

    caspol -m -q -ag All_Code -url c:\panel\bin\* FullTrust

To analyze policies applied to the assembly you may run (according to <http://msdn.microsoft.com/en-us/library/vstudio/tx1dts55(v=vs.100).aspx>):

    caspol all resolveperm assembly-file

    caspol enterprise resolveperm assembly-file
    caspol machine resolveperm assembly-file
    caspol user resolveperm assembly-file

