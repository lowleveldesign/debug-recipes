
Identify network problems in memory dumps
-----------------------------------------

### Find undisposed ConnectStreams ###

We are checking if the `m_DoneCalled` (offset 0x54) property is not set:

```
.foreach (addr {!DumpHeap -type System.Net.ConnectStream -short}) { .if (not dwo( addr + 54)) { !do addr; }}
```

### Find connections with number of waiting requests > 0 ###

We are checking if size (offset 0xc) of the `m_WaitList` (offset 0x5c) is greater than zero:

```
0:000> !Name2EE System.dll!System.Net.Connection
Module:      71b51000
Assembly:    System.dll
Token:       020004e9
MethodTable: 71d75b24
EEClass:     71b737c4
Name:        System.Net.Connection
0:000> .foreach (addr {!DumpHeap -mt 71d75b24 -short}) { .if (dwo(poi( addr + 5c ) + c)) { !do addr } }
```
