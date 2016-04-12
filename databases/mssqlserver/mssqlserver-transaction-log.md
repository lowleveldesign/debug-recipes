
MS SQL SERVER TRANSACTION LOG
-----------------------------

The easiest way to tell whether a database is in autotruncate mode is by using the catalog view called `sys.database_recovery_status` and looking in the column called `last_log_backup_lsn`. If that column value is null, the database is in autotruncate mode:

    select db_name(database_id), last_log_backup_lsn from sys.database_recovery_status

### Examining transactions logs ###

#### Virtual Log Files ####

`DBCC LOGINFO` command displays information on Virtual Log Files that the transaction log is composed of. Example output is:

    RecoveryUnitId FileId      FileSize             StartOffset          FSeqNo      Status      Parity CreateLSN
    0              2           262144               8192                 2094        0           64     0
    0              2           262144               270336               2091        0           128    0
    0              2           262144               532480               2092        0           128    0
    0              2           270336               794624               2093        0           128    0
    0              2           311296               1064960              2095        0           64     2094000000027200481
    0              2           262144               1376256              2096        2           64     2095000000043400090

We can store this information in our system table:

    USE master
    GO
    IF EXISTS  (SELECT 1 FROM sys.tables
       WHERE name = 'sp_LOGINFO')
     DROP TABLE sp_loginfo;
    GO
    CREATE TABLE sp_LOGINFO
    (FileId tinyint,
     FileSize bigint,
     StartOffset bigint,
     FSeqNo int,
     Status tinyint,
     Parity tinyint,
     CreateLSN numeric(25,0) );
    GO

    TRUNCATE TABLE sp_LOGINFO;
    INSERT INTO sp_LOGINFO
       EXEC ('DBCC LOGINFO');
    GO

#### Get active transaction log content ####

`DBCC LOG(<dbname>)` returns basic information on operations stored in the transaction log, example output:

    /*------------------------
    DBCC LOG(testdb)
    ------------------------*/
    Current LSN             Operation                       Context                         Transaction ID LogBlockGeneration
    ----------------------- ------------------------------- ------------------------------- -------------- --------------------
    00000830:0000009f:0001  LOP_BEGIN_XACT                  LCX_NULL                        0000:000f6b84  0
    00000830:0000009f:0002  LOP_BEGIN_XACT                  LCX_NULL                        0000:000f6b85  0
    00000830:0000009f:0003  LOP_MODIFY_ROW                  LCX_BOOT_PAGE                   0000:000f6b85  0
    00000830:0000009f:0004  LOP_MODIFY_ROW                  LCX_BOOT_PAGE                   0000:000f6b85  0
    00000830:0000009f:0005  LOP_MODIFY_ROW                  LCX_BOOT_PAGE                   0000:000f6b85  0
    00000830:0000009f:0006  LOP_MODIFY_ROW                  LCX_BOOT_PAGE                   0000:000f6b85  0
    00000830:0000009f:0007  LOP_COMMIT_XACT                 LCX_NULL                        0000:000f6b85  0
    00000830:0000009f:0008  LOP_COMMIT_XACT                 LCX_NULL                        0000:000f6b84  0
    00000830:000000a1:0001  LOP_SHRINK_NOOP                 LCX_DIAGNOSTICS                 0000:00000000  0
    00000830:000000a1:0002  LOP_MODIFY_ROW                  LCX_SCHEMA_VERSION              0000:00000000  0
    00000830:000000a1:0003  LOP_BEGIN_XACT                  LCX_NULL                        0000:000f6b86  0
    00000830:000000a1:0004  LOP_INSERT_ROWS                 LCX_CLUSTERED                   0000:000f6b86  0
    00000830:000000a1:0005  LOP_COMMIT_XACT                 LCX_NULL                        0000:000f6b86  0
    00000830:000000a3:0001  LOP_BEGIN_XACT                  LCX_NULL                        0000:000f6b87  0
    ...

To get more information we can use `fn_dblog(null, null)` table function. The two parameters are for filtering the start and end of a LSN number range which should be in a numeric format and not in its usual hexadecimal format:

    select * from fn_dblog(null, null)

#### Get backed up transaction log content ####

To read content from a backed-up transaction log we can use `fn_dump_dblog`. The starting parameters are:

- Starting LSN (usually just NULL)
- Ending LSN (again, usually just NULL)
- Type of file (DISK or TAPE)
- Backup number within the backup file (for multi-backup media sets)
- File name

For other parametrs we may use `DEFAULT` value:

    SELECT COUNT (*) FROM fn_dump_dblog (
        NULL, NULL, 'DISK', 1, 'D:\SQLskills\FNDBLogTest_Log2.bak',
        DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
        DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
        DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
        DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
        DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
        DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
        DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
        DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
        DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT);
    GO

### Log File Size ###

You can see the current size of the log file for all databases, as well as the percentage of the log file space that has been used, by running the command `DBCC SQLPERF(logspace)`:

    /*------------------------
    DBCC SQLPERF(logspace)
    ------------------------*/
    SQL Server parse and compile time:
       CPU time = 0 ms, elapsed time = 0 ms.
    Database Name                            Log Size (MB) Log Space Used (%) Status
    ---------------------------------------- ------------- ------------------ -----------
    master                                   1,742188      31,9787            0
    tempdb                                   0,4921875     59,52381           0
    model                                    0,9921875     52,85433           0
    msdb                                     5,054688      16,47025           0
    testdb                                   1,007813      53,34302           0
    Tools                                    1,007813      47,57752           0

    (6 row(s) affected)

However, because it is a DBCC command, it’s hard to filter the rows to get just the rows for a single database.

You may also find the file size by using `sys.database_files` (or `sys.master_files`) view:

    select name, physical_name, size * 8 * 1024 from sys.database_files where type_desc = 'LOG';

You can use the dynamic management `view sys.dm_os_performance_counters` and retrieve the percentage full for each database’s log:

    SELECT instance_name as [Database],
           cntr_value as "LogFullPct"
    FROM sys.dm_os_performance_counters
    WHERE counter_name LIKE 'Percent Log Used%'
        AND instance_name not in ('_Total', 'mssqlsystemresource')
        AND cntr_value > 0;

### Check transaction log usage by a transaction ###

You can use `sys.dm_tran_active_transactions` view to find an active transaction of your interest and then query its transaction log information from the `sys.dm_tran_database_transactions`. This view contains:

    - database_transaction_log_record_count
    - database_transaction_log_bytes_used
    - database_transaction_log_bytes_reserved
    - database_transaction_log_bytes_used_system
    - database_transaction_log_bytes_reserved_system

Additionally we can query information about the Log Sequence Number:

    - database_transaction_begin_lsn
    - database_transaction_last_lsn
    - database_transaction_most_recent_savepoint_lsn
    - database_transaction_commit_lsn
    - database_transaction_last_rollback_lsn
    - database_transaction_next_undo_lsn

The `sys.dm_tran_database_transactions` shows information about space of a transaction log that a given transaction is taking:

    SELECT
      [database_transaction_log_bytes_used]
    FROM
      sys.dm_tran_database_transactions
    WHERE
      [database_id] = DB_ID ('NestedTransactions');
    GO

### Links ###

- [SQL Server Transaction Log Fragmentation: a Primer](http://www.simple-talk.com/sql/database-administration/sql-server-transaction-log-fragmentation-a-primer/)
- [Using fn\_dblog, fn\_dump\_dblog, and restoring with STOPBEFOREMARK to an LSN](http://www.sqlskills.com/blogs/paul/post/Using-fn_dblog-fn_dump_dblog-and-restoring-with-STOPBEFOREMARK-to-an-LSN.aspx)
- [Using `fn_dblog`](http://killspid.blogspot.com/2006/07/using-fndblog.html)
- [Managing the SQL Server Transaction Log: Dealing with Explosive Log Growth](https://www.simple-talk.com/sql/database-administration/managing-the-sql-server-transaction-log-dealing-with-explosive-log-growth/)
- [Transaction Log Monitoring](http://www.sqlperformance.com/2013/11/sql-performance/transaction-log-monitoring)
- [Tackle WRITELOG Waits Using the Transaction Log and Extended Events](http://michaeljswart.com/2016/04/tackle_writelog/)
