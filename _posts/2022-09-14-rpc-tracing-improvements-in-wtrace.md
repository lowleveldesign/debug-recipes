---
layout: post
title:  'RPC tracing improvements in wtrace 3.3'
date:   2022-09-14 08:00:00 +0200
redirect_from:
  - /2022/12/14/comon-a-new-project-in-the-wtrace-toolkit/
---

[Wtrace](https://github.com/lowleveldesign/wtrace) collected **RPC events** almost from its beginning (version 1.2). This functionality was implemented through a generated [Microsoft-Windows-RPC ETW event parser](https://github.com/lowleveldesign/wtrace/blob/master/wtrace.imports/Parsers/Microsoft-Windows-RPC.cs). Thanks to the RPC ETW events, we could learn some information about RPC calls happening in our system, including their endpoint names, protocols, interface UUIDs, and procedure numbers. An example RPC event in the wtrace output might look as follows:

```
11:42:41.7551 winver (9620.13744) RPC/ClientCallStart 'fb8a0729-2d04-4658-be93-27b4ad553fac (lsapolicylookup) [0]'
```

And in the summary view, we would see the number of calls to a given RPC procedure:

```
--------------------------------
              RPC
--------------------------------
fb8a0729-2d04-4658-be93-27b4ad553fac (lsapolicylookup) [5] calls: 4
```

One thing that was missing in this output was the procedure name. Until now, I recommended using [RpcView](http://rpcview.org/) to decode it. RpcView is an excellent tool, but its binaries are not always available, and you may not have time (or possibility) to build it. Fortunately, some time ago [James Forshaw](https://twitter.com/tiraniddo) added support for RPC servers to his excellent [NtApiDotNet library](https://github.com/googleprojectzero/sandbox-attacksurface-analysis-tools). Querying RPC information is only a tiny part of the library, but it is all I needed for wtrace. Additionally, you may call some of the NtApiDotNet functions in PowerShell by using the [NtObjectManager](https://www.powershellgallery.com/packages/NtObjectManager) package. Check out [this post](https://googleprojectzero.blogspot.com/2019/12/calling-local-windows-rpc-servers-from.html) on the Google Zero Project blog if you're interested.

Moving back to wtrace, thanks to NtApiDotNet, wtrace 3.3 will try to resolve RPC procedure names in the summary view. I will later describe how it's done, but first, let's have a look at the final result. Instead of seeing:

```
--------------------------------
              RPC
--------------------------------
fb8a0729-2d04-4658-be93-27b4ad553fac (lsapolicylookup) [5] calls: 4
```

We will now see:

```
--------------------------------
       RPC (client calls)
--------------------------------
fb8a0729-2d04-4658-be93-27b4ad553fac (ncalrpc:[lsapolicylookup]) [5]{LsaLookuprGetDomainInfo} calls: 2
```

As you may have noticed, RPC calls are now split between server and client calls, and wtrace prints the procedure name (in curly braces) next to its number. Displaying meaningful procedure names requires access to the debugging symbols. If you have the `_NT_SYMBOL_PATH` environment variable set (I highly recommend configuring it), wtrace will use it. Otherwise, you need to set debugging symbols path through the `--symbols` parameter, for example:

```
wtrace.exe --symbols="SRV*C:\symbols\*https://msdl.microsoft.com/download/symbols" -v notepad.exe
```

The procedure resolution works only for local RPC servers. Apart from RPC parsing improvements, wtrace 3.3 includes minor fixes and optimizations, so give it a try the next time you need to trace something in the system.

If you're willing to learn a bit more about how RPC name resolution works, the next section is for you :)

### How procedure name resolution works?

The payload of the RPC ETW event gives us enough data to build a binding name (`constructBinding` method in the wtrace RPC event handler). With the binding name, we may query its published interfaces using the `RpcEndpointMapper.QueryEndpointsForBinding` method from NtApiDotNet. Under the hood, it calls [`RpcMgmtInqIfIds`](https://docs.microsoft.com/en-us/windows/win32/api/rpcdce/nf-rpcdce-rpcmgmtinqifids). For each retrieved interface, NtApiDotNet builds a `RpcEndpoint` object by calling a family of [`RpcMgmtEpEltInq*`](https://docs.microsoft.com/en-us/windows/win32/api/rpcdce/nf-rpcdce-rpcmgmtepeltinqbegin) functions, providing the interface UUID and version. In the next step, we need to learn which process hosts a given endpoint. This part is a bit complicated and depends on the protocol used in the communication. Check the `_factories` dictionary in the `RpcClientTransportFactory` class to learn how NtApiDotNet constructs various connection points. When we know the process ID, it's time to search through process modules, looking for NDR structures. The `RpcServer.ParsePeFile` method parses a DLL/EXE file and, among many other things, retrieves information about the RPC interface procedure addresses. With the symbols available, we can then decode their names. As you can imagine, resolving every RPC binding is a time-consuming process. I do that asynchronously in background threads (`RpcResolver` class), but it could happen, especially when the trace session is short, that wtrace will require some additional time to finish resolving the queued endpoint names.
