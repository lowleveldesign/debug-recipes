
$probcnt = 0

while ($true) {

    & "C:\Program Files\Microsoft SQL Server\110\Tools\Binn\sqlcmd" -S srv -U user -P pass -d master -Q "select req.request_id, substring(text, (statement_start_offset/2) + 1, ((case statement_end_offset when -1 then datalength(text) else statement_end_offset end - statement_start_offset)/2) + 1) as query_text,    req.plan_handle, db_name(req.database_id) as database_name, req.start_time, req.total_elapsed_time, req.status, req.command, req.connection_id, req.session_id, req.blocking_Session_id, req.wait_type, req.transaction_id, req.percent_complete, req.cpu_time, req.reads, req.logical_reads, req.writes, req.transaction_isolation_level,
    princ.name as 'user', ses.host_name from sys.dm_exec_requests req inner join sys.dm_exec_sessions ses on ses.session_id = req.session_id inner join sys.database_principals princ on princ.principal_id = req.user_id cross apply sys.dm_exec_sql_text(req.sql_handle) where req.session_id <> @@spid order by start_time asc" | Out-File "c:\temp\mssql\output_$(get-date -format 'yyyyMMdd_hhmmss.ff').log"

    start-sleep -s 20

    if ($probcnt++ -gt 60) { break }
}
