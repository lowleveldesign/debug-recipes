---
layout: post
title:  Announcing dotnet-wtrace 1.0
date:   2021-07-03 15:00:00 +0200
permalink: /2021/07/03/announcing-dotnet-wtrace-1-0/
---

I am happy to announce that the first version of **dotnet-wtrace** is available for download 🎉️ Like wtrace, it is an **open-source**, command-line tool that collects process traces in real-time and displays them in the standard output. However, dotnet-wtrace focuses only on events coming from .NET applications. It uses EventPipe to read runtime and application events and works with .NET Core applications (2.1+) on all the supported platforms.

The reasoning for creating dotnet-wtrace was that I could not find any tool that will show me .NET trace events in real-time. Until now, we could only record the trace (using dotnet-trace or PerfView) and later analyze it. Of course, this approach works in all situations, but sometimes it could be a bit tedious, especially for easy-to-diagnose bugs, such as swallowed exceptions or networking problems. Dotnet-wtrace should help in such cases, quickly pointing you to the error details. It is not meant to replace dotnet-trace or PerfView, but rather help in the initial phases of diagnosing problems. That’s why it does not simply dump all event details but preprocess them and extracts only the most interesting bits, making the output human-readable. Dotnet-wtrace includes multiple event handlers, each one of them handling a specific event category (such as GC, network, loader, or ASP.NET Core events). An example output looks as follows:

![](/assets/img/dotnet-wtrace-example-output.png)

As in wtrace, you may choose the handlers and specify event filters through the command-line options. Please have a look at the [documentation](/documentation/dotnet-wtrace) to learn more.

I hope I convinced you to give dotnet-wtrace a try. You may install it as one of the dotnet tools:

```
dotnet tool install -g dotnet-wtrace
```

Or download the precompiled binaries from its [repository release page](https://github.com/lowleveldesign/dotnet-wtrace/releases).

Happy tracing and until the next time! 🧐️
