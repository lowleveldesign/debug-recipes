
Performance tools available in Windows
======================================

## Task Manager (taskmgr.exe)

Shows information about processes running on the system.

## Resource Monitor (resmon.exe)

Nicely shows the CPU, memory and disk usage satatistics for processes on the system.

## Performance Monitor (perfmon.exe)

Allows you to collect performance counters data as well as ETW events (event collectors).

## Windows Assesment Tool (winsat.exe)

Test CPU, memory and disk:

```
> winsat cpuformal -v
> winsat memformal -v
> winsat diskformal -v
```

## logman.exe, wevtutil.exe

Tools for collecting ETW traces (more in a recipe dedicated to ETW).

## typeperf.exe

A command line tool to collect performance counters data. Example usages:

```
> typeperf -q

> typeperf -c "\Process(notepad*)\ID Process" -sc 1

> typeperf -cf memcounters.txt -si 1 -sc 10 -f CSV -o memperfdata.csv
```

## netsh.exe (for network traces)



## Links

- [Diagnosing applications using Performance Counters](https://lowleveldesign.wordpress.com/2012/04/19/diagnosing-applications-using-performance-counters/)

