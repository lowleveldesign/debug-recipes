
MS SQL Server schedulers and threads
====================================

Schedulers
---------

**A uniquer scheduler** is created for every CPU that is available to SQL Server and you can think of it as a logical CPU. **A worker** can be either a thread or a fiber that is bound to a logical scheduler. Based on the affinity mask settings each scheduler is set to either `ONLINE` or `OFFLINE` state.

Each **Resource Monitor** has its own SPID, which you can see by querying the `sys.dm_exec_requests` and `sys.dm_os_workers` DMVs, as shown here:

    SELECT session_id,
        CONVERT (varchar(10), t1.status) AS status,
        CONVERT (varchar(20), t1.command) AS command,
        CONVERT (varchar(15), t2.state) AS worker_state
    FROM sys.dm_exec_requests AS t1 JOIN sys.dm_os_workers AS t2
    ON  t2.task_address = t1.task_address
    WHERE command = 'RESOURCE MONITOR';

All running schedulers can be found by using the following query:

    select * from sys.dm_os_schedulers;

Workers
------

You can use the following query to find out how long a worker has been running in a SUSPENDED or RUNNABLE state:

    SELECT
        t1.session_id,
        CONVERT(varchar(10), t1.status) AS status,
        CONVERT(varchar(15), t1.command) AS command,
        CONVERT(varchar(10), t2.state) AS worker_state,
        w_suspended =
          CASE t2.wait_started_ms_ticks
            WHEN 0 THEN 0
            ELSE
              t3.ms_ticks - t2.wait_started_ms_ticks
          END,
        w_runnable =
          CASE t2.wait_resumed_ms_ticks
            WHEN 0 THEN 0
            ELSE
              t3.ms_ticks - t2.wait_resumed_ms_ticks
          END
      FROM sys.dm_exec_requests AS t1
      INNER JOIN sys.dm_os_workers AS t2
        ON t2.task_address = t1.task_address
      CROSS JOIN sys.dm_os_sys_info AS t3
      WHERE t1.scheduler_id IS NOT NULL;

Tasks
-----

Each task when it's executing receives a worker. You can find its worker address by checking `worker_address` column of the `sys.dm_os_tasks` view. Each worker is bound to a thread - you can find `thread_address` in the `sys.dm_os_workers` view.

The below query joins the waiting tasks with their corresponding sessions and requests showing also executing queries and query plans:

    SELECT
      [owt].[session_id],
      [owt].[exec_context_id],
      [owt].[wait_duration_ms],
      [owt].[wait_type],
      [owt].[blocking_session_id],
      [owt].[resource_description],
      [es].[program_name],
      [est].[text],
      [est].[dbid],
      [eqp].[query_plan],
      [es].[cpu_time],
      [es].[memory_usage]
    FROM sys.dm_os_waiting_tasks [owt]
    INNER JOIN sys.dm_exec_sessions [es] ON
      [owt].[session_id] = [es].[session_id]
    INNER JOIN sys.dm_exec_requests [er] ON
      [es].[session_id] = [er].[session_id]
    OUTER APPLY sys.dm_exec_sql_text ([er].[sql_handle]) [est]
    OUTER APPLY sys.dm_exec_query_plan ([er].[plan_handle]) [eqp]
    WHERE [es].[is_user_process] = 1
    ORDER BY [owt].[session_id], [owt].[exec_context_id]
    GO

Shows tasks for a given scheduler:

    select * from sys.dm_os_tasks t
        inner join sys.dm_os_workers w on w.worker_address = t.worker_address
        inner join sys.dm_os_schedulers s on w.scheduler_address = s.scheduler_address
            where s.scheduler_id = 255

Waits statistics are stored in a `sys.dm_os_wait_stats` view. To show the **TOP 95% of wait types** you may use the following query:

    WITH [Waits] AS
      (SELECT
        [wait_type],
        [wait_time_ms] / 1000.0 AS [WaitS],
        ([wait_time_ms] - [signal_wait_time_ms]) / 1000.0 AS [ResourceS],
        [signal_wait_time_ms] / 1000.0 AS [SignalS],
        [waiting_tasks_count] AS [WaitCount],
        100.0 * [wait_time_ms] / SUM ([wait_time_ms]) OVER() AS [Percentage],
        ROW_NUMBER() OVER(ORDER BY [wait_time_ms] DESC) AS [RowNum]
      FROM sys.dm_os_wait_stats
      WHERE [wait_type] NOT IN (
        N'CLR_SEMAPHORE',    N'LAZYWRITER_SLEEP',
        N'RESOURCE_QUEUE',   N'SQLTRACE_BUFFER_FLUSH',
        N'SLEEP_TASK',       N'SLEEP_SYSTEMTASK',
        N'WAITFOR',          N'HADR_FILESTREAM_IOMGR_IOCOMPLETION',
        N'CHECKPOINT_QUEUE', N'REQUEST_FOR_DEADLOCK_SEARCH',
        N'XE_TIMER_EVENT',   N'XE_DISPATCHER_JOIN',
        N'LOGMGR_QUEUE',     N'FT_IFTS_SCHEDULER_IDLE_WAIT',
        N'BROKER_TASK_STOP', N'CLR_MANUAL_EVENT',
        N'CLR_AUTO_EVENT',   N'DISPATCHER_QUEUE_SEMAPHORE',
        N'TRACEWRITE',       N'XE_DISPATCHER_WAIT',
        N'BROKER_TO_FLUSH',  N'BROKER_EVENTHANDLER',
        N'FT_IFTSHC_MUTEX',  N'SQLTRACE_INCREMENTAL_FLUSH_SLEEP',
        N'DIRTY_PAGE_POLL')
      )
    SELECT
      [W1].[wait_type] AS [WaitType],
      CAST ([W1].[Waits] AS DECIMAL(14, 2)) AS [Wait_S],
      CAST ([W1].[Resources] AS DECIMAL(14, 2)) AS [Resource_S],
      CAST ([W1].[SignalS] AS DECIMAL(14, 2)) AS [Signal_S],
      [W1].[WaitCount] AS [WaitCount],
      CAST ([W1].[Percentage] AS DECIMAL(4, 2)) AS [Percentage],
      CAST (([W1].[WaitS] / [W1].[WaitCount]) AS DECIMAL (14, 4)) AS [AvgWait_S],
      CAST (([W1].[ResourceS] / [W1].[WaitCount]) AS DECIMAL (14, 4)) AS [AvgRes_S],
      CAST (([W1].[SignalS] / [W1].[WaitCount]) AS DECIMAL (14, 4)) AS [AvgSig_S]
    FROM [Waits] AS [W1]
    INNER JOIN [Waits] AS [W2]
      ON [W2].[RowNum] <= [W1].[RowNum]
    GROUP BY [W1].[RowNum], [W1].[wait_type], [W1].[WaitS],
      [W1].[ResourceS], [W1].[SignalS], [W1].[WaitCount], [W1].[Percentage]
    HAVING SUM ([W2].[Percentage]) - [W1].[Percentage] < 95; -- percentage threshold
    GO

Statatistics are cleared on a server restart. But you can also clear them manually by executing:

    DBCC SQLPERF('sys.dm_os_wait_stats', CLEAR);


Threads
-------

Threads in SQL Server can exist in one of the following queues:

- RUNNING
- SUSPENDED
- RUNNABLE

Every thread has an execution quantum equal to 4ms. Threads are transfered by the SQL Server scheduler from one queue to another. To get the status of the currently running schedulers you can use `sys.dm_os_schedulers` view. You can then query the state of scheduler tasks by checking the `sys.dm_os_tasks` view. Example query to group the tasks by their state for each scheduler running on a server:

    SELECT
      [ot].[scheduler_id],
      [task_state],
      COUNT (*) AS [task_count]
    FROM
      sys.dm_os_tasks AS [ot]
    INNER JOIN
      sys.dm_exec_requests AS [er]
        ON [ot].[session_id] = [er].[session_id]
    INNER JOIN
      sys.dm_exec_sessions AS [es]
        ON [er].[session_id] = [es].[session_id]
    WHERE
      [es].[is_user_process] = 1
    GROUP BY
      [ot].[scheduler_id],
      [task_state]
    ORDER BY
      [task_state],
      [ot].[scheduler_id];
    GO

    select t.* from sys.dm_os_threads t
        inner join sys.dm_os_workers w on w.worker_address = t.worker_address
        inner join sys.dm_os_schedulers s on w.scheduler_address = s.scheduler_address
            where s.scheduler_id = 255

To associate **session id** and **request id** with the **os threads** use the following query:

    SELECT STasks.session_id, STasks.request_id, STasks.task_address,
           Stasks.task_state,
           SThreads.os_thread_id, SThreads.thread_handle,
           SThreads.stack_base_address, SThreads.stack_end_address,
           SThreads.thread_address, SThreads.worker_address, SThreads.scheduler_address
      FROM sys.dm_os_tasks AS STasks
      INNER JOIN sys.dm_os_threads AS SThreads
        ON STasks.worker_address = SThreads.worker_address
      WHERE STasks.session_id IS NOT NULL
      ORDER BY STasks.session_id;

Unfortunately the request`_id column often contains only 0s.

