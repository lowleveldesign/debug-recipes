
Diagnosing MySql
================

Checking server status (SHOW commands)
--------------------------------------

### System Variables ###

MySql exposes many variables through the `SHOW VARIABLES` command (or `mysqladmin variables` at the command line). You can also access those variables querying `INFORMATION_SCHEMA.GLOBAL_VARIABLES` table.

### SHOW STATUS ###

`SHOW STATUS` command displays server status variables. You can retrieve the same set of information by querying `INFORMATION_SCHEMA.GLOBAL_STATUS` and `INFORMATION_SCHEMA.SESSION_STATUS` tables. By using `SHOW STATUS` you see global and session variables combined together, but session variables overwrite global ones with the same names. To get global variables use `SHOW GLOBAL STATUS` command. Variables are grouped in sets using the underscore, for example we have `select_*` group for select statistics. This heavily simplifies status quries, eg.

    mysql> show status like 'select_%';
    +------------------------+-------+
    | Variable_name          | Value |
    +------------------------+-------+
    | Select_full_join       | 0     |
    | Select_full_range_join | 0     |
    | Select_range           | 0     |
    | Select_range_check     | 0     |
    | Select_scan            | 5     |
    +------------------------+-------+
    5 rows in set (0.00 sec)

For a side-by-side view of current and previous snapshots and the differences between them you may use the following query:

    SELECT STRAIGHT_JOIN
      LOWER(gs0.VARIABLE_NAME) AS variable_name,
      gs0.VARIABLE_VALUE AS value_0,
      gs1.VARIABLE_VALUE AS value_1,
      (gs1.VARIABLE_VALUE - gs0.VARIABLE_VALUE) AS diff,
      (gs1.VARIABLE_VALUE - gs0.VARIABLE_VALUE) / 10 AS per_sec,
      (gs1.VARIABLE_VALUE - gs0.VARIABLE_VALUE) * 60 / 10 AS per_min
      FROM (
        SELECT VARIABLE_NAME, VARIABLE_VALUE
        FROM INFORMATION_SCHEMA.GLOBAL_STATUS
        UNION ALL
        SELECT '', SLEEP(10) FROM DUAL
        ) AS gs0
        JOIN INFORMATION_SCHEMA.GLOBAL_STATUS gs1 USING (VARIABLE_NAME)
        WHERE gs1.VARIABLE_VALUE <> gs0.VARIABLE_VALUE;
    +-----------------------+---------+---------+------+---------+---------+
    | variable_name         | value_0 | value_1 | diff | per_sec | per_min |
    +-----------------------+---------+---------+------+---------+---------+
    | handler_read_rnd_next | 1035    | 1658    |  623 |    62.3 |    3738 |
    | handler_write         | 1011    | 1943    |  932 |    93.2 |    5592 |
    | open_files            | 10      | 8       |   -2 |    -0.2 |     -12 |
    | select_full_join      | 0       | 1       |    1 |     0.1 |       6 |
    | select_scan           | 8       | 10      |    2 |     0.2 |      12 |
    +-----------------------+---------+---------+------+---------+---------+
    5 rows in set (10.08 sec)

A list of all status variables can be found here: <http://dev.mysql.com/doc/refman/5.5/en/mysqld-option-tables.html>. Variables can be grouped by their genre.

#### Thread and Connection statistics ####

    show status where variable_name in (
      'Connections'
     ,'Max_used_connections'
     ,'Threads_connected'
     ,'Aborted_clients'
     ,'Aborted_connects'
     ,'Bytes_received'
     ,'Bytes_sent'
     ,'Slow_launch_threads'
     ,'Threads_cached'
     ,'Threads_created'
     ,'Threads_running');

    +----------------------+-------+
    | Variable_name        | Value |
    +----------------------+-------+
    | Aborted_clients      | 0     |
    | Aborted_connects     | 0     |
    | Bytes_received       | 1365  |
    | Bytes_sent           | 28892 |
    | Connections          | 2     |
    | Max_used_connections | 1     |
    | Slow_launch_threads  | 0     |
    | Threads_cached       | 0     |
    | Threads_connected    | 1     |
    | Threads_created      | 1     |
    | Threads_running      | 1     |
    +----------------------+-------+
    11 rows in set (0.00 sec)

`Aborted_connects` might indicate some serious netowork problems. `Aborted_clients` usually just means that there were some bugs in applications connecting to MySql (like not closed connections etc.).

#### Binary Logging Status ####

    show status where variable_name in (
          'Binlog_cache_use'
         ,'Binlog_cache_disk_use'
         ,'Binlog_stmt_cache_use'
         ,'Binlog_stmt_cache_disk_use');

    +----------------------------+-------+
    | Variable_name              | Value |
    +----------------------------+-------+
    | Binlog_cache_disk_use      | 0     |
    | Binlog_cache_use           | 0     |
    | Binlog_stmt_cache_disk_use | 0     |
    | Binlog_stmt_cache_use      | 0     |
    +----------------------------+-------+
    4 rows in set (0.00 sec)


Those variable show how many transactions have been stored in the binary log cache, and how many transactions were too large for the binary log cache and so had their statements stored in a temporary file. MySQL 5.5 also includes Binlog_stmt_cache_use and Binlog_stmt_cache_disk_use, which show corresponding metrics for nontransactional statements.

#### Command Counters ####

`Com_*` variables count the number of times each type of SQL or C API commands has been issued.

#### Temporary Files and Tables ####

    show global STATUS LIKE 'Created_tmp%';

    +-------------------------+-------+
    | Variable_name           | Value |
    +-------------------------+-------+
    | Created_tmp_disk_tables | 2     |
    | Created_tmp_files       | 5     |
    | Created_tmp_tables      | 16    |
    +-------------------------+-------+
    3 rows in set (0.00 sec)

#### File Descriptors ####

    SHOW GLOBAL STATUS LIKE 'Open_%';

    +--------------------------+-------+
    | Variable_name            | Value |
    +--------------------------+-------+
    | Open_files               | 0     |
    | Open_streams             | 0     |
    | Open_table_definitions   | 33    |
    | Open_tables              | 0     |
    | Opened_files             | 91    |
    | Opened_table_definitions | 33    |
    | Opened_tables            | 35    |
    +--------------------------+-------+
    7 rows in set (0.00 sec)

#### Query Cache ####

    SHOW GLOBAL STATUS LIKE 'Qcache_%';

    +-------------------------+-------+
    | Variable_name           | Value |
    +-------------------------+-------+
    | Qcache_free_blocks      | 0     |
    | Qcache_free_memory      | 0     |
    | Qcache_hits             | 0     |
    | Qcache_inserts          | 0     |
    | Qcache_lowmem_prunes    | 0     |
    | Qcache_not_cached       | 0     |
    | Qcache_queries_in_cache | 0     |
    | Qcache_total_blocks     | 0     |
    +-------------------------+-------+
    8 rows in set (0.00 sec)

#### Select queries ####

    SHOW GLOBAL STATUS LIKE 'Select_%';
    +------------------------+-------+
    | Variable_name          | Value |
    +------------------------+-------+
    | Select_full_join       | 1     |
    | Select_full_range_join | 0     |
    | Select_range           | 0     |
    | Select_range_check     | 0     |
    | Select_scan            | 19    |
    +------------------------+-------+
    5 rows in set (0.00 sec)

#### Sorts ####

    show global status like 'sort_%';
    +-------------------+-------+
    | Variable_name     | Value |
    +-------------------+-------+
    | Sort_merge_passes | 0     |
    | Sort_range        | 0     |
    | Sort_rows         | 0     |
    | Sort_scan         | 0     |
    +-------------------+-------+
    4 rows in set (0.00 sec)

#### Table Locking ####

The `Table_locks_immediate` and `Table_locks_waited` variables tell you how many locks were granted immediately and how many had to be waited for. Be aware, however, that they show only server-level locking statistics, not storage engine locking statistics.

### SHOW ENGINE INNODB STATUS ###

    mysql> show engine innodb status;
    +--------+------+--------------------------------------------------------------------------------------------------
    -------------------------------------------------------------------------------------------------------------------
    | Type   | Name | Status
    +--------+------+--------------------------------------------------------------------------------------------------
    -------------------------------------------------------------------------------------------------------------------
    | InnoDB |      |
    =====================================
    120726 21:50:12 INNODB MONITOR OUTPUT
    =====================================
    Per second averages calculated from the last 31 seconds
    -----------------
    BACKGROUND THREAD
    -----------------
    srv_master_thread loops: 1 1_second, 1 sleeps, 0 10_second, 1 background, 1 flush
    srv_master_thread log flush and writes: 1
    ----------
    SEMAPHORES
    ----------
    OS WAIT ARRAY INFO: reservation count 2, signal count 2
    Mutex spin waits 1, rounds 25, OS waits 0
    RW-shared spins 2, rounds 60, OS waits 2
    RW-excl spins 0, rounds 0, OS waits 0
    Spin rounds per wait: 25.00 mutex, 30.00 RW-shared, 0.00 RW-excl
    ------------
    TRANSACTIONS
    ------------
    Trx id counter 2100
    Purge done for trx's n:o < 1F15 undo n:o < 0
    History list length 423
    LIST OF TRANSACTIONS FOR EACH SESSION:
    ---TRANSACTION 0, not started
    MySQL thread id 1, OS thread handle 0x2c0, query id 23 localhost 127.0.0.1 root
    show engine innodb status
    --------
    FILE I/O
    --------
    I/O thread 0 state: wait Windows aio (insert buffer thread)
    I/O thread 1 state: wait Windows aio (log thread)
    I/O thread 2 state: wait Windows aio (read thread)
    I/O thread 3 state: wait Windows aio (read thread)
    I/O thread 4 state: wait Windows aio (read thread)
    I/O thread 5 state: wait Windows aio (read thread)
    I/O thread 6 state: wait Windows aio (write thread)
    I/O thread 7 state: wait Windows aio (write thread)
    I/O thread 8 state: wait Windows aio (write thread)
    I/O thread 9 state: wait Windows aio (write thread)
    Pending normal aio reads: 0 [0, 0, 0, 0] , aio writes: 0 [0, 0, 0, 0] ,
     ibuf aio reads: 0, log i/o's: 0, sync i/o's: 0
    Pending flushes (fsync) log: 0; buffer pool: 0
    407 OS file reads, 3 OS file writes, 3 OS fsyncs
    0.00 reads/s, 0 avg bytes/read, 0.00 writes/s, 0.00 fsyncs/s
    -------------------------------------
    INSERT BUFFER AND ADAPTIVE HASH INDEX
    -------------------------------------
    Ibuf: size 1, free list len 0, seg size 2, 0 merges
    merged operations:
     insert 0, delete mark 0, delete 0
    discarded operations:
     insert 0, delete mark 0, delete 0
    Hash table size 276707, node heap has 1 buffer(s)
    0.00 hash searches/s, 0.00 non-hash searches/s
    ---
    LOG
    ---
    Log sequence number 3451649
    Log flushed up to   3451649
    Last checkpoint at  3451649
    0 pending log writes, 0 pending chkp writes
    8 log i/o's done, 0.00 log i/o's/second
    ----------------------
    BUFFER POOL AND MEMORY
    ----------------------
    Total memory allocated 137363456; in additional pool allocated 0
    Dictionary memory allocated 33650
    Buffer pool size   8192
    Free buffers       7795
    Database pages     396
    Old database pages 0
    Modified db pages  0
    Pending reads 0
    Pending writes: LRU 0, flush list 0, single page 0
    Pages made young 0, not young 0
    0.00 youngs/s, 0.00 non-youngs/s
    Pages read 396, created 0, written 0
    0.00 reads/s, 0.00 creates/s, 0.00 writes/s
    No buffer pool page gets since the last printout
    Pages read ahead 0.00/s, evicted without access 0.00/s, Random read ahead 0.00/s
    LRU len: 396, unzip_LRU len: 0
    I/O sum[0]:cur[0], unzip sum[0]:cur[0]
    --------------
    ROW OPERATIONS
    --------------
    0 queries inside InnoDB, 0 queries in queue
    1 read views open inside InnoDB
    Main thread id 6380, state: waiting for server activity
    Number of rows inserted 0, updated 0, deleted 0, read 0
    0.00 inserts/s, 0.00 updates/s, 0.00 deletes/s, 0.00 reads/s
    ----------------------------
    END OF INNODB MONITOR OUTPUT
    ============================
     |
    +--------+------+--------------------------------------------------------------------------------------------------
    -------------------------------------------------------------------------------------------------------------------
    1 row in set (0.02 sec)

### SHOW [FULL] PROCESSLIST ###

    mysql> show processlist\G
    *************************** 1. row ***************************
         Id: 1
       User: root
       Host: localhost:2464
         db: information_schema
    Command: Query
       Time: 0
      State: NULL
       Info: show processlist
    1 row in set (0.00 sec)


### Replication status ###

    mysql> SHOW MASTER STATUS\G
    *************************** 1. row ***************************
                File: mysql-bin.000079
            Position: 13847
        Binlog_Do_DB:
    Binlog_Ignore_DB:
    The output includes the master’s current binary log position. You can get a list of binary logs with SHOW BINARY LOGS:
     mysql> SHOW BINARY LOGS
    +------------------+-----------+
    | Log_name         | File_size |
    +------------------+-----------+
    | mysql-bin.000044 |     13677 |
    ...
    | mysql-bin.000079 |     13847 |
    +------------------+-----------+
    36 rows in set (0.18 sec)


INFORMATION\_SCHEMA
-------------------

There is a set of very useful views created over the `INFORMATION_SCHEMA` that can be downloaded from <http://code.openark.org/forge/common_schema>.

    mysql> show tables;
    +---------------------------------------+
    | Tables_in_information_schema          |
    +---------------------------------------+
    | CHARACTER_SETS                        |
    | COLLATIONS                            |
    | COLLATION_CHARACTER_SET_APPLICABILITY |
    | COLUMNS                               |
    | COLUMN_PRIVILEGES                     |
    | ENGINES                               |
    | EVENTS                                |
    | FILES                                 |
    | GLOBAL_STATUS                         |
    | GLOBAL_VARIABLES                      |
    | KEY_COLUMN_USAGE                      |
    | PARAMETERS                            |
    | PARTITIONS                            |
    | PLUGINS                               |
    | PROCESSLIST                           |
    | PROFILING                             |
    | REFERENTIAL_CONSTRAINTS               |
    | ROUTINES                              |
    | SCHEMATA                              |
    | SCHEMA_PRIVILEGES                     |
    | SESSION_STATUS                        |
    | SESSION_VARIABLES                     |
    | STATISTICS                            |
    | TABLES                                |
    | TABLESPACES                           |
    | TABLE_CONSTRAINTS                     |
    | TABLE_PRIVILEGES                      |
    | TRIGGERS                              |
    | USER_PRIVILEGES                       |
    | VIEWS                                 |
    | INNODB_CMP_RESET                      |
    | INNODB_TRX                            |
    | INNODB_CMPMEM_RESET                   |
    | INNODB_LOCK_WAITS                     |
    | INNODB_CMPMEM                         |
    | INNODB_CMP                            |
    | INNODB_LOCKS                          |
    +---------------------------------------+
    37 rows in set (0.00 sec)

Links
-----

- [Capture database traffic using the Performance Schema](https://www.percona.com/blog/2015/10/01/capture-database-traffic-using-performance-schema/)

