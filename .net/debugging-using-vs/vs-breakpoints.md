
Breakpoints and tracepoints in .NET code
========================================

Breakpoint locations
--------------------

You may set a breakpoint on **any .NET function** (assuming Just my code is disabled) - just press Ctrl + B and in the Function text field type the full path to the desired function, eg. `System.Console.WriteLine`. Unfortunately this won't work for anonymouns methods. For generic types use the type you are interested in, eg. `System.Collections.Generic.Dictionary<String, String>.Insert`. Visual Studio might then display a warning that the function was not found, but for now you may skip it. After you start debugging your breakpoint should look as follows:

![valid-break](vs-breakpoints-validbreakpoint.PNG)

When the method is optimized (inlined for instance) or when VS debugger was unable to find the function the breakpoint will be disabled:

![invalid-break](vs-breakpoints-invalidbreakpoint.PNG)

and VS will display an error dialog.

Breakpoint - something more than stop
--------------------------------------

Breakpoints have some very interesting features, among them the **Condition** expression which is evaluated each time the breakpoint is hit and based on its value (true or false) the debugger breaks into the application. The condition evaluator is the same one as in the Watch window so you may use in it pinned objects - this might be useful when you would like to stop when a specific lock is taken, eg.: `1# == this.lockObj`.

Another option, which might be interesting when debugging errors in loops or recursive calls, is the **Hit Count**. You may define that the debugger should break the execution only when the breakpoint was hit the n-th time, or every n times.

Tracepoint - break to trace
---------------------------

I love tracepoints, especially when you are debugging application that do not provide any logs. Tracepoints are breakpoints that do not break and their main job is to provide you with information what the application is doing. They can be conditional (as described above) and they also have the hit count.

One example situation when tracepoints are very useful is debugging the duplicate key insert error in a dictionary. The default framework exception does not tell you which key generated the problem. You may then set a tracepoint on `System.Collections.Generic.Dictionary<String, String>.Insert` with **When Hit** set to *Inserted key: {key}* and when the exception occurs Immediate (or Output) window will show you which key caused the problem. As you can imagine tracepoints are another way to diagnose issues with:

- concurrency - you may control which threads executes a given part of code at given time
- exceptions - as in our example you may dump in the trace all the information required to diagnose the specific problem
- locks - you may dump information who acquired a given lock and when
- method order execution - setting tracepoints in an application you don't know will help you better understand the code execution flow

and many more. Tracepoints which are often hit might have an impact on the application performance - in such a case you should consider setting breakpoints before the critical sections and enabling tracepoints only for the section execution.

