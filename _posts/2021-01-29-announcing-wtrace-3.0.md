---
layout: post
title:  Announcing wtrace 3.0
date:   2021-01-29 14:00:00 +0200
permalink: /2021/01/29/announcing-wtrace-3-0/
---

After weeks of work, I am happy to announce the new release of wtrace. The **3.0 version** is a complete rewrite, with many fixes and new features.

One of the most significant changes is the possibility to **collect traces system-wide**. If you don’t provide a file path or PID, wtrace will trace all the processes. To keep the number of trace events acceptable, consider using one of the [extensive filtering options](/documentation/wtrace/#filtering-events) (a new feature, too!).

You may also choose the [event handlers](/documentation/wtrace/#event-handlers) for each session. The sensible default set includes process, file, RPC, and TCP handlers. The 3.0 version introduces a **Registry** event handler, so if you enable it, you may trace Registry operations with wtrace! I plan to add handlers for less common event types in future releases, too.

The **summary** section got a new view that displays a process tree. When tracing system-wide or system-only, the tree includes all the running processes. In other modes, you will see the parent process and all its descendants.

![](/assets/img/wtrace-process-tree.png)

The missing file paths are no longer a prevalent issue. And wtrace can finally run in a Windows container (thanks to updates in the [TraceEvent](https://github.com/microsoft/perfview/) library).

Unfortunately, I needed to drop support for ALPC and PowerShell events. In the previous versions of wtrace, I tried to match ALPC connections with the RPC ones, but it never worked reliably. Similarly, the PowerShell event handler had much to improve. I want to revive those handlers, but I need to be sure that they present accurate data. And that requires some more research.

Finally, wtrace has its homepage now: <https://wtrace.net>, and I hope that soon new utilities will join its [Tools](/tools) section.

Get the new version from the [release page](https://github.com/lowleveldesign/wtrace/releases/tag/3.0) and start (w)tracing! 😃
