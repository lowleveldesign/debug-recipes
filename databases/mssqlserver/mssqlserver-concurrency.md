
Diagnosing concurrency issues in MS SQL Server
==============================================

Requests and sessions
-------------------

### Get currently executing requests ###

Show request info plus **the executed sql statement** for the current database:

    select substring(text, (statement_start_offset/2) + 1,
       ((case statement_end_offset
            when -1
               then datalength(text)
            else statement_end_offset
       end - statement_start_offset)/2) + 1) as query_text,
       pl.query_plan,
       req.start_time, req.total_elapsed_time, req.status, req.command,
       req.user_id, req.connection_id, req.wait_type,
       req.transaction_id, req.percent_complete,
       req.cpu_time, req.total_elapsed_time,
       req.reads, req.writes, req.logical_reads,
       req.transaction_isolation_level, req.row_count,
       req.transaction_id, princ.name as 'user'
    from sys.dm_exec_requests req
       inner join sys.database_principals princ on princ.principal_id = req.user_id
       cross apply sys.dm_exec_sql_text(req.sql_handle)
       cross apply sys.dm_exec_query_plan(req.plan_handle) pl
       where req.database_id = DB_ID();

We may retrieve **the query plan** for a given request:

    select req.start_time, req.total_elapsed_time, req.status, req.command,
       req.user_id, req.connection_id, req.wait_type,
       req.transaction_id, req.percent_complete,
       req.cpu_time, req.total_elapsed_time,
       req.reads, req.writes, req.logical_reads,
       req.transaction_isolation_level, req.row_count,
       req.transaction_id, princ.name as 'user',query_plan from sys.dm_exec_requests req
      inner join sys.database_principals princ on princ.sid = req.user_id
      cross apply sys.dm_exec_query_plan(req.plan_handle)
      where req.database_id = DB_ID()

### Find last running query in a session ###

We can get most recent query from the connections that belong to a given session:

    select  c.session_id
           ,sq.text
           ,c.connect_time
           ,c.protocol_type
           ,c.num_reads
           ,c.num_writes
           ,c.client_net_address
           ,c.connection_id
           ,c.most_recent_session_id
    from sys.dm_exec_connections c
        cross apply sys.dm_exec_sql_text(c.most_recent_sql_handle) sq
        where c.session_id in (1)
            or c.most_recent_session_id in (1)

Transactions
------------

### Nested transactions ###

Transactions can be nested in TSQL, but they won't be treated separately. When you place `COMMIT` after a nested transaction only the `@@TRANCOUNT` will be decremented, but no changes in the transaction log will happen. The nested transactions will be committed only after the outer transaction is committed (thus when `@@TRANCOUNT = 0`).

### Find active transactions with sessions that they belong to ###

    select sess.session_id
          ,sess.host_name
          ,sess.program_name
          ,sess.login_name
          ,dt.transaction_id
          ,dt.database_transaction_begin_time
          ,dt.database_transaction_state
          ,dt.database_transaction_log_record_count
          ,dt.database_transaction_log_bytes_used
          ,dt.database_transaction_log_bytes_reserved
          ,dt.database_transaction_begin_lsn
          ,dt.database_transaction_last_lsn
          ,st.is_user_transaction
    from sys.dm_tran_active_transactions at
        join sys.dm_tran_database_transactions dt on at.transaction_id = dt.transaction_id
        join sys.dm_tran_session_transactions st on st.transaction_id = dt.transaction_id
        join sys.dm_exec_sessions sess on sess.session_id = st.session_id

### Find transaction locks with blocking queries ###

    select WT.session_id as waiting_session_id,
           DB_NAME(TL.resource_database_id) as DatabaseName,
           WT.wait_duration_ms,
           WT.waiting_task_address,
           TL.request_mode,
           (select SUBSTRING(ST.text, (ER.statement_start_offset / 2) + 1, ((case ER.statement_end_offset
              when -1 then DATALENGTH(ST.text) else ER.statement_end_offset
              end - ER.statement_start_offset) / 2) + 1)
            from   sys.dm_exec_requests as ER cross apply sys.dm_exec_sql_text (ER.sql_handle) as ST
            where  ER.session_id = TL.request_session_id) as waiting_query_text,
           TL.resource_type,
           TL.resource_associated_entity_id,
           WT.wait_type,
           WT.blocking_session_id,
           WT.resource_description as blocking_resource_description,
           case
    when WT.blocking_session_id > 0 then (select ST2.text
                                                      from   sys.sysprocesses as SP cross apply sys.dm_exec_sql_text (SP.sql_handle) as ST2
                                                      where  SP.spid = WT.blocking_session_id) else null
    end as blocking_query_text
    from   sys.dm_os_waiting_tasks as WT
           inner join
           sys.dm_tran_locks as TL
           on WT.resource_address = TL.lock_owner_address
    where  WT.wait_duration_ms > 5000
           and WT.session_id > 50;

Locks
-----

Information about transaction locks are hold in the `sys.dm_tran_locks` system view. The <code>resource_associated_entity_id</code> can be an object ID, Hobt ID, or an Allocation Unit ID, depending on the resource type. Hobt ID corresponds to the `sys.partitions.hobt_id` column and Allocation Unit ID references `sys.allocation_units.allocation_unit_id`.

### Find locks in the current database ###

We can find requests with their blocking counterparts by using `sp_who(2)` procedures:

    sp_who [ [ @loginame = ] 'login' | session ID | 'ACTIVE' ]

You can get even more verbose information by using **sp\_who2** but with no filtering support. Example:

    exec sp_who @loginame='testuser';

    -- get info about a particular session
    declare @spid int;
    set @spid = 51
    exec sp_who @spid;

Similar results might be achieved with querying `sys.dm_tran_locks` view:

    select l.request_status, l.request_mode, l.resource_type, l.request_session_id,
           s.host_name, s.program_name, s.host_process_id, s.login_name, s.status,
           s.reads, s.writes, s.is_user_process,
           l.resource_subtype, l.resource_description,
           l.resource_associated_entity_id
    from sys.dm_tran_locks l inner join sys.dm_exec_sessions s
            on s.session_id = l.request_session_id where l.resource_database_id = db_id()

### Find waiting transactions and their blocking counterparts ###

You will have to run this query in each database in question to get all the object names:

    SELECT
       TL1.resource_type,
       DB_NAME(TL1.resource_database_id) AS DatabaseName,
       CASE TL1.resource_type
          WHEN 'OBJECT' THEN OBJECT_NAME(TL1.resource_associated_entity_id,
             TL1.resource_database_id)
          WHEN 'DATABASE' THEN 'DATABASE'
          ELSE
             CASE
                WHEN TL1.resource_database_id = DB_ID() THEN
                    (SELECT OBJECT_NAME(object_id, TL1.resource_database_id)
                     FROM sys.partitions
                     WHERE hobt_id = TL1.resource_associated_entity_id)
                ELSE NULL
             END
       END AS ObjectName,
       TL1.resource_description,
       TL1.request_session_id,
       TL1.request_mode,
       TL1.request_status
    FROM sys.dm_tran_locks AS TL1
       JOIN sys.dm_tran_locks AS TL2
       ON TL1.resource_associated_entity_id = TL2.resource_associated_entity_id
    WHERE TL1.request_status <> TL2.request_status
       AND (TL1.resource_description = TL2.resource_description
       OR (TL1.resource_description IS NULL
       AND TL2.resource_description IS NULL))
    ORDER BY TL1.resource_database_id,
       TL1.resource_associated_entity_id,
       TL1.request_status ASC;

### Find locks acquired by a given session ###

You can get information about locks from a given session by issuing:

    sp_lock [ [ @spid1 = ] 'session ID1' ] [ , [@spid2 = ] 'session ID2' ]

### Find transaction locks that last longer than ... ###

    select WT.session_id as waiting_session_id,
           DB_NAME(TL.resource_database_id) as DatabaseName,
           WT.wait_duration_ms,
           WT.waiting_task_address,
           TL.request_mode,
           TL.resource_type,
           TL.resource_associated_entity_id,
           TL.resource_description as lock_resource_description,
           WT.wait_type,
           WT.blocking_session_id,
           WT.resource_description as blocking_resource_description
    from   sys.dm_os_waiting_tasks as WT
           inner join
           sys.dm_tran_locks as TL
           on WT.resource_address = TL.lock_owner_address
    where  WT.wait_duration_ms > 5000
           and WT.session_id > @@spid;

### Troubleshoot dead-locks using Extended Events ###

I created a simple Extended Events session to find dead-lock cause:

    CREATE EVENT SESSION [deadlock-track] ON SERVER
    ADD EVENT sqlserver.lock_deadlock(SET collect_database_name=(0),collect_resource_description=(1)),
    ADD EVENT sqlserver.lock_deadlock_chain(SET collect_database_name=(0),collect_resource_description=(1)),
    ADD EVENT sqlserver.xml_deadlock_report(
        ACTION(sqlserver.client_app_name,sqlserver.client_connection_id,sqlserver.client_hostname,sqlserver.client_pid,sqlserver.session_id))
    ADD TARGET package0.histogram(SET filtering_event_name=N'sqlserver.lock_acquired',source=N'sqlserver.query_hash')
    WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=ON,STARTUP_STATE=OFF)
    GO

Actually the most interesting event in this set is `xml_deadlock_report` which provides a tremendous number of information about the dead-lock in the payload. Example xml file can be found in the same folder as this document.

