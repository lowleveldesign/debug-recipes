---
layout: page
title: Troubleshooting on Linux
date: 2025-07-16 08:00:00 +0200
redirect_from:
    - /guides/configuring-linux-for-effective-troubleshooting/
    - /guides/diagnosing-applications-on-linux/
    - /guides/gdb/
    - /guides/linux-tracing/
    - /guides/ebpf/
---

{% raw %}

**Table of contents:**

<!-- MarkdownTOC -->

- [System configuration](#system-configuration)
    - [Installing tools](#installing-tools)
    - [Configuring GDB](#configuring-gdb)
    - [Configuring debug symbols](#configuring-debug-symbols)
- [Troubleshooting techniques](#troubleshooting-techniques)
    - [Checking overall system status](#checking-overall-system-status)
    - [Listing running processes](#listing-running-processes)
    - [Checking disk space usage](#checking-disk-space-usage)
    - [Troubleshooting glibc loader errors](#troubleshooting-glibc-loader-errors)
    - [Tracing system calls with strace](#tracing-system-calls-with-strace)
    - [Sampling CPU usage with bpftrace](#sampling-cpu-usage-with-bpftrace)
    - [Diagnosing a slow system start](#diagnosing-a-slow-system-start)
    - [Troubleshooting network connectivity](#troubleshooting-network-connectivity)
        - [Testing network connectivity](#testing-network-connectivity)
        - [Tracing network traffic with tcpdump](#tracing-network-traffic-with-tcpdump)
        - [Measuring network bandwidth with iperf](#measuring-network-bandwidth-with-iperf)
- [Tools usage tips](#tools-usage-tips)
    - [GDB](#gdb)
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
            - [Expressions (variables, registers, etc.)](#expressions-variables-registers-etc)
        - [Extensions](#extensions)
            - [Python interpreter](#python-interpreter)
            - [GUI / CUI](#gui-cui)
    - [Linux Kernel Tracing (/sys/kernel/tracing)](#linux-kernel-tracing-syskerneltracing)
        - [Enable tracing](#enable-tracing)
        - [Collecting events](#collecting-events)
        - [Function tracing](#function-tracing)
    - [eBPF](#ebpf)
        - [General information](#general-information)
        - [bpftrace](#bpftrace)
            - [Probe Metadata](#probe-metadata)
            - [Language Syntax](#language-syntax)
            - [Available functions](#available-functions)
            - [My one-liners](#my-one-liners)

<!-- /MarkdownTOC -->

System configuration
--------------------

### Installing tools

I highly recommend installing the following tools to have them available when error occurs:

- [procps](https://gitlab.com/procps-ng/procps) (includes: uptime, w, vmstat, free, ps, pmap, pgrep)
- [sysstat](https://sysstat.github.io/) (includes: pidstat, mpstat, iostat, sar)
- [gdb](https://www.gnu.org/software/gdb/)
- [strace](https://strace.io/)
- [bpftrace](https://github.com/iovisor/bpftrace)

For a desktop system, you may also like to have a GUI/TUI system monitor. My favorite is [Mission Center](https://missioncenter.io/), but any of the tools listed below will be a good choice too:

- [btop](https://github.com/aristocratos/btop) - a TUI tool with fantastic colors and graphics
- [Glances](https://nicolargo.github.io/glances/) is an interesting choice if you're looking for a TUI or web application. You may run it with uv, for example, `uv tool run --with fastapi --with uvicorn --with jinja2 glances -w --bind 127.0.0.1`.  Then open <http://127.0.0.1:61208/> in the browser. The 'h' key will show you available shortcuts.
- [htop](https://htop.dev/) was for a long time my favorite monitoring tool. If you're looking for a modern `top` replacement, `htop` might be a good choice.
- [Resources](https://apps.gnome.org/Resources) is a monitoring app which will become a default Gnome system montoring app, very similar to Mission Center.
- [TuxManager](https://github.com/benapetr/TuxManager) is a Qt-based monitoring app, similar to Microsoft's Task Manager.

### Configuring GDB

I like to have the following lines in my `~/.gdbinit` file:

```sh
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

To ptrace (attach to) any process, you may **add ptrace capability** to gdb:

```sh
sudo setcap cap_sys_ptrace=eip $(which gdb)
```

### Configuring debug symbols

These days many debugging tools can fetch debug symbols from debuginfod servers. The [official project page](https://sourceware.org/elfutils/Debuginfod.html) lists the URLs you should use for each supported distribution. For example, in my Arch Linux, the `DEBUGINFOD_URLS` environment variable is set to `https://debuginfod.archlinux.org` by the `/etc/profile.d/debuginfod.sh` script (a part of the libelf package).

If you want this variable to be preserved when running commands with sudo, you can add a rule such as the following to a file in `/etc/sudoers.d/` (e.g., `/etc/sudoers.d/debuginfod`):

```
Defaults env_keep += "DEBUGINFOD_URLS"
```

If you enabled the debuginfod support in gdb (see above), you may check if gdb properly recognizes the debuginfod settings with the following command:

```
(gdb) show debuginfod
debuginfod enabled:  Debuginfod functionality is currently set to "ask".
debuginfod urls:  Debuginfod URLs have not been set.
debuginfod verbose:  Debuginfod verbose output is set to 1.
```

Troubleshooting techniques
--------------------------

### Checking overall system status

If our system is based on systemd, we can use a number of `systemctl` commands to check its current status, such as:

```sh
# check system services status
systemctl status

# check user session services status
systemctl status --user

# list failed units
systemctl status --failed

# list units with a specific state and name pattern
systemctl list-units --user --state inactive 'plasma*'
```

With `w` we may check **basic system stats and list who is logged to the system and what are they doing**. Example output:

```
 17:27:09 up  1:59,  1 user,  load average: 0.00, 0.02, 0.00
USER     TTY       LOGIN@   IDLE   JCPU   PCPU  WHAT
me       pts/1     15:27    1:59m  0.01s  0.01s -fish
```

The first line shows the current time, the system uptime time, the number of logged users, and the system load averages for the past 1, 5, and 15 minutes (same as the output of the `uptime` command). `JCPU` shows the CPU time of all processes attached to tty (including background processes). `PCPU` is the CPU time of the current process (the one in the `WHAT` column).

Another useful tool to report the total **CPU usage** is `mpstat`, for example:

```sh
# display CPU usage every second for 4 seconds
mpstat 1 4
```

To check basic **memory usage**, we may use `free` and `vmstat`, for example:

```
# 1 to show stats each second and stop after 3 seconds, -S switches unit to MB, CPU and disk subsystems (use -d for disk stats)
vmstat -S M 1 3

# memory and swap space configurations.
free -mh
               total        used        free      shared  buff/cache   available
Mem:           7,7Gi       3,9Gi       1,3Gi       1,3Gi       4,0Gi       3,8Gi
Swap:          8,2Gi          0B       8,2Gi
```

To check the current **I/O usage**, we may use the `iostat` app, for example:

```sh
# prints 4 times (every 1 second) extended (-x) statistics about devices (-d) in a human readable way (-h).
iostat -h -x -d 1 4
```

Finally, if we want a diagnostic command to run in a loop, we may achieve that with the `watch` command, for example:

```sh
# run nvidia-smi every 1 second
watch -n 1 nvidia-smi
```

### Listing running processes

For services, you may use `systemctl` already mentioned in this guide.

If you want to list individual processes (or even threads), you might use `ps`. Example usages:

```shell
# show every process running in the system with full details
ps -eF # very similar to ps -ely

# show as process tree
ps -ejH

# show threads
ps -eLf

# filter by pid
ps -F -p $fish_pid
# filter by command line
ps -F -C fish

# show a process tree for a given process (-l is to show long lines, -a show process arguments, -s show parent processes)
pstree -sal 14545
```

The `lsof` command lists open files (handles) in the system, for example:

```sh
# lists open files by all processes
lsof

# filter by pid
lsof -p 1234
```

### Checking disk space usage

The `df` and `du` commands are helpful when investigating the data usage on the mounted file systems, for example:

```sh
# display disk space usage
df -h

# Summary of disk usage for all catalogs in the current folder
du -hs *

# File disk usage (all files in the current folder and its children)
du -ah | more
```

### Troubleshooting glibc loader errors

If we experience problems with library resolution and our system is using a glibc loader, we may set the `LD_DEBUG` environment variables to collect loader logs on the standard error output (setting `LD_DEBUG_OUTPUT` to a file path will redirect the logs to a file). The content of `LD_DEBUG` is one or more categories, including: `bindings`, `files`, `libs`, `scopes`, `versions`, etc. (check `ld.so` manual page for all the available options). Setting `LD_DEBUG` to `all` enables all the categories. Example usages:

```sh
# Enable all the loader logs for a /bin/ls run
LD_DEBUG=all /bin/ls

# Enable LD_DEBUG to find out why nvidia libraries are not loaded by the tensorflow docker image
podman run --name deep-learning --rm -it -v ".:/workspace" -e LD_DEBUG=libs --device nvidia.com/gpu=all docker.io/tensorflow/tensorflow:2.21.0-gpu-jupyter python3 -c "import tensorflow as tf; tf.config.list_physical_devices('GPU')" 2>&1
```

### Tracing system calls with strace

Strace is often the first tool I use when troubleshooting errors in applications. It can answers questions such as: what files the application tried to access, which connections it created, what child processes it created, etc. Below you may find some usage examples:

```sh
# trace openat syscall only when executing testapp (output to stderr)
strace -e trace=openat testapp

# trace file-related syscalls when executing ls ~/tmp/mnt (output to stderr)
strace --trace=%file -- ls ~/tmp/mnt

# trace file- and process-related syscalls when executing testapp and its children (-f)
# output for the parent and the children goes to testapp.strace (-o)
strace --trace=%file,%process -f -o /tmp/testapp.strace -- testapp

# same as above but creates a separate testapp.strace file with PID appended
# to its for each process (-ff)
strace --trace=%file,%process -ff -o /tmp/testapp.strace -- testapp

# trace file-related syscalls for the python app and its children, forwarding the stderr and stdout
# to /tmp/tf.strace and the regulard output (tee)
strace --trace=%file -f --  python3 -c "print('test')" 2>&1 | tee /tmp/tf.strace 
```

### Sampling CPU usage with bpftrace

Bpftrace [supports debuginfod symbols](https://github.com/iovisor/bcc/pull/3393/files) and this is awesome because, for example, `ustack` or `kstack` show readable stacks. After collecting a trace, it can be converted to a flame graph using scripts from the [FlameGraph](https://github.com/brendangregg/FlameGraph) repository, e.g.:

```perl
bpftrace -o test-service.out -q -e 'profile:hz:99 / comm == "test-service" / { @[ustack()] = count(); }'

./stackcollapse-bpftrace.pl test-service.out > test-service.flame
./flamegraph.pl test-service.flame > test-service.flame.svg
```

### Diagnosing a slow system start

The systemd-analyze command provides great insights which services were slowing down the system startup:

```
# startup 
systemd-analyze time

Startup finished in 2.240s (firmware) + 5.913s (loader) + 884ms (kernel) + 11.641s (initrd) + 5.069s (userspace) = 25.751s 
graphical.target reached after 5.068s in userspace.
```

```
systemd-analyze critical-chain 

The time when unit became active or started is printed after the "@" character.
The time the unit took to start is printed after the "+" character.

graphical.target @5.068s
└─power-profiles-daemon.service @4.993s +72ms
  └─multi-user.target @4.989s
    └─cups.service @4.890s +97ms
      └─network.target @4.887s
        └─NetworkManager.service @4.525s +359ms
          └─network-pre.target @4.522s
            └─firewalld.service @4.520s
              └─basic.target @4.503s
                └─dbus-broker.service @4.400s +76ms
                  └─dbus.socket @4.386s +43us
                    └─sysinit.target @4.382s
                      └─systemd-update-done.service @4.352s +29ms
                        └─ldconfig.service @3.980s +369ms
                          └─systemd-tmpfiles-setup.service @3.819s +158ms
                            └─local-fs.target @3.755s
                              └─efi.mount @3.009s +741ms
                                └─systemd-fsck@dev-disk-by\x2duuid-A6DB\x2dF538.service @2.683s +60ms
```

```
# prints a list of the running units, ordered by the time it took to initialize
systemd-analyze blame

# draw a plot of the services startup
systemd-analyze plot > boot.svg
```

We can use `dmesg` to read the **kernel ring buffer logs**, but usually, we will be interested also in the **systemd-journal logs**. `journalctl` is the command that will show us log entries from both those places:

```sh
# show logs from the current session
journalctl -b -0

# show logs from the previous session and grep them using the 'timer' pattern without paging
journalctl -b -1 -g 'timer' --no-pager
```

### Troubleshooting network connectivity

#### Testing network connectivity

It is a common mistake to rely on ping when testing TCP connections. Ping uses a different protocol (ICMP) and although it is a fine tool to check if there is connectivity between two hosts (assuming ICMP traffic is not blocked), it will not tell us anything about opened TCP ports.

To check if there is anything listening on a TCP port 80 on a remote host, you may use **netcat**:

```shell
nc -vnz 192.168.0.20 80
```

#### Tracing network traffic with tcpdump

Most commonly used tool to collect network traces on Linux is tcpdump. The BPF language is quite complex and allows various filtering options. A great explanation of its syntax can be found [here](http://www.biot.com/capstats/bpf.html). Below, you may find example session configurations:

```shell
# View traffic only between two hosts:
tcpdump host 192.168.0.1 && host 192.168.0.2

# View traffic in a particular network:
tcpdump net 192.168.0.1/24

# Dump traffic to a file and rotate it every 1KB:
tcpdump -C 1024 -w test.pcap
```

#### Measuring network bandwidth with iperf

The iperf tool can measure bandwidth on Windows and Linux. We need to start the iperf server (`-s`) (the `-e` option is to enable enhanced output and `-l` sets the TCP read buffer size):

```shell
iperf -s -l 128k -p 8080 -e
```

Then, for an example test, we may run the client for `30s` (`-t`) using two parallel threads (`-P`) and showing interval summaries every `2s` (`-i`):

```shell
iperf -c 172.30.102.167 -p 8080 -l 128k -P 2 -i 2 -t 30
```

Tools usage tips
----------------

### GDB

#### TUI

This is a windowed interface for GDB. We enable/disable it using `Ctrl-x a`. `Ctrl-x 1` enables single-window mode, `Ctrl-x 2` enables two-window mode. The `tui layout` command determines what appears in the windows, e.g.:

```shell
tui layout split
tui layout src
```

`Ctrl-x o` allows us to switch between active debugger windows.

#### Symbols

##### Searching for symbols and addresses

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

##### Searching for source code

The `directory` command allows us to add additional directories for the source code:

```shell
show directories 
# Source directories searched: $cdir:$cwd

directory /tmp/openssl-0.9.8-easy_tls-orig/
# Source directories searched: /tmp/openssl-0.9.8-easy_tls-orig:$cdir:$cwd
```

#### Debugging child processes

`set detach-on-fork off` makes the debugger debug both the parent and its fork. If we don't enable this, we can decide what happens at fork using `set follow-fork-mode`. The `parent` option will cause the debugger to continue debugging the parent. The `child` option will switch to the child.

At the moment of fork, it's possible that `continue` won't work. We then need to allow both parent and child to execute simultaneously using `set schedule-multiple on`.

We can view currently debugged processes with the `info inferiors` command, and switch between them with `inferior {ID}`.

#### Execution Control

##### Process startup

GDB takes the debugged binary as an argument. Then we can add startup arguments with the `run` command. It also accepts stdin redirection from any file, e.g.:

```shell
r mytestapp < /tmp/test_file
```

##### Breakpoints and catchpoints

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

##### Code execution

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

##### Signals

The debugger intercepts some signals (e.g. SIGINT) and handles them. To send such a signal to the application we can use the `signal` command, e.g. `signal SIGINT`.

#### State Control

##### Process information

We can view currently debugged processes with the `info inferiors` command, and switch between them with `inferior {ID}`.

`info proc` and its subcommands provide insight into the internals of the executing process, e.g.:

```shell
info proc
# process 10372
# cmdline = '/tmp/easy_tls_0_9_8o_stripped'
# cwd = '/tmp'
# exe = '/tmp/easy_tls_0_9_8o_stripped'
```

##### Threads

`info threads` to list the threads, `thread ID` to switch to a thread.

We can also execute a command on all the threads by using: `thread apply all`, for example `thread apply all bt`.

##### Shared libs

`info proc exe` shows information about the main module

`info dll` - shows the status of loaded libraries

##### Stack

`bt` - shows the stack

`f {num}` - selects a stack frame `{num}` as active
`up` or `down` - moves up or down the stack

##### Code and Assembler

`list` shows the current location in sources. You can also list a function by passing its name as parameters.

`disassemble /s` shows the assembly code of the current function along with source code, if available. You can provide start and end addresses of any location in memory as parameters.

##### Memory

`x` (examine)

`mem read -tdouble -c10 arr` - read a count of 10 items of type double from an array

`info proc mappings` lists memory regions occupied by the process.

##### Expressions (variables, registers, etc.)

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

#### Extensions

##### Python interpreter

The `python` command starts the Python interpreter, from where we can access the GDB interface through the gdb object, e.g.:

```py
python print (gdb.breakpoints())
```

##### GUI / CUI

Interesting extensions:

- [gef](https://github.com/hugsy/gef)
- [nnd](https://github.com/al13n321/nnd)

### Linux Kernel Tracing (/sys/kernel/tracing)

#### Enable tracing

If `/sys/kernel/tracing` is not available we may **mount it** with the following command:

```shell
mount -t tracefs nodev /sys/kernel/tracing
```

Writing to the buffer (`trace` or `trace_pipe`) is enabled globally by writing `1` to the file `/sys/kernel/tracing/tracing_on` (default value). If we write `0`, traces are still set up, but the kernel stops writing to the buffer. This is like a pause.

#### Collecting events

[Official documentation](https://docs.kernel.org/trace/events.html)

The list of events is available in the `available_events` file. We enable the tracer by sending the name to the `set_event` file or by setting `1` in the `enabled` file for events in the events directory (e.g., enabled in events/ will enable all events):

```shell
# events only
echo nop > current_tracer

# clear trace
echo > trace

# enable events
echo 1 > /sys/kernel/tracing/events/sched/sched_process_exec/enable
echo 1 > /sys/kernel/tracing/events/sched/sched_process_fork/enable

# continuous reading or periodically cat /sys/kernel/tracing/trace
cat /sys/kernel/tracing/trace_pipe

# disable all events
echo 0 > /sys/kernel/tracing/events/enable
```

Using the `trace_event=[event-list]` option in **boot options** we can enable very early tracing.

We can **filter** events by fields using the filter file in the given event's directory (events/). Additionally, filtering by PIDs is possible through the `set_event_pid` file. To automatically **filter forks and remove PIDs of processes that have ended**, you can set the `event-fork` option:

```shell
echo 1 > options/event-fork

echo $$
# 3187
echo 3187 > set_event_pid

# clear trace
echo > trace

# start tracing
echo 1 > events/sched/enable

bash
# in bash
# [me@testbox tmp]$ echo $$
# 7519

cat set_event_pid
# 3187
# 7519

cat trace

# disable tracing
echo 0 > events/enable
```

Collected events can be found in `/sys/kernel/tracing/trace` (collection of recent events, for reading by us, new line clears it) or `/sys/kernel/tracing/trace_pipe` (event stream, events disappear after reading). Description of event fields can be found in the given event's directory, in the `format` file, e.g.:

```shell
cat events/sched/sched_process_exec/format
# name: sched_process_exec
# ID: 322
# format:
#     field:unsigned short common_type;   offset:0;   size:2; signed:0;
#     field:unsigned char common_flags;   offset:2;   size:1; signed:0;
#     field:unsigned char common_preempt_count;   offset:3;   size:1; signed:0;
#     field:int common_pid;   offset:4;   size:4; signed:1;
# 
#     field:__data_loc char[] filename;   offset:8;   size:4; signed:0;
#     field:pid_t pid;    offset:12;  size:4; signed:1;
#     field:pid_t old_pid;    offset:16;  size:4; signed:1;
# 
# print fmt: "filename=%s pid=%d old_pid=%d", __get_str(filename), REC->pid, REC->old_pid
```

#### Function tracing

[Official documentation](https://docs.kernel.org/trace/ftrace.html)

Function tracing feature should be enabled by default and it is controlled using `kernel.ftrace` global switch. To enable it, run:

```sh
sysctl kernel.ftrace_enabled=1
```

**Events/function calls** can be collected either aggregated (less invasive) or sequentially.

To enable statistics for (selected) kernel functions, we write `1` to `function_profile_enabled`. Statistics are collected for all functions listed in `available_filter_function`. We can filter these statistics by writing to `set_ftrace_filter` and `set_ftrace_notrace` (function) as well as `set_graph_function` and `set_graph_notrace` (function_graph). PIDs that interest us can be written to `set_ftrace_pid` or `set_ftrace_notrace_pid`. Call statistics can be found in `trace_stat/function<cpu>`. Example trace:

```shell
echo 2594 > set_ftrace_pid

echo 1 > function_profile_enabled

# collection time

echo 0 > function_profile_enabled

cat trace_stat/function*
```

To enable tracing of individual functions, we set the tracer to "function" (and possibly "function_graph") and read calls through `trace_pipe` or `trace`, as with events:

```shell
# enabling
echo 'tcp*' > set_ftrace_filter && echo function > current_tracer

# collecting events from buffer
cat trace > /tmp/tcp-trace.txt

# disabling
echo nop > current_tracer && echo > set_ftrace_filter
```

### eBPF

#### General information

[Main project page](https://ebpf.io/)

To use eBPF you need to hold the following **required capabilities**: `CAP_BPF`, `CAP_PERFMON` (loading tracing programs), `CAP_NET_ADMIN` (loading network programs).

#### bpftrace

##### Probe Metadata

Information about available probes (instrumentation point for capturing event data) can be retrieved with the **-l** option, e.g.:

```shell
bpftrace -l 'tracepoint:syscalls:*execve*'

# tracepoint:syscalls:sys_enter_execve
# tracepoint:syscalls:sys_enter_execveat
# tracepoint:syscalls:sys_exit_execve
# tracepoint:syscalls:sys_exit_execveat

# and parameters
bpftrace -lv 'tracepoint:syscalls:sys_enter_execve*'
# tracepoint:syscalls:sys_enter_execve
#     int __syscall_nr
#     const char * filename
#     const char *const * argv
#     const char *const * envp
# tracepoint:syscalls:sys_enter_execveat
#     int __syscall_nr
#     int fd
#     const char * filename
#     const char *const * argv
#     const char *const * envp
#     int flags
```

##### Language Syntax

In each event, we can reference one of the **[built-in variables](https://github.com/bpftrace/bpftrace/blob/master/man/adoc/bpftrace.adoc#builtins)**, including: `comm` (process name), `pid`, `tid`, or `args` (a special variable that allows us to access arguments of a given event, e.g., `args.filename` for `tracepoint:syscalls:sys_enter_openat`). Additionally, we can create so-called **scratch variables**, which will only be visible within a given probe:

```perl
BEGIN { let $n = (uint8)1; }
END { printf("%d", $n) } # error - $n is not available
```

Hashmaps, on the other hand, remain visible throughout the entire script execution:

```perl
BEGIN {
    @myconf["only_stacks"] = (uint8)0;
}

END {
    printf("Stats enabled: %d\n", @myconf["only_stats"]);
    delete(@myconf, "only_stacks");
}
```

We also cannot change the type of either a variable or a value stored in a map, e.g.:

```perl
@myconf["pid"] = $# > 1 ? $2 : 0;
@myconf["pid"] = "test"; # error
```

The default numeric type is `uint64` and everything is cast to it, e.g.:

```perl
# pid will be stored as uint64 even if we cast to int32
BEGIN {
    @myconf["pid"] = $# > 1 ? $2 : 0;
}

# WARNING: comparison of integers of different signs: 'int32' and 'uint64' can lead to undefined behavior
tracepoint:sched:sched_process_fork / @myconf["pid"] != 0 && args.parent_pid == @myconf["pid"] / 

# OK:
tracepoint:sched:sched_process_fork / @myconf["pid"] != 0 && args.parent_pid == (int32)@myconf["pid"] /
```

At the beginning of a script, we can use **preprocessor directives**, but `#define` only works for constants (when I tried to add a function, I got a strange error).

In the preamble, we can also create our own types, but it seems we can only use them when working with C pointers. I couldn't initialize a variable of my type (`$t : my_struct = {}`). However, we can use tuples, which should often be sufficient. We reference tuple fields by their numeric index, e.g.:

```perl
tracepoint:syscalls:sys_enter_openat
{
    @openat[tid] = (args.dfd, args.filename, args.mode);
}

tracepoint:syscalls:sys_exit_openat
{
    $eventName = "file_openat";
    PRINT_EVENT_COMMONS;

    $data = @openat[tid];
    printf("dfd: %d filename: '%s', mode: %x, ret: %d\n", $data.0, str($data.1), $data.2, args.ret);
    delete(@openat[tid]);
}
```

`BEGIN` is one of the **[available probes](https://github.com/bpftrace/bpftrace/blob/master/man/adoc/bpftrace.adoc#probes)** that allows code execution at the start of a tracing session, e.g.:

```shell
bpftrace -e 'BEGIN { printf("hello world\n"); }'
# Attaching 1 probe...
# hello world
# ^C
```

If we prefix a variable name with `@`, we get a hashmap (without a name, we'll use the global hashmap). We can access its keys through square brackets. At the end of tracing, bpftrace outputs all used hashmaps, e.g.:

```perl
bpftrace -e 'tracepoint:syscalls:sys_enter_write { @[comm] = count(); }'
# Attaching 1 probe...
# ^C
# 
# @[rtkit-daemon]: 1
# @[Worker Launcher]: 1
# ...

bpftrace -e 'tracepoint:syscalls:sys_enter_write { @write[comm] = count(); } tracepoint:syscalls:sys_enter_writev { @writev[comm] = count(); }'
# Attaching 2 probes...
# ^C
# 
# @write[redshift-gtk]: 2
# @write[syncthing]: 2
# @write[redshift]: 2
# @writev[at-spi2-registr]: 2
# @writev[redshift]: 4
```

If we add `/ ... /` after a syscall name, we can place **a filter** between the slashes, e.g., `pid == 1234`, to display events only for the process with ID 1234, e.g.:

```perl
bpftrace -e 'tracepoint:syscalls:sys_enter_write / comm == "fish" / { @ = count(); }'
# Attaching 1 probe...
# ^C
# 
# @: 415
```

We can also use ifs inside action code.

`count` is one of the **[map functions](https://github.com/bpftrace/bpftrace/blob/master/man/adoc/bpftrace.adoc#map-functions)** we can use to generate hashmaps. `hist`, `stats` and `avg` are other such functions.

##### Available functions

In the **printf** function, the '-' character before the width means the text will be left-aligned, e.g.:

```perl
printf("|%-15s|\n", "TIME");
#|TIME           |
printf("|%15s|\n", "TIME");
#|           TIME|
```

##### My one-liners

```perl
# openat with process information and collected stack
bpftrace -e 'tracepoint:syscalls:sys_enter_openat / strcontains(comm, "dump-") == 1 / { printf("%d:%s %d %s\n", pid, comm, args.dfd, str(args.filename)); print(ustack()); }'
```

{% endraw %}
