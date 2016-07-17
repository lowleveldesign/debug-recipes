
.NET memory and GC debugging in VS
==================================

Observing object lifetimes
--------------------------

There are not many options available in VS debugger to monitor GC work. But one of the most interesting is Object Pinning. When you are stopped in the debugger you may right click on any object available in the scope (either in Watch Windows or in the source code) and from the context menu choose **Make Object ID**. Your object will be pinned in the debugger and will receive a unique numeric identifier. From this time on you may refer to it using the generated number followed by a hash character, eg. `1#`. This will work even when the object is not visible within the scope you are currently in. Places where you may use this syntax are for example: Watch Windows, Immediate Window, breakpoint condition expression or tracepoint message text (by using curly braces, eg. `{1#}`). Additionally, when the pinned object becomes collected it will appear in the watch window as `(Disposed)`.

Example situations to profit from Object Pinning include:

- testing if the Dependency Injection framework releases objects according to our configuration (for example when request scope is used: pin an instance of some object in one request and in subsequent request check if the current instance is not the same as the pinned one: `1# != this.exampleManager` or force GC Collection and check if the pinned instance was disposed)
- checking if threads are waiting on the same lock instance (by pinning the lock object) and then breaking on the `Monitor.Enter` call

Find the memory address of an object
-------------------------------------

Probably not very well known feature of the **Memory Window** is the fact that you may drag on it objects from other windows. As shown in the [breakpoints section](vs-breakpoints.md) we may drag register values onto the Memory Window in order to check the pointers destination. We may also drag objects from the **Watch Windows** and their addresses in memory will be revealed.

When you would like to disassemly an exported function in 64-bit debugger (and you have no symbols loaded) you need to use the native breakpoint syntax, eg. `{,,kernel32}LoadLibraryA`. When debugging 32-bit app things get a bit trickier as you need to know the raw name of the function, eg.: `{,,kernel32}LoadLibraryA@4`.

Get GC Generation in which a given object resides
-------------------------------------------------

This one is pretty simple. Just use: `GC.GetGeneration(<object-name>)` in the Immediate or Watch Window - works only for objects in the current scope.

Force GC collection
-------------------

Just call `GC.Collect(<generation-number_or_nothing-to-run-collection-in-all-generations>)` in the Immediate or Watch Window.

