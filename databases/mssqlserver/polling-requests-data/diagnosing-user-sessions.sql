-- list all sessions that were created by users
select s.session_id, s.login_time, s.host_name, s.program_name,
        s.login_name, s.status, s.reads, s.writes, s.is_user_process
    from sys.dm_exec_sessions s 
        where is_user_process = 1;
        
-- find requests in a session
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
   where req.session_id = @@spid; -- FIXME sessionid

/* get connections belonging to a given sessions 
   with their last executed sql statements */
select 
        s.host_name, s.program_name,
        st.text as lastStmt, 
        s.reads as session_reads, s.writes as session_writes, 
        cn.num_reads, cn.num_writes, 
        cn.last_read, cn.last_write, 
        s.login_name, s.status,
        s.login_time, 
        cn.connect_time, 
        cn.client_net_address, cn.client_tcp_port,
        cn.session_id, 
        cn.most_recent_session_id, 
        s.is_user_process
    from sys.dm_exec_connections cn
        inner join sys.dm_exec_sessions s on s.session_id = cn.session_id
        CROSS APPLY sys.dm_exec_sql_text(cn.most_recent_sql_handle) AS st
            where s.is_user_process = 1
                and s.session_id = @@spid;

-- find transactions in a session
select at.transaction_id, at.transaction_begin_time, at.transaction_state,
        st.session_id, st.is_user_transaction,
        db_name(dt.database_id) as dbname, dt.database_transaction_log_record_count,
        dt.database_transaction_log_bytes_reserved, dt.database_transaction_log_bytes_reserved_system,
        dt.database_transaction_log_bytes_used, dt.database_transaction_log_bytes_used_system,
        -- some more lsn values
        st.is_local
  from sys.dm_tran_active_transactions at
    inner join sys.dm_tran_database_transactions dt on dt.transaction_id = at.transaction_id
        left join sys.dm_tran_session_transactions st on st.transaction_id = dt.transaction_id
        where st.session_id = @@spid
        order by at.transaction_begin_time desc;

