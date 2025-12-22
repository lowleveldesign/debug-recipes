---
layout: page
title: Linux Kernel Tracing (/sys/kernel/tracing)
date: 2025-12-22 08:00:00 +0200
---

{% raw %}

**Table of contents:**

<!-- MarkdownTOC -->

- [General information](#general-information)
- [Collecting events](#collecting-events)
- [Function tracing](#function-tracing)

<!-- /MarkdownTOC -->

General information
-------------------

If `/sys/kernel/tracing` is not available we may **mount it** with the following command:

```shell
mount -t tracefs nodev /sys/kernel/tracing
```

Writing to the buffer (trace / trace_pipe) is enabled globally by writing `1` to the file `/sys/kernel/tracing/tracing_on` (default value). If we write `0`, traces are still set up, but the kernel stops writing to the buffer. This is like a pause.

Collecting events
-----------------

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

Function tracing
----------------

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

{% endraw %}