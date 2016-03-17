
MS SQL Server - troubleshooting IO
==================================

Findind most used disks
-----------------------

This query might help if you are about buying a faster hard drive and would like to know which of your current drives suffers from overload:

    SELECT LEFT(MF.physical_name, 1)     AS DRIVE_LETTER,
    sample_ms,
    SUM(VFS.num_of_writes)        AS TOTAL_NUM_OF_WRITES,
    SUM(VFS.num_of_bytes_written) AS TOTAL_NUM_OF_BYTES_WRITTEN,
    SUM(VFS.io_stall_write_ms)    AS TOTAL_IO_STALL_WRITE_MS,
    SUM(VFS.num_of_reads)         AS TOTAL_NUM_OF_READS,
    SUM(VFS.num_of_bytes_read)    AS TOTAL_NUM_OF_BYTES_READ,
    SUM(VFS.io_stall_read_ms)     AS TOTAL_IO_STALL_READ_MS,
    SUM(VFS.io_stall)             AS TOTAL_IO_STALL,
    SUM(VFS.size_on_disk_bytes)   AS TOTAL_SIZE_ON_DISK_BYTES
    FROM   sys.master_files MF
    JOIN sys.DM_IO_VIRTUAL_FILE_STATS(NULL, NULL) VFS
    ON MF.database_id = VFS.database_id
                AND MF.file_id = VFS.file_id
    GROUP  BY LEFT(MF.physical_name, 1),
              sample_ms

Getting IO statistics for your queries
--------------------------------------

Based on <http://sqlblog.com/blogs/jamie_thomson/archive/2014/03/05/capturing-query-and-io-statistics-using-extended-events.aspx>

The simplest (and most common) way to get IO statistics is to enable them in the output window:

    SET STATISTICS TIME ON
    SET STATISTICS IO ON

It is not always convenient - for instance you can't query this info. So as an alternative you may use those system variables:

    @@QUERYPARSETIME
    @@QUERYCOMPILETIME
    @@QUERYEXECUTIONTIME
    @@SCANCOUNT
    @@LOGICALREADS
    @@PHYSICALREADS
    @@READAHEADREADS

or create an XEvents session:

    --Create the event session
    CREATE EVENT SESSION [queryperf] ON SERVER
    ADD EVENT sqlserver.sql_statement_completed
    ADD TARGET package0.event_file(SET filename=N'C:\temp\queryperf.xel',max_file_size=(2),max_rollover_files=(100))
    WITH (  MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_MULTIPLE_EVENT_LOSS,
                 MAX_DISPATCH_LATENCY=120 SECONDS,MAX_EVENT_SIZE=0 KB,
                 MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=ON);

    --Set up some demo queries against AdventureWorks2012 in order to evaluate query time & IO
    USE AdventureWorks2012
    DECLARE    @SalesPersonID INT;
    DECLARE    @salesTally INT;
    DECLARE    mycursor CURSOR FOR
    SELECT soh.SalesPersonID
    FROM   Sales.SalesOrderHeader soh
    GROUP  BY soh.SalesPersonID;
    OPEN mycursor;
    FETCH NEXT FROM mycursor INTO @SalesPersonID;
    ALTER EVENT SESSION [queryperf] ON SERVER STATE = START;
    WHILE @@FETCH_STATUS = 0
    BEGIN
           DBCC FREEPROCCACHE;
           DBCC DROPCLEANBUFFERS;
           CHECKPOINT;
           SELECT @salesTally = COUNT(*)
           FROM Sales.SalesOrderHeader  soh
           INNER JOIN Sales.[SalesOrderDetail] sod        ON  soh.[SalesOrderID] = sod.[SalesOrderID]
           WHERE SalesPersonID = @SalesPersonID
           FETCH NEXT FROM mycursor INTO @SalesPersonID;
    END
    CLOSE mycursor;
    DEALLOCATE mycursor;
    DROP EVENT SESSION [queryperf] ON SERVER;

    --Extract query information from the XEvents target
    SELECT q.duration,q.cpu_time,q.physical_reads,q.logical_reads,q.writes--,event_data_XML,statement,timestamp
    FROM   (
           SELECT  duration=e.event_data_XML.value('(//data[@name="duration"]/value)[1]','int')
           ,       cpu_time=e.event_data_XML.value('(//data[@name="cpu_time"]/value)[1]','int')
           ,       physical_reads=e.event_data_XML.value('(//data[@name="physical_reads"]/value)[1]','int')
           ,       logical_reads=e.event_data_XML.value('(//data[@name="logical_reads"]/value)[1]','int')
           ,       writes=e.event_data_XML.value('(//data[@name="writes"]/value)[1]','int')
           ,       statement=e.event_data_XML.value('(//data[@name="statement"]/value)[1]','nvarchar(max)')
           ,       TIMESTAMP=e.event_data_XML.value('(//@timestamp)[1]','datetime2(7)')
           ,       *
           FROM    (
                   SELECT CAST(event_data AS XML) AS event_data_XML
                   FROM sys.fn_xe_file_target_read_file('C:\temp\queryperf*.xel', NULL, NULL, NULL)
                   )e
           )q
    WHERE  q.[statement] LIKE 'select @salesTally = count(*)%' --Filters out all the detritus that we're not interested in!
    ORDER  BY q.[timestamp] ASC
    ;
