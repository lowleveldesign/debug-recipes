---
layout: page
title: Guides
---

Please first check the [Windows degugging configuration guide](configuring-windows-for-effective-troubleshooting) as it presents fundamental settings and tools for effective problems troubleshooting on Windows. Similarly, I published the [Linux debugging configuration guide](configuring-linux-for-effective-troubleshooting) (work in progress).

### :triangular_ruler: Troubleshooting scenarios

#### [Diagnosing .NET applications](diagnosing-dotnet-apps)

This guide describes ways of troubleshooting various problems in .NET applications, such as high CPU usage, memory leaks, network issues, etc.

#### [Diagnosing native Windows applications](diagnosing-native-windows-apps)

This guide describes ways of troubleshooting various problems in native applications on Windows, such as high CPU usage, hangs, abnormal terminations, etc.

#### [COM troubleshooting](com-troubleshooting)

A guide presenting troubleshooting techniques and tools (including the [comon extension](https://github.com/lowleveldesign/comon)) useful for debugging COM objects.

### :wrench: Tools usage

#### [WinDbg usage guide](windbg)

My field notes describing usage of WinDbg and WinDbgX (new WinDbg).

#### [GDB usage guide](gdb)

My field notes describing usage of GDB.

#### [Event Tracing for Windows (ETW)](etw)

This guide describes how to collect and analyze ETW traces.

#### [Linux Kernel Tracing](linux-tracing)

The guide presents tracing frameworks available through `/sys/kernel/tracing` mount point.

#### [eBPF](ebpf)

The guide describes how to use eBPF to trace system and application events.

#### [Network tracing tools](network-tracing-tools)

This guide lists various network tools you may use to diagnose connectivity problems and collect network traces on Windows and Linux.

#### [Windows Performance Counters](windows-performance-counters)

The guide presents how to query Windows Performance Counters and analyze the collected data.

#### [Using withdll and detours to trace Win API calls](using-withdll-and-detours-to-trace-winapi)

This guide describes how to use [withdll](https://github.com/lowleveldesign/withdll) and [Detours](https://github.com/microsoft/Detours) samples to collect traces of Win API calls.
