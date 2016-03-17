
Extended events in MS SQL Server
================================

Permission: ALTER ANY EVENT SESSION

## Creating an event session ##

In order to collect events you need to create a tracing session.

### 1. Choose events ###

When creating a session you need to decide which events are interesting for you:

    select * from sys.dm_xe_objects where object_type = 'event'

or even more interesting query:

    USE msdb
    SELECT p.name, c.event, k.keyword, c.channel, c.description FROM
    (
    SELECT event_package=o.package_guid, o.description,
    event=c.object_name, channel=v.map_value
    FROM sys.dm_xe_objects o
    LEFT JOIN sys.dm_xe_object_columns c ON o.name=c.object_name
    INNER JOIN sys.dm_xe_map_values v ON c.type_name=v.name
    AND c.column_value=cast(v.map_key AS nvarchar)
    WHERE object_type='event' AND (c.name='CHANNEL' or c.name IS NULL)

    ) c LEFT JOIN
    (
    SELECT event_package=c.object_package_guid, event=c.object_name,
    keyword=v.map_value
    FROM sys.dm_xe_object_columns c INNER JOIN sys.dm_xe_map_values v
    ON c.type_name=v.name AND c.column_value=v.map_key
    AND c.type_package_guid=v.object_package_guid
    INNER JOIN sys.dm_xe_objects o ON o.name=c.object_name
    AND o.package_guid=c.object_package_guid
    WHERE object_type='event' AND c.name='KEYWORD'
    ) k
    ON
    k.event_package=c.event_package AND (k.event=c.event or k.event IS NULL)
    INNER JOIN sys.dm_xe_packages p ON p.guid=c.event_package
    ORDER BY name, event, keyword

### 2. Configure predicates and actions ###

You may then (optionally) configure actions and predicates for a given event. Following actions are available:

    SELECT p.name AS 'package_name', xo.name AS 'action_name', xo.description, xo.object_type
    FROM sys.dm_xe_objects AS xo
    JOIN sys.dm_xe_packages AS p
       ON xo.package_guid = p.guid
    WHERE xo.object_type = 'action'
    AND (xo.capabilities & 1 = 0
    OR xo.capabilities IS NULL)
    ORDER BY p.name, xo.name

Actions are special objects which add additional (computed) attributes to the event.

Predicates (replace event\_name with your chosen event name):

    SELECT * FROM sys.dm_xe_object_columns WHERE object_name = 'event_name' AND column_type = 'data'

    SELECT p.name AS package_name, xo.name AS predicate_name
       , xo.description, xo.object_type
    FROM sys.dm_xe_objects AS xo
    JOIN sys.dm_xe_packages AS p
       ON xo.package_guid = p.guid
    WHERE xo.object_type = 'pred_source'
    ORDER BY p.name, xo.name

### 3. Add targets ###

### 4. Configure global session options ###

Example:

    create event session [backup_calls]
    on server
    add event sqlserver.sql_statement_completed (
        action (sqlserver.sql_text, sqlserver.session_id, sqlserver.client_hostname,
                sqlserver.request_id, sqlserver.client_pid)
        where (
            source_database_id = 7 -- AssetManager
        )
    )
    add target package0.ring_buffer (
        set max_memory = 4096
    )
    with (
        max_memory = 4096KB,
        event_retention_mode = allow_single_event_loss,
        max_dispatch_latency = 5 seconds,
        memory_partition_mode = none,
        track_causality = off,
        startup_state = off
    )

## Collect events ##

### Start session ###

    alter event session [session_name] on server state = start

### Stop session ###

    alter event session [session_name] on server state = stop

### Query session data ###

For ring buffer target:

    SELECT name, target_name, CAST(xet.target_data AS xml)
    FROM sys.dm_xe_session_targets AS xet
    JOIN sys.dm_xe_sessions AS xe
       ON (xe.address = xet.event_session_address)
    WHERE xe.name = 'session_name'

### Drop session ###

    drop event session [session_name] on server

Links
-----

- <https://www.simple-talk.com/sql/database-administration/getting-started-with-extended-events-in-sql-server-2012/>
- [Dissecting SQL Server physical reads with Extended Events and Process monitor](http://blogs.msdn.com/b/sql_pfe_blog/archive/2013/03/14/dissecting-sql-server-physical-reads-with-extended-events-and-process-monitor.aspx)
- [Using SQL Server 2008 Extended Events](https://technet.microsoft.com/en-us/library/dd822788(v=sql.100).aspx)
- [Using ETW for SQL Server 2005](http://blogs.msdn.com/b/sqlqueryprocessing/archive/2006/11/12/using-etw-for-sql-server-2005.aspx)
- [Troubleshooting SQL Server High CPU usage using Xperf](http://blogs.msdn.com/b/sql_pfe_blog/archive/2013/03/19/troubleshooting-sql-server-high-cpu-usage-using-xperf.aspx)
- [Identifying the cause of SQL Server IO bottlenecks using XPerf](http://blogs.msdn.com/b/sql_pfe_blog/archive/2013/04/23/identifying-cause-of-sql-server-io-bottleneck-using-xperf.aspx)
