
.NET memory and GC debugging in VS
==================================

Observing object lifetimes
--------------------------

There are not many options available in VS debugger to monitor GC work. But one of the most interesting is Object Pinning. When you are stopped in the debugger you may right click on any object available in the scope (either in a watch windows or in source code) and from the context menu choose **Make Object ID**. Your object will be pinned in the debugger and will receive a unique numeric identifier. From this time on you may refer to it using the generated number followed by a hash character, eg. `1#`. This will work even when the object is not visible within the scope you are currently in. Places where you may use this syntax are for example: watch windows, immediate window, breakpoint condition expression or tracepoint message text (by using curly braces, eg. `{1#}`). Additionally, when the pinned object becomes collected it will show in the watch window as `(Disposed)`.

Example situations to profit from Object Pinning include:

- testing if the Dependency Injection framework releases objects according to our configuration (for example when request scope is used for ExampleManager instance: pin an instance of it in one request and in subsequent request check if the current instance is not the same as the pinned one: `1# != this.exampleManager`
- checking if threads are waiting on the same lock instance (by pinning the lock object) and then breaking on the `Monitor.Enter` call

Find a memory address of the .NET object
----------------------------------------

Probably not very well known feature of the **Memory Window** is the fact that you may drag on it objects from other windows. As shown in the [breakpoints section](vs-breakpoints.md) we may drag register values onto the Memory Window in order to check the pointers destination. We may also drag objects from the **Watch Windows** and their addresses in memory will be revealed.

Get GC Generation in which a given object resides
-------------------------------------------------

This one is pretty simple. Just use: `GC.GetGeneration(<object-name>)` in the Immediate or Watch Window - works only for objects in the current scope. In other cases you need to gather information about the memory boundaries of each GC segment and based on object addresses investigate in which generation they live (check the previous paragraph).

Force GC collection
-------------------

Just call `GC.Collect(<generation-number_or_nothing-to-run-collection-in-all-generations>)`.

