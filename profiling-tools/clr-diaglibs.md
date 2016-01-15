
.NET libraries for diagnosing
------------------------------

### CLRMD (Microsoft.Diagnostics.Runtime) ###

Library repo: <https://github.com/Microsoft/clrmd>
Nuget: <https://www.nuget.org/packages/Microsoft.Diagnostics.Runtime>

Microsoft.Diagnostics.Runtime.dll (nicknamed "CLR MD") is a process and crash dump introspection library. This allows you to write tools and debugger plugins which can do thing similar to SOS and PSSCOR.

Links:

- [Using CLRMD to replace KD/CDB/NTSD and maybe WinDbg?](http://blogs.microsoft.co.il/pavely/2015/05/14/using-clrmd-to-replace-kdcdbntsd-and-maybe-windbg/)
- [Sasha Goldstein's slides and demos from CLRMD at DotNext](https://twitter.com/goldshtn/status/675326898000535552)

### Microsoft.Diagnostics.Tracing.Logging ###

Library repo: <https://github.com/Microsoft/Microsoft.Diagnostics.Tracing.Logging>
Nuget: <https://www.nuget.org/packages/Microsoft.Diagnostics.Tracing.TraceEvent>

The TraceEvent library conains the classes needed to control ETW providers (including EventSources) and parse the events they emit.

### BenchmarkDotNet ###

Library repo: <https://github.com/PerfDotNet/BenchmarkDotNet>
Nuget: <https://www.nuget.org/packages/BenchmarkDotNet/>

BenchmarkDotNet is a lightweight .NET library for benchmarking.

### BenchmarkIt ###

Library repo: <https://github.com/bodyloss/BenchmarkIt>
Nuget: <https://www.nuget.org/packages/Benchmark.It>

Simple easy .NET benchmarking for little bits of code. When you just really want to see if one method is actually faster than another.
