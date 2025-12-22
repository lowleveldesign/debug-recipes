---
layout: page
title: eBPF
date: 2025-12-22 08:00:00 +0200
---

{% raw %}

**Table of contents:**

<!-- MarkdownTOC -->

- [General information](#general-information)
- [bpftrace](#bpftrace)
    - [Probe Metadata](#probe-metadata)
    - [Language Syntax](#language-syntax)
    - [CPU Sampling](#cpu-sampling)
    - [Available functions](#available-functions)
    - [My one-liners](#my-one-liners)

<!-- /MarkdownTOC -->

General information
-------------------

[Main project page](https://ebpf.io/)

To use eBPF you need to hold the following **required capabilities**: `CAP_BPF`, `CAP_PERFMON` (loading tracing programs), `CAP_NET_ADMIN` (loading network programs).

bpftrace
--------

### Probe Metadata

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

### Language Syntax

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

### CPU Sampling

bpftrace [supports debuginfod symbols](https://github.com/iovisor/bcc/pull/3393/files) and this is awesome because, for example, ustack or kstack show real stacks. After collecting a trace, it can be converted to a flame graph using scripts from the [FlameGraph](https://github.com/brendangregg/FlameGraph) repository, e.g.:

```perl
bpftrace -o test-service.out -q -e 'profile:hz:99 / comm == "test-service" / { @[ustack()] = count(); }'

./stackcollapse-bpftrace.pl test-service.out > test-service.flame
./flamegraph.pl test-service.flame > test-service.flame.svg
```

### Available functions

In the **printf** function, the '-' character before the width means the text will be left-aligned, e.g.:

```perl
printf("|%-15s|\n", "TIME");
#|TIME           |
printf("|%15s|\n", "TIME");
#|           TIME|
```

### My one-liners

```perl
# openat with process information and collected stack
bpftrace -e 'tracepoint:syscalls:sys_enter_openat / strcontains(comm, "dump-") == 1 / { printf("%d:%s %d %s\n", pid, comm, args.dfd, str(args.filename)); print(ustack()); }'
```

{% endraw %}