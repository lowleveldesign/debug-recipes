;with frequent_queries as
(
    select top 20 
        query_hash, 
        sum(execution_count) executions
    from sys.dm_exec_query_stats 
    where query_hash <> 0x0
    group by query_hash
    order by sum(execution_count) desc
)
select @@servername as server_name,
    db_name(st.dbid) as database_name,
    object_name(ST.objectid, ST.dbid) as [object_name],
    qs.query_hash,
    qs.execution_count,
    executions as total_executions_for_query,
    SUBSTRING(ST.TEXT,(QS.statement_start_offset + 2) / 2,
        (CASE 
            WHEN QS.statement_end_offset = -1  THEN LEN(CONVERT(NVARCHAR(MAX),ST.text)) * 2
            ELSE QS.statement_end_offset
            END - QS.statement_start_offset) / 2) as sql_text,
    qp.query_plan
from sys.dm_exec_query_stats qs
join frequent_queries fq
    on fq.query_hash = qs.query_hash
cross apply sys.dm_exec_sql_text(qs.sql_handle) st
cross apply sys.dm_exec_query_plan (qs.plan_handle) qp
order by fq.executions desc,
    fq.query_hash,
    qs.execution_count desc
option (recompile)
