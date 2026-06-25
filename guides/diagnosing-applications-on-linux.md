---
layout: page
title: Diagnosing applications on Linux
date: 2026-06-23 08:00:00 +0200
---

**Table of contents:**

<!-- MarkdownTOC -->

- [Checking overall system status](#checking-overall-system-status)
- [Listing running processes](#listing-running-processes)
- [Troubleshooting processes](#troubleshooting-processes)
    - [Tracing system calls (strace)](#tracing-system-calls-strace)
    - [Troubleshooting glibc loader errors](#troubleshooting-glibc-loader-errors)

<!-- /MarkdownTOC -->

Checking overall system status
------------------------------

If our system is based on systemd, we can use a number of `systemctl` commands to check its current status:

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

With `w` we may check **basic system stats and list who is logged to the system and what are they doing**, for example:

```sh
w
# 17:27:09 up  1:59,  1 user,  load average: 0.00, 0.02, 0.00
#USER     TTY       LOGIN@   IDLE   JCPU   PCPU  WHAT
#me       pts/1     15:27    1:59m  0.01s  0.01s -fish
```

The first line shows the current time, the system uptime time, the number of logged users, and the system load averages for the past 1, 5, and 15 minutes (same as the output of the `uptime` command). `JCPU` shows the CPU time of all processes attached to tty (including background processes). `PCPU` is the CPU time of the current process (the one in the `WHAT` column).

To check basic **memory usage**, we may use `free` and `vmstat` (`procps-ng` package), for example:

```sh
# 1 to show stats each second and stop after 3 seconds, -S switches unit to MB, CPU and disk subsystems (use -d for disk stats)
vmstat -S M 1 3

# your memory and swap space configurations.
free -mh
#                total        used        free      shared  buff/cache   available
# Mem:           7,7Gi       3,9Gi       1,3Gi       1,3Gi       4,0Gi       3,8Gi
# Swap:          8,2Gi          0B       8,2Gi
```

To check the current **I/O usage**, we may use the `iostat` app (`sysstat` package), for example:

```sh
# prints 4 times (every 1 second) extended (-x) statistics about devices (-d) in a human readable way (-h).
iostat -h -x -d 1 4
```

The `df` and `du` commands are helpful when investigating the data usage on the mounted file systems, for example:

```sh
# display disk space usage
df -h

# Summary of disk usage for all catalogs in the current folder
du -hs *

# File disk usage (all files in the current folder and its children)
du -ah | more
```

Listing running processes
-------------------------

For services, you may use `systemctl` already mentioned in this guide.

If you want to list individual processes (or even threads), you might use `ps` (`procps-ng` package). You may find a number of its usage examples below:

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

Troubleshooting processes
-------------------------

### Tracing system calls (strace)

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

### Troubleshooting glibc loader errors

If we experience problems with library resolution and our system is using a glibc loader, we may set the `LD_DEBUG` environment variables to collect loader logs on the standard error output (setting `LD_DEBUG_OUTPUT` to a file path will redirect the logs to a file). The content of `LD_DEBUG` is one or more categories, including: `bindings`, `files`, `libs`, `scopes`, `versions`, etc. (check `ld.so` manual page for all the available options). Setting `LD_DEBUG` to `all` enables all the categories. Example usages:


```sh
# Enable all the loader logs for a /bin/ls run
LD_DEBUG=all /bin/ls

# Enable LD_DEBUG to find out why nvidia libraries are not loaded by the tensorflow docker image
podman run --name deep-learning --rm -it -v ".:/workspace" -e LD_DEBUG=libs --device nvidia.com/gpu=all docker.io/tensorflow/tensorflow:2.21.0-gpu-jupyter python3 -c "import tensorflow as tf; tf.config.list_physical_devices('GPU')" 2>&1
```

