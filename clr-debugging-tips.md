
CLR general debugging tips
==========================

Controlling JIT optimization
----------------------------

Assemblies can be compiled as optimized - JIT compiler takes `DebuggableAttribute` into consideration while generating the native code to execute.

### DebuggableAttribute ###

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

**<none>**

No Debuggable attribute emitted

### INI file ###

The ini file must have the same name as the executable with only extension changed to ini, eg. my.ini file will work with my.exe application.

    [.NET Framework Debugging Control]
    GenerateTrackingInfo=1
    AllowOptimize=0

Links
-----

- [.NET Debugging Quick Start -  a list of links for different parts of a .net debugging infrastructure](http://blogs.msdn.com/b/arvindsh/archive/2012/03/14/net-debugging-quick-start.aspx)
- [.NET Debugging for the Production Environment](http://channel9.msdn.com/Series/-NET-Debugging-Stater-Kit-for-the-Production-Environment)
- [.NET Debugging Starter Kit: for the Production Environment - 6 great videos about .NET and native debugging](http://channel9.msdn.com/Series/-NET-Debugging-Stater-Kit-for-the-Production-Environment)
- [Interesting library that binds github sources with solution](https://github.com/GeertvanHorrik/GitHubLink)
- [Defrag Tools #109 - Writing a CLR Debugger Extension Part 1](http://channel9.msdn.com/Shows/Defrag-Tools/Defrag-Tools-109-Writing-a-CLR-Debugger-Extension-Part-1)
- [Defrag Tools #110 - Writing a CLR Debugger Extension Part 2](http://channel9.msdn.com/Shows/Defrag-Tools/Defrag-Tools-110-Writing-a-CLR-Debugger-Extension-Part-2)
