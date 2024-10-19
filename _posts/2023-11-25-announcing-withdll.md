---
layout: post
title:  'withdll - a tool to inject DLLs into remote processes'
date:   2023-11-25 08:00:00 +0200
permalink: /2023/11/25/withdll-dll-injection-tool/
---

I am happy to share with you a new open-source troubleshooting utility: **withdll**. I created it inspired by one of the samples in the [Detours](https://github.com/microsoft/Detours) library with the same name. Withdll is a small tool, written in C#, that can **inject DLLs into newly started or already running Windows processes** (both 32- and 64-bit). If you are wondering why you may want to load a DLL into a remote process, think of those two example scenarios: patching some code in a remote process memory or collecting a trace of function calls made by a remote process. For the latter scenario, I prepared [a short guide](https://wtrace.net/guides/using-withdll-and-detours-to-trace-winapi/) in which I present how you may use Detours sample libraries to collect traces of Win API calls. The withdll source code is available in [its GitHub repository](https://github.com/lowleveldesign/withdll).

<br />
*PS. If you need to interact with native libraries on Windows, I highly recommend checking the [CsWin32 project](https://github.com/microsoft/CsWin32). It helped me tremendously in generating the C# bindings for the Detours library. In case you are interested, I described the whole process in [a post on my blog](https://lowleveldesign.wordpress.com/2023/11/23/generating-c-bindings-for-native-windows-libraries/).*
