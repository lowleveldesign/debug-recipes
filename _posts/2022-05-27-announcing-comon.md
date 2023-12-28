---
layout: post
title:  'comon - a new project in the wtrace toolkit'
date:   2022-05-27 06:30:00 +0200
permalink: /2022/05/27/comon-a-new-project-in-the-wtrace-toolkit/
---

Almost five months ago, I wrote [an article on implementing COM+ code](https://lowleveldesign.org/2022/01/17/com-revisited/), in which I promised a new troubleshooting tool in the wtrace toolkit. Today, I am pleased to present it to you! It’s an [open-source](https://github.com/lowleveldesign/comon) Windbg extension named **comon**.  You may use it to investigate COM class interactions and better understand application logic. During a debugging session, comon will record virtual table addresses (for the newly created COM objects) and allow you to query them or even set breakpoints (**!cobp**) on COM interface methods. 

The **!cometa** command parses COM metadata found in the registry or standalone TLB/DLL files. Thanks to the metadata, comon will decode CLSIDs and IIDs to their human-friendly names. You may also query the metadata with the **showc** or **showi** subcommands.

Here is a short snippet of a debugging session with comon:

```
0:000> .load c:\Users\me\Debugging Tools for Windows\extensions-x86\comon.dll
[comon] Opening an existing metadata database from 'C:\Users\me\AppData\Local\Temp\cometa.db3'.

0:000> !comon attach
[comon] COM monitor enabled for process 0.

0:000> !cometa showi {59644217-3E52-4202-BA49-F473590CC61A}
Found: {59644217-3E52-4202-BA49-F473590CC61A} (IGameObject)

Methods:
- [0] QueryInterface
- [1] AddRef
- [2] Release
- [3] get_Name
- [4] get_Minerals
- [5] get_BuildTime

Registered VTables for IID:
- Module: protoss (32-bit), CLSID: {EFF8970E-C50F-45E0-9284-291CE5A6F771} (Protoss Probe), VTable offset: 0x37854
- Module: protoss (32-bit), CLSID: {F5353C58-CFD9-4204-8D92-D274C7578B53} (Protoss Nexus), VTable offset: 0x37808

0:000> sxe ld:protoss.dll
0:000> g
...
ModLoad: 70290000 702d4000   c:\Users\me\repos\protoss-com-example\Debug\protoss.dll
ntdll!NtMapViewOfSection+0xc:
774a4e7c c22800          ret     28h
0:000> !cobp {F5353C58-CFD9-4204-8D92-D274C7578B53} {59644217-3E52-4202-BA49-F473590CC61A} get_Name
0:000> bl
     8 e Disable Clear  702a1505     0001 (0001)  0:**** protoss!ILT+1280(?get_NameNexusUAGJPAPA_WZ) "..."
0:000> g
...
[comon] 0:000 [IUnknown::QueryInterface] CLSID: {EFF8970E-C50F-45E0-9284-291CE5A6F771} (Protoss Probe), IID: {00000001-0000-0000-C000-000000000046} (IClassFactory)
[comon] 0:000 [IUnknown::QueryInterface] CLSID: {EFF8970E-C50F-45E0-9284-291CE5A6F771} (Protoss Probe), IID: {00000001-0000-0000-C000-000000000046} (IClassFactory)
[comon] 0:000 [combase!CoGetClassObject] CLSID: {EFF8970E-C50F-45E0-9284-291CE5A6F771} (Protoss Probe), IID: {00000001-0000-0000-C000-000000000046} (IClassFactory)
[comon] 0:000 [IUnknown::QueryInterface] CLSID: {EFF8970E-C50F-45E0-9284-291CE5A6F771} (Protoss Probe), IID: {246A22D5-CF02-44B2-BF09-AAB95A34E0CF} (IProbe)
[comon] 0:000 [IUnknown::QueryInterface] CLSID: {EFF8970E-C50F-45E0-9284-291CE5A6F771} (Protoss Probe), IID: {59644217-3E52-4202-BA49-F473590CC61A} (IGameObject)
[comon] 0:000 [IUnknown::QueryInterface] CLSID: {F5353C58-CFD9-4204-8D92-D274C7578B53} (Protoss Nexus), IID: {59644217-3E52-4202-BA49-F473590CC61A} (IGameObject)

== Method get_Name [3] called on a COM object (CLSID: {59644217-3E52-4202-BA49-F473590CC61A} (IGameObject), IID {F5353C58-CFD9-4204-8D92-D274C7578B53} (Protoss Nexus)) ==
0:000> k
 # ChildEBP RetAddr  
00 0095f540 004e482a protoss!ILT+1280(?get_NameNexusUAGJPAPA_WZ)
```

If you're working with COM (or debugging Windows applications), I believe that comon will benefit your work. So comon, give it a try 😊 The latest binaries are on the [release page](https://github.com/lowleveldesign/comon/releases) and the documentation is [here](https://wtrace.net/documentation/comon/).
