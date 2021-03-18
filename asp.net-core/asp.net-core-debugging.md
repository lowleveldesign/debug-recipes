
## dotnet-trace

### Microsoft-Extensions-Logging

Link do źródeł i komentarza + przykładowy trace

```
dotnet-trace collect -p PID --providers "Microsoft-Extensions-Logging:0x4,Microsoft-Diagnostics-DiagnosticSource"
```

### Microsoft-Diagnostics-DiagnosticSource

Link do user guide'a i przykładowy trace

```
dotnet-trace collect --providers Microsoft-Diagnostics-DiagnosticSource:0xFFFFFFFFFFFFFFFF:5:FilterAndPayloadSpecs="SqlClientDiagnosticListener/Microsoft.Data.SqlClient.WriteCommandBefore:-Command.CommandText" -p PID
```

Nice usage example: https://github.com/dotnet/diagnostics/issues/1190 

## dotnet-counters

```
> dotnet-counters monitor "System.Runtime" "Microsoft.AspNetCore.Hosting" "Microsoft.EntityFrameworkCore" -p 11320

Press p to pause, r to resume, q to quit.
    Status: Running

[Microsoft.AspNetCore.Hosting]
    Current Requests                                                0
    Failed Requests                                                 0
    Request Rate (Count / 1 sec)                                    0
    Total Requests                                                  0
[System.Runtime]
    % Time in GC since last GC (%)                                  0
    Allocation Rate (B / 1 sec)                                 8 168
    CPU Usage (%)                                                   0
    Exception Count (Count / 1 sec)                                 0
    GC Fragmentation (%)                                            0,031
    GC Heap Size (MB)                                              99
    Gen 0 GC Count (Count / 1 sec)                                  0
    Gen 0 Size (B)                                                192
    Gen 1 GC Count (Count / 1 sec)                                  0
    Gen 1 Size (B)                                         23 376 680
    Gen 2 GC Count (Count / 1 sec)                                  0
    Gen 2 Size (B)                                          5 890 608
    IL Bytes Jitted (B)                                     1 204 637
    LOH Size (B)                                            2 045 304
    Monitor Lock Contention Count (Count / 1 sec)                   0
    Number of Active Timers                                         2
    Number of Assemblies Loaded                                   157
    Number of Methods Jitted                                   28 854
    POH (Pinned Object Heap) Size (B)                         262 384
    ThreadPool Completed Work Item Count (Count / 1 sec)            2
    ThreadPool Queue Length                                         0
    ThreadPool Thread Count                                         3
    Working Set (MB)                                              215
[Microsoft.EntityFrameworkCore]
    Active DbContexts                                               0
    Execution Strategy Operation Failures (Count / 1 sec)           0
    Execution Strategy Operation Failures (Total)                   0
    Optimistic Concurrency Failures (Count / 1 sec)                 0
    Optimistic Concurrency Failures (Total)                         0
    Queries (Count / 1 sec)                                         0
    Queries (Total)                                                 1
    Query Cache Hit Rate (%)                                      NaN
    SaveChanges (Count / 1 sec)                                     0
    SaveChanges (Total)                                             0
```