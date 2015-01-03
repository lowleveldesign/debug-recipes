
JIT configuration for debugging
===============================

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

