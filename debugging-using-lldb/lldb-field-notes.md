
# LLDB Field Notes

In this recipe:

- [System objects in the debugger](#system-objects-in-the-debugger)
  - [Processes](#processes)
  - [Threads](#threads)
- [Work with data](#work-with-data)
  - [Stack](#stack)
  - [Other memory commands](#other-memory-commands)
- [Controlling process execution](#controlling-process-execution)
  - [Controlling the target](#controlling-the-target)
  - [Breakpoints](#breakpoints)
- [Symbols and modules](#symbols-and-modules)

## System objects in the debugger

### Processes

Show information about the current status (**proc status**):

```
(lldb) proc st
Process 342 stopped
* thread #1, name = 'testapp', stop reason = breakpoint 1.1
    frame #0: 0x00007ffff7380697 libcoreclr.so`::PAL_GetTransportName(MAX_TRANSPORT_NAME_LENGTH=108, name="", prefix="dotnet-diagnostic", id=342, applicationGroupId=<unavailable>, suffix="socket") at process.cpp:2299:11
```

### Threads

List all threads (**thread list**):

```
(lldb) thread l
Process 342 stopped
* thread #1: tid = 342, 0x00007ffff7380697 libcoreclr.so`::PAL_GetTransportName(MAX_TRANSPORT_NAME_LENGTH=108, name="", prefix="dotnet-diagnostic", id=342, applicationGroupId=<unavailable>, suffix="socket") at process.cpp:2299:11, name = 'testapp', stop reason = breakpoint 1.1
  thread #2: tid = 459, 0x00007ffff7b7589d libc.so.6`syscall + 29, name = 'testapp-ust'
  thread #3: tid = 460, 0x00007ffff7b7589d libc.so.6`syscall + 29, name = 'testapp-ust'
  thread #4: tid = 461, 0x00007ffff7b6faff libc.so.6`__poll + 79, name = 'testapp'
```

Switch to the thread no. 2 (**thread select**):

```
(lldb) thread se 2
* thread #2, name = 'testapp-ust'
    frame #0: 0x00007ffff7b7589d libc.so.6`syscall + 29
libc.so.6`syscall:
->  0x7ffff7b7589d <+29>: cmpq   $-0xfff, %rax             ; imm = 0xF001
    0x7ffff7b758a3 <+35>: jae    0x7ffff7b758a6            ; <+38>
    0x7ffff7b758a5 <+37>: retq
    0x7ffff7b758a6 <+38>: movq   0xcf5c3(%rip), %rcx
```

## Work with data

### Registers

Show register values (**register read**) (notice that LLDB automatically tries resolving symbols for registers values):

```
(lldb) re read
General Purpose Registers:
       rax = 0xbf5a9058a65ad800
       rbx = 0x0000000000000ffc
       rcx = 0x0000000000000ffc
       rdx = 0x00007ffff740c97f  
       rdi = 0x000000000000006c
       ...
       r12 = 0x00007ffff706c650  libcoreclr.so`DiagnosticServer::Initialize()::$_1::__invoke(char const*, unsigned int) at diagnosticserver.cpp:139
       ...
```

Show the value of the rsi register (**register read**):

```
(lldb) re read rsi
     rsi = 0x00007fffffffcfca
```

### Variables and expressions

Evaluate an expression in LLDB and show the result in hex (**expression**):

```
(lldb) expr -f hex -- (0x00007f6a10013f80 + 0x28)
(long) $3 = 0x00007f6a10013fa8
```

### Stack

Show the current thread's call stack (**thread backtrace**):

```
(lldb) bt
* thread #2, name = 'testapp-ust'
  * frame #0: 0x00007ffff7b7589d libc.so.6`syscall + 29
    frame #1: 0x00007ffff6b8e15d liblttng-ust.so.0`___lldb_unnamed_symbol82$$liblttng-ust.so.0 + 909
    frame #2: 0x00007ffff7fa6609 libpthread.so.0`start_thread(arg=<unavailable>) at pthread_create.c:477:8
    frame #3: 0x00007ffff7b7c293 libc.so.6`__clone + 67
```

Show the call stacks of all the threads (**thread backtrace**):

```
(lldb) bt all
  thread #1, name = 'testapp', stop reason = breakpoint 1.1
    frame #0: 0x00007ffff7380697 libcoreclr.so`::PAL_GetTransportName(MAX_TRANSPORT_NAME_LENGTH=108, name="", prefix="dotnet-diagnostic", id=342, applicationGroupId=<unavailable>, suffix="socket") at process.cpp:2299:11
    ...
    frame #22: 0x0000555555558f8a testapp`___lldb_unnamed_symbol11$$testapp + 41
* thread #2, name = 'testapp-ust'
  * frame #0: 0x00007ffff7b7589d libc.so.6`syscall + 29
    frame #1: 0x00007ffff6b8e15d liblttng-ust.so.0`___lldb_unnamed_symbol82$$liblttng-ust.so.0 + 909
    frame #2: 0x00007ffff7fa6609 libpthread.so.0`start_thread(arg=<unavailable>) at pthread_create.c:477:8
    frame #3: 0x00007ffff7b7c293 libc.so.6`__clone + 67
  thread #3, name = 'testapp-ust'
    frame #0: 0x00007ffff7b7589d libc.so.6`syscall + 29
    frame #1: 0x00007ffff6b8e15d liblttng-ust.so.0`___lldb_unnamed_symbol82$$liblttng-ust.so.0 + 909
    frame #2: 0x00007ffff7fa6609 libpthread.so.0`start_thread(arg=<unavailable>) at pthread_create.c:477:8
    frame #3: 0x00007ffff7b7c293 libc.so.6`__clone + 67
```

Switch to the second call stack frame (**thread select**):

```
(lldb) fr s 2
frame #2: 0x00007ffff7fa6609 libpthread.so.0`start_thread(arg=<unavailable>) at pthread_create.c:477:8
```

Show the value of the `name` variable (**frame variable**):

```
(lldb) fr v name
(char *) name = 0x00007fffffffcb5a ""
```

### Other memory commands

Show the memory (bytes + ASCII) at the address of the `name` variable:

```
(lldb) mem rea -f Y &name
0x7fffffffc9c8: 5a cb ff ff ff 7f 00 00 91 b9 41 f7 ff 7f 00 00  Z.........A.....
0x7fffffffc9d8: 94 1e 22 f7 ff 7f 00 00 a0 74 7c 55 55 55 00 00  .."......t|UUU..
```

Show the value of the `name` variable as string:

```
(lldb) mem rea -f s name
0x7fffffffcb5a: ""
```

Show bytes and ASCI characters at the address pointed by the `rdx` register:

```
(lldb) mem read -f Y -c 20 $rdx
```

## Controlling process execution

### Controlling the target

Switch the frame to the parent one and disassembly the code (**disassembly**) (notice that LLDB marks the return address with `->`):

```
(lldb) frame s 1
frame #1: 0x00007ffff7272cbb libcoreclr.so`IpcStream::DiagnosticsIpc::Create(pIpcName=<unavailable>, mode=LISTEN, callback=(libcoreclr.so`DiagnosticServer::Initialize()::$_1::__invoke(char const*, unsigned int) at diagnosticserver.cpp:139))(char const*, unsigned int)) at diagnosticsipc.cpp:55:9
(lldb) dis
libcoreclr.so`IpcStream::DiagnosticsIpc::Create:
    0x7ffff7272b70 <+0>:   pushq  %rbp
    ...
    0x7ffff7272cb4 <+324>: movl   %eax, %ecx
    0x7ffff7272cb6 <+326>: callq  0x7ffff7380660            ; ::PAL_GetTransportName(const unsigned int, char *, const char *, DWORD, const char *, const char *) at process.cpp:2298
->  0x7ffff7272cbb <+331>: testl  %r14d, %r14d
    0x7ffff7272cbe <+334>: jne    0x7ffff7272bf2            ; <+130> at diagnosticsipc.cpp:71:30
    ...
```

Disassembly the `PAL_GetTransportName` function (**disassembly**):

```
(lldb) dis -n PAL_GetTransportName
libcoreclr.so`::PAL_GetTransportName(const unsigned int, char *, const char *, DWORD, const char *, const char *):
    0x7ffff7380660 <+0>:   pushq  %rbp
    0x7ffff7380661 <+1>:   movq   %rsp, %rbp
    0x7ffff7380664 <+4>:   pushq  %r15
    ...
```

Use **s** (**thread step-in**) to step into code and **si** (**thread step-inst**) to step into assembly instruction.

Continue execution until 

To continue execution until a specific address, use the **thread until -a {address}** command.

### Breakpoints

Set a pending breakpoint for a `PAL_GetTransportName` function (**breakpoint set**):

```
(lldb) break set -n PAL_GetTransportName
Breakpoint 1: no locations (pending).
WARNING:  Unable to resolve breakpoint to any actual locations.
```

Set a breakpoint at an address: `0x7ffff7272cbb` (**breakpoint set**):

```
(lldb) break set -a 0x7ffff7272cbb
Breakpoint 2: where = libcoreclr.so`IpcStream::DiagnosticsIpc::Create(char const*, IpcStream::DiagnosticsIpc::ConnectionMode, void (*)(char const*, unsigned int)) + 331 at diagnosticsipc.cpp:64:14, address = 0x00007ffff7272cbb
```

## Symbols and modules

List all modules in a process (**image list**):

```
(lldb) im list
[  0] AE3665AD-7887-1218-F2B4-4253E6119E5F-6F14A510 0x0000555555554000 /home/me/testapp/bin/Debug/net5.0/testapp
[  1] B18234D1-A8CC-926B-DC73-E72CF5C0915D-C4458D42 0x00007ffff7fcf000 /usr/lib/x86_64-linux-gnu/ld-2.31.so
[  2] 10D52F0F-47C5-6EB1-4391-D3BC5823A4CF-1BFC83A8 0x00007ffff7fce000 [vdso] (0x00007ffff7fce000)
[  3] 4FC5FC33-F442-9136-A494-C640B113D76F-610E4ABC 0x00007ffff7f9d000 /lib/x86_64-linux-gnu/libpthread.so.0
      /usr/lib/debug/.build-id/4f/c5fc33f4429136a494c640b113d76f610e4abc.debug
      ...
```

List modules with their base addressses (**image list**):

```
(lldb) im list -b -h
[  0] testapp 0x0000555555554000
[  1] ld-2.31.so 0x00007ffff7fcf000
[  2] [vdso] 0x00007ffff7fce000(0x00007ffff7fce000)
[  3] libpthread.so.0 0x00007ffff7f9d000
[  4] libdl.so.2 0x00007ffff7f97000
[  5] libstdc++.so.6 0x00007ffff7db6000
[  6] libm.so.6 0x00007ffff7c67000
...
```

List modules with information about symbol files (**image list**):

```
(lldb) im list -b -S
[  0] testapp
[  1] ld-2.31.so
[  2] [vdso] (0x00007ffff7fce000)
[  3] libpthread.so.0
      /usr/lib/debug/.build-id/4f/c5fc33f4429136a494c640b113d76f610e4abc.debug
[  4] libdl.so.2
[  5] libstdc++.so.6
[  6] libm.so.6
[  7] libgcc_s.so.1
...
```

Dump sections of the module file:

```
(lldb) image dump sections libcoreclr.so
Sections for '/usr/share/dotnet/shared/Microsoft.NETCore.App/5.0.2/libcoreclr.so' (x86_64):
  SectID     Type             Load Address                             Perm File Off.  File Size  Flags      Section Name
  ---------- ---------------- ---------------------------------------  ---- ---------- ---------- ---------- ----------------------------
  0xfffffffffffffffe container        [0x00007ffff6e9b000-0x00007ffff7519fe8)  r-x  0x00000000 0x0067efe8 0x00000000 libcoreclr.so.PT_LOAD[0]
  0x00000001 regular          [0x00007ffff6e9b238-0x00007ffff6e9b25c)  r--  0x00000238 0x00000024 0x00000002 libcoreclr.so.PT_LOAD[0]..note.gnu.build-id
  0x00000002 elf-dynamic-symbols [0x00007ffff6e9b260-0x00007ffff6e9d1e0)  r--  0x00000260 0x00001f80 0x00000002 libcoreclr.so.PT_LOAD[0]..dynsym
```

By using the **target.debug-file-search-paths** setting we can configure custom paths where we store the symbol files. For example, for .NET symbols we could have used the dotnet-symbols tool to download them: **dotnet-symbol --recurse-subdirectories --output /home/me/symbols/ /usr/share/dotnet/shared/Microsoft.NETCore.App/5.0.1/**. Now, we need to add this folder to the lldb search paths. We could do so by adding the following line to the **~/.lldbinit** file:

```
settings set target.debug-file-search-paths /home/me/symbols
```

To reload symbol information or add it, we should use the **target symbols add** (**add-dsym**) command:

```
(lldb) target symbols add /usr/lib/debug/lib/x86_64-linux-gnu/libc-2.31.so
symbol file '/usr/lib/debug/lib/x86_64-linux-gnu/libc-2.31.so' has been added to '/lib/x86_64-linux-gnu/libc.so.6'
```

Lookup an address of the `PAL_GetTransportName` function:

```
(lldb) im look -n PAL_GetTransportName
1 match found in /usr/share/dotnet/shared/Microsoft.NETCore.App/5.0.2/libcoreclr.so:
        Address: libcoreclr.so[0x00000000004e5660] (libcoreclr.so.PT_LOAD[0]..text + 4662656)
        Summary: libcoreclr.so`::PAL_GetTransportName(const unsigned int, char *, const char *, DWORD, const char *, const char *) at process.cpp:2298
```

Resolve an address to a symbol (**image lookup**):

```
(lldb) im look -va $rip
      Address: libcoreclr.so[0x00000000004e5697] (libcoreclr.so.PT_LOAD[0]..text + 4662711)
      Summary: libcoreclr.so`::PAL_GetTransportName(const unsigned int, char *, const char *, DWORD, const char *, const char *) + 55 at process.cpp:2299:11
       Module: file = "/usr/share/dotnet/shared/Microsoft.NETCore.App/5.0.2/libcoreclr.so", arch = "x86_64"
```
