---
layout: page
title: GDB usage guide
date: 2025-05-27 08:00:00 +0200
redirect_from:
    - /guides/gdb/
---

{% raw %}


**Table of contents:**

<!-- MarkdownTOC -->

- [Configuration](#configuration)
    - [.gdbinit](#gdbinit)
    - [ptrace capability](#ptrace-capability)
- [TUI](#tui)
- [Symbols](#symbols)
    - [Searching for symbols and addresses](#searching-for-symbols-and-addresses)
    - [Searching for source code](#searching-for-source-code)
- [Debugging child processes](#debugging-child-processes)
- [Execution Control](#execution-control)
    - [Process startup](#process-startup)
    - [Breakpoints and catchpoints](#breakpoints-and-catchpoints)
    - [Code execution](#code-execution)
    - [Signals](#signals)
- [State Control](#state-control)
    - [Process information](#process-information)
    - [Threads](#threads)
    - [Shared libs](#shared-libs)
    - [Stack](#stack)
    - [Code and Assembler](#code-and-assembler)
    - [Memory](#memory)
    - [Expressions \(variables, registers, etc.\)](#expressions-variables-registers-etc)
- [Extensions](#extensions)
    - [Python interpreter](#python-interpreter)
    - [GUI / CUI](#gui-cui)

<!-- /MarkdownTOC -->

Configuration
-------------

### .gdbinit

It's worth enabling the following elements permanently in the `~/.gdbinit` file:

```shell
# show disassembly on every stop and use intel syntax
set disassembly-flavor intel
set disassemble-next-line on

# enable debuginfod
set debuginfod enable on

# stop on forking and exceptions
catch fork
catch vfork
catch throw
catch rethrow
```

We may check the debuginfod settings in GDB:

```
(gdb) show debuginfod
debuginfod enabled:  Debuginfod functionality is currently set to "ask".
debuginfod urls:  Debuginfod URLs have not been set.
debuginfod verbose:  Debuginfod verbose output is set to 1.
```

### ptrace capability

To ptrace any process, you may add ptrace capability to gdb:

```shell
sudo setcap cap_sys_ptrace=eip $(which gdb)
```

TUI
---

This is a windowed interface for GDB. We enable/disable it using **Ctrl-x a**. **Ctrl-x 1** enables single-window mode, **Ctrl-x 2** enables two-window mode. The `tui layout` command determines what appears in the windows, e.g.:

```shell
tui layout split
tui layout src
```

**Ctrl-x o** allows us to switch between active debugger windows.

Symbols
-------

### Searching for symbols and addresses

`info address` finds the symbol associated with a given memory address, `info symbol` finds the address associated with a given symbol, for example:

```shell
info address lo_getattr
# Symbol "lo_getattr" is a function at address 0x555555556af0.

info symbol 0x555555556af0
# lo_getattr in section .text of /tmp/passthrough-minimal/passthrough_ll
```

`info types` searches for type declarations (accepts regexes). For functions we have `info functions` e.g.:

```shell
info functions statx
# All functions matching regular expression "statx":
# 
# File ../sysdeps/unix/sysv/linux/statx.c:
# 25: int statx(int, const char *, int, unsigned int, struct statx *);
# 
# File ./statx_generic.c:
# 42: static int statx_generic(int, const char *, int, struct statx *, unsigned int);
```

`ptype` allows viewing the definition of a given type. As a parameter we can provide either the type name or a variable of that type, e.g.:

```shell
ptype struct link_map
# type = struct link_map {
#     Elf64_Addr l_addr;
#     char *l_name;
#     Elf64_Dyn *l_ld;
#     struct link_map *l_next;
#     struct link_map *l_prev;
#     struct link_map *l_real;
#     Lmid_t l_ns;
#     ...
# }
```

`info scope` - shows symbols currently available in a given scope, e.g. for function `match_symbol`:

```shell
info scope match_symbol 
# Scope for match_symbol:
# Symbol digits is optimized out.
# Symbol _itoa_word is a function at address 0x7ffff7fda11a, length 1.
# Symbol value is multi-location:
#   Range 0x7ffff7fda21c-0x7ffff7fda220: a variable in $rcx
#   Range 0x7ffff7fda240-0x7ffff7fda26f: a variable in $rcx
#   Range 0x7ffff7fda26f-0x7ffff7fda275: a variable in $rdx
# , length 8.
# Symbol buflim is multi-location:
#   Range 0x7ffff7fda21c-0x7ffff7fda220: a complex DWARF expression:
#      0: DW_OP_fbreg -109
#      3: DW_OP_stack_value
# 
#   Range 0x7ffff7fda220-0x7ffff7fda275: a variable in $rsi
# , length 8.
# Symbol base is multi-location:
#   Range 0x7ffff7fda21c-0x7ffff7fda275: the constant 10
# , length 4.
# Symbol upper_case is multi-location:
#   Range 0x7ffff7fda21c-0x7ffff7fda275: the constant 0
# , length 4.
# Symbol digits is optimized out.
```

### Searching for source code

The `directory` command allows us to add additional directories for the source code:

```shell
show directories 
# Source directories searched: $cdir:$cwd

directory /tmp/openssl-0.9.8-easy_tls-orig/
# Source directories searched: /tmp/openssl-0.9.8-easy_tls-orig:$cdir:$cwd
```

Debugging child processes
-------------------------

`set detach-on-fork off` makes the debugger debug both the parent and its fork. If we don't enable this, we can decide what happens at fork using `set follow-fork-mode`. The `parent` option will cause the debugger to continue debugging the parent. The `child` option will switch to the child.

At the moment of fork, it's possible that `continue` won't work. We then need to allow both parent and child to execute simultaneously using `set schedule-multiple on`.

We can view currently debugged processes with the `info inferiors` command, and switch between them with `inferior {ID}`.

Execution Control
-----------------

### Process startup

GDB takes the debugged binary as an argument. Then we can add startup arguments with the `run` command. It also accepts stdin redirection from any file, e.g.:

```shell
r mytestapp < /tmp/test_file
```

### Breakpoints and catchpoints

`b func_name` sets a breakpoint on a function, `b file:line_num` sets a breakpoint on a line.

Additionally, we have special breakpoints called catchpoints for handling events (somewhat similar to `sxe` in WinDbg), e.g. `catch fork` to stop the debugger at fork:

```shell
catch fork
# Catchpoint 1 (fork)

info breakpoints 
# Num     Type           Disp Enb Address            What
# 1       catchpoint     keep y                      fork
# 2       breakpoint     keep y   0x00000000004044f0 in main at test.c:38
#     breakpoint already hit 1 time

# Catchpoint 1 (forked process 5473), arch_fork (ctid=0x7ffff7ca8690) at ../sysdeps/unix/sysv/linux/arch-fork.h:50
# 50    ret = INLINE_SYSCALL_CALL (clone, flags, 0, NULL, ctid, 0);
# => 0x00007ffff7db9b57 <__GI__Fork+39>:  48 3d 00 f0 ff ff   cmp    rax,0xfffffffffffff000
#    0x00007ffff7db9b5d <__GI__Fork+45>:  77 39               ja     0x7ffff7db9b98 <__GI__Fork+104>
# set detach-on-fork off
c
# Continuing.
# [New inferior 2 (process 5473)]
# [Thread debugging using libthread_db enabled]
# Using host libthread_db library "/usr/lib/libthread_db.so.1".
```

The `catch` command alone will display available events (similar to `sx` in WinDbg).

`rb function_regex` allows setting breakpoints based on regular expressions:

```shell
rb ssl_shim::wrapped_.*

# Breakpoint 2 at 0x7ffff7f741cd: file src/lib.rs, line 308.
# fn ssl_shim::wrapped_SSL_CTX_check_private_key(*mut ssl_shim::ssl::ssl_ctx_st) -> i32;
# Breakpoint 3 at 0x7ffff7f74539: file src/lib.rs, line 406.
# fn ssl_shim::wrapped_SSL_CTX_ctrl(*mut ssl_shim::ssl::ssl_ctx_st, i32, i64, *mut core::ffi::c_void) -> i64;
# Breakpoint 4 at 0x7ffff7f73b4e: file src/lib.rs, line 124.
# fn ssl_shim::wrapped_SSL_CTX_free(*mut ssl_shim::ssl::ssl_ctx_st);
# Breakpoint 5 at 0x7ffff7f73f0d: file src/lib.rs, line 226.
# fn ssl_shim::wrapped_SSL_CTX_get_client_CA_list(*mut ssl_shim::ssl::ssl_ctx_st) -> *mut ssl_shim::ssl::stack_st_X509_NAME;
# ...
```

`info break` lists the breakpoints and catchpoints. `disable ID` disables the breakpoint, `enable ID` enables the breakpoint, `del ID` deletes the breakpoint.

`commands ID` allows us to assign a command to a breakpoint:

```shell
b easy-tls.c:991

info b
# Num     Type           Disp Enb Address    What
# 1       breakpoint     keep y   <PENDING>  easy_tls.c:991

commands 1
# Type commands for breakpoint(s) 1, one per line.
# End with a line saying just "end".
>print r
>end
```

`watch {var}` - break if the value of the variable changes

### Code execution

| Command             | Description |
|---------------------|-------------|
| `r {args}`          | (re)run the program |
| `s`                 | step in |
| `n`                 | step over |
| `u`                 | until the next line (for example, to exit the loop) |
| `c`                 | continue |
| `ret {return_code}` | return from the current function |
| `j {line}`          | jump to a given line |

`info registers` - current register state for the selected stack frame

`info threads` - list the active threads  
`thread {num}` - switch focus to thread `{num}`

`info inferiors` - list the debugged processes (when `detach-on-fork` is `off`)  
`inferior {num}` - switch focus to a process `{num}`

### Signals

The debugger intercepts some signals (e.g. SIGINT) and handles them. To send such a signal to the application we can use the `signal` command, e.g. `signal SIGINT`.

State Control
-------------

### Process information

We can view currently debugged processes with the `info inferiors` command, and switch between them with `inferior {ID}`.

`info proc` and its subcommands provide insight into the internals of the executing process, e.g.:

```shell
info proc
# process 10372
# cmdline = '/tmp/easy_tls_0_9_8o_stripped'
# cwd = '/tmp'
# exe = '/tmp/easy_tls_0_9_8o_stripped'
```

### Threads

`info threads` to list the threads, `thread ID` to switch to a thread.

We can also execute a command on all the threads by using: `thread apply all`, for example `thread apply all bt`.

### Shared libs

`info proc exe` shows information about the main module

`info dll` - shows the status of loaded libraries

### Stack

`bt` - shows the stack

`f {num}` - selects a stack frame `{num}` as active
`up` or `down` - moves up or down the stack

### Code and Assembler

`list` shows the current location in sources. You can also list a function by passing its name as parameters.

`disassemble /s` shows the assembly code of the current function along with source code, if available. You can provide start and end addresses of any location in memory as parameters.

### Memory

`x` (examine)

`mem read -tdouble -c10 arr` - read a count of 10 items of type double from an array

`info proc mappings` lists memory regions occupied by the process.

### Expressions (variables, registers, etc.)

`info local` - show local variables  
`info args` - show all arguments to the function  
`info vars` - show all local variables

`print EXP` allows executing a given expression and saving the result in history under some variable, e.g.:

```shell
print $rcx
# $1 = 0

#  print the first 10 elements of the array arr
p *arr@10
```

`output` works similarly but doesn't save the result in history and doesn't insert a newline character.

In GDB, you may create custom variables with `set` for example, `set $t = my_var->t`.

You may use the output variable of the command to reference it:

```
(gdb) p x
$12 = (int) 2
```

The `$` is for the last variable in the output. To print structures we may use GDB functions

`display EXP` - display variable on each debugger break (can be called multiple times)  
`undisp {var}` - do not show the variable any longer

Extensions
----------

### Python interpreter

The `python` command starts the Python interpreter, from where we can access the GDB interface through the gdb object, e.g.:

```py
python print (gdb.breakpoints())
```

### GUI / CUI

Interesting extensions:

- [gef](https://github.com/hugsy/gef)
- [nnd](https://github.com/al13n321/nnd)

{% endraw %}
