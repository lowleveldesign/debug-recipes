select DB_ID('mydb')

create event session [backup_calls]
on server
add event sqlserver.sql_statement_completed (
	action (sqlserver.sql_text, sqlserver.session_id, sqlserver.client_hostname,
			sqlserver.request_id, sqlserver.client_pid)
	where (
		source_database_id = 7 -- database id
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


select * from sys.dm_xe_sessions;

alter event session backup_calls on server state = start

alter event session backup_calls on server state = stop

drop event session backup_calls on server


SELECT name, target_name, cast(xet.target_data as XML)
FROM sys.dm_xe_session_targets AS xet
JOIN sys.dm_xe_sessions AS xe
   ON (xe.address = xet.event_session_address)
WHERE xe.name = 'backup_calls'


SELECT
	theNodes.event_data.value('(data/value)[1]','bigint') AS source_database_id,
	theNodes.event_data.value('(data/value)[2]','bigint') AS object_id,
	theNodes.event_data.value('(data/value)[3]','bigint') AS object_type,
	theNodes.event_data.value('(data/value)[4]','bigint') AS cpu,
	theNodes.event_data.value('(data/value)[5]','bigint') AS duration,
	theNodes.event_data.value('(data/value)[6]','bigint') AS reads,
	theNodes.event_data.value('(data/value)[7]','bigint') AS writes,
	theNodes.event_data.value('(action/value)[1]','nvarchar(max)') AS sql_text,
	theNodes.event_data.value('(action/value)[2]','bigint') AS session_id,
	theNodes.event_data.value('(action/value)[3]','nvarchar(max)') AS client_hostname,
	theNodes.event_data.value('(action/value)[4]','bigint') AS request_id,
	theNodes.event_data.value('(action/value)[5]','bigint') AS client_pid
FROM (SELECT CONVERT(XML,st.target_data) AS ring_buffer FROM sys.dm_xe_sessions s
	JOIN sys.dm_xe_session_targets st ON s.address=st. event_session_address
		WHERE s.name = 'backup_calls') AS theData
		CROSS APPLY theData.ring_buffer.nodes('//RingBufferTarget/event') theNodes(event_data)



select * from sys.dm_xe_session_targets

select top 10 * from test

backup database mydb
	to disk = 'c:\temp\am_log.bak'
