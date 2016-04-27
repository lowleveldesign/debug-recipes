
Troubleshooting MySql queries
=============================

In most cases, you can estimate query performance by counting disk seeks. For small tables, you can usually find a row in one disk seek
(because the index is probably cached). For bigger tables, you can estimate that, using B-tree indexes, you need this many seeks
to find a row: `log(row_count) / log(index_block_length / 3 * 2 / (index_length + data_pointer_length)) + 1`.

In MySQL, an index block is usually 1,024 bytes and the data pointer is usually four bytes. For a 500,000-row table with a key value
length of three bytes (the size of MEDIUMINT), the formula indicates `log(500,000)/log(1024/3*2/(3+4)) + 1 = 4 seeks`.

MySql query caching
-------------------

`table_open_cache` is related to `max_connections`. For example, for 200 concurrent running connections, specify a table cache size of at least 200 * N, where N is the maximum number of tables per join in any of the queries which you execute. You must also reserve some extra file descriptors for temporary tables and files.

If you often have recurring queries for tables that are not updated frequently, enable the query cache:

    [mysqld]
    query_cache_type = 1
    query_cache_size = 10M

Also you may force mysql to cache a query by using `SQL_CACHE`, eg. `SELECT SQL_CACHE id, name FROM customer;`. In the same way you may forbid caching by using `SQL_NO_CACHE`.

Some constraints on caching: <http://dev.mysql.com/doc/refman/5.5/en/query-cache-operation.html>

To check whether server has query caching enabled issue `mysql> SHOW VARIABLES LIKE 'have_query_cache';`. The query cache system variables all have names that begin with `query_cache_`.

To control the maximum size of individual query results that can be cached, set the query_cache_limit system variable. The default value is 1MB.

If the query cache size is greater than 0, the `query_cache_type` variable influences how it works. This variable can be set to the following values:

- A value of 0 or OFF prevents caching or retrieval of cached results.
- A value of 1 or ON enables caching except of those statements that begin with `SELECT SQL_NO_CACHE`.
- A value of 2 or DEMAND causes caching of only those statements that begin with `SELECT SQL_CACHE`.

If a query result is returned from query cache, the server increments the `Qcache_hits` status variable, not `Com_select`. You can determine whether your table cache is too small by checking the mysqld status variable `Opened_tables`, which indicates the number of table-opening operations since the server started.

from <http://www.mysqlperformanceblog.com/2013/10/07/tuning-mysql-5-6-configuration-webinar-followup/>

Q: Query Cache is turned off but we still see commits taking very long time around 50-60 seconds what could be the case?
A: The settings which impact commit performance the most is `innodb_flush_log_at_trx_commit`, `sync_binlog` and `sync_relay_log` (in MySQL 5.6) The impact can depend on a lot of factors including hardware, filesystem and workload. Generally if you want highly durable configuration (setting all these options to 1) you want to ensure to have RAID with write back cache or SSD. If you have slow storage you might need to use less secure settings of 2,0,0 (respectfully) which however may result at some of latest transactions being lost and binary log being inconsistent with database transactional state.

InnoDB options:

- `innodb_buffer_pool_size`
- `innodb_buffer_pool_instances`
- `innodb_old_blocks_pct` - specifies the approximate percentage of the buffer pool that InnoDB uses for the old block sublist. The range of values is 5 to 95. The default value is 37 (that is, 3/8 of the pool).
- `innodb_old_blocks_time` - specifies how long in milliseconds (ms) a block inserted into the old sublist must stay there after its first access before it can be moved to the new sublist. The default value is 0

### Monitoring ###

A cache is cleared if it becomes full or when a table flushing operation occurs. This happens when someone issues a FLUSH TABLES. You can defragment the query cache to better utilize its memory with the `FLUSH QUERY CACHE` statement. The statement does not remove any queries from the cache. The `RESET QUERY CACHE` statement removes all query results from the query cache. The FLUSH TABLES statement also does this.

To monitor query cache performance, use SHOW STATUS to view the cache status variables: `mysql> SHOW STATUS LIKE 'Qcache%';`

MySql Query Plans
-----------------

based on <http://dev.mysql.com/doc/refman/5.5/en/explain-output.html> (explain output columns)

**EXPLAIN** returns a row of information for each table used in the SELECT statement. It lists the tables in the
output in the order that MySQL would read them while processing the statement. MySQL resolves all joins using a nested-loop
join method. This means that MySQL reads a row from the first table, and then finds a matching row in the second table,
the third table, and so on. When all tables are processed, MySQL outputs the selected columns and backtracks through
the table list until a table is found for which there are more matching rows.

**EXPLAIN EXTENDED** adds *filtered* colum which shows the percentage of filtered rows. With **SHOW WARNINGS** may
contain special markers to provide information about query rewriting or optimizer actions, the statement is not
necessarily valid SQL and is not intended to be executed. The output may also include rows with Message values
that provide additional non-SQL explanatory notes about actions taken by the optimizer.

    mysql> EXPLAIN EXTENDED
        -> SELECT t1.a, t1.a IN (SELECT t2.a FROM t2) FROM t1\G

    mysql> SHOW WARNINGS\G

**EXPLAIN PARTITIONS** shows information about partitions that will be queried during execution of a given statement:

    mysql> explain partitions select * From test2 where id = 2;
    +----+-------------+-------+------------+-------+---------------+---------+---------+-------+------+-------+
    | id | select_type | table | partitions | type  | possible_keys | key     | key_len | ref   | rows | Extra |
    +----+-------------+-------+------------+-------+---------------+---------+---------+-------+------+-------+
    |  1 | SIMPLE      | test2 | p3         | const | PRIMARY       | PRIMARY | 4       | const |    1 |       |
    +----+-------------+-------+------------+-------+---------------+---------+---------+-------+------+-------+
    1 row in set (0.00 sec)

### Show query plan for a running connection ###

There is a special syntax `EXPLAIN FOR CONNECTION connid\G`, where connid could be taken from `SHOW processlist`.

### Temporary tables usage ###

After <http://dev.mysql.com/doc/refman/5.5/en/internal-temporary-tables.html>

If an internal temporary table is created initially as an in-memory table but becomes too large, MySQL automatically
converts it to an on-disk table. The maximum size for in-memory temporary tables is the minimum of the `tmp_table_size` and
`max_heap_table_size` values. This differs from MEMORY tables explicitly created with CREATE TABLE: For such tables,
the `max_heap_table_size` system variable determines how large the table is permitted to grow and there is no conversion
to on-disk format.

When the server creates an internal temporary table (either in memory or on disk), it increments the
`Created_tmp_tables` status variable. If the server creates the table on disk (either initially or by converting an in-memory table)
it increments the `Created_tmp_disk_tables` status variable.

MySql query hints
-----------------

Syntax:

    index_hint:
        USE {INDEX|KEY}
          [FOR {JOIN|ORDER BY|GROUP BY}] ([index_list])
      | IGNORE {INDEX|KEY}
          [FOR {JOIN|ORDER BY|GROUP BY}] (index_list)
      | FORCE {INDEX|KEY}
          [FOR {JOIN|ORDER BY|GROUP BY}] (index_list)

Index hint is placed after table name:

    tbl_name [[AS] alias] [index_hint_list]

Index list must be a list of indexes names (the name of a PRIMARY KEY is PRIMARY). To see the index names for a table, use `SHOW INDEX FROM tbl_name`.

You can use `FORCE INDEX`, which acts like `USE INDEX (index_list)` but with the addition that a table scan is assumed to be very expensive. In other words, a table scan is used only if there is no way to use one of the given indexes to find rows in the table. If you specify no FOR clause for an index hint, the hint by default applies to all parts of the statement.

MySql query statistics
----------------------

    ANALYZE [NO_WRITE_TO_BINLOG | LOCAL] TABLE
        tbl_name [, tbl_name] ...

**ANALYZE TABLE** analyzes and stores the key distribution for a table. During the analysis, the table is locked with a read lock for InnoDB and MyISAM. This statement works with InnoDB, NDB, and MyISAM tables. ANALYZE TABLE is supported for partitioned tables, and you can use **ALTER TABLE ... ANALYZE PARTITION** to analyze one or more partitions. By default, the server writes ANALYZE TABLE statements to the binary log so that they replicate to replication slaves. To suppress logging, use the optional NO_WRITE_TO_BINLOG keyword or its alias LOCAL.

`innodb_stats_method` or `myisam_stats_method` server variables

Query profiling
---------------

### Using SHOW PROFILE(S) ###

You can enable profiling for your mysql session by issuing: `set profiling=1` and then query the profiling information using `SHOW PROFILES` and `SHOW PROFILE FOR QUERY`, eg.

    mysql> set profiling=1;
    Query OK, 0 rows affected (0.00 sec)

    mysql> select * from aspnet_error_events limit 0, 1\G;
    ...

    mysql> show profiles;
    +----------+------------+----------------------------------------------+
    | Query_ID | Duration   | Query                                        |
    +----------+------------+----------------------------------------------+
    |        1 | 0.01052625 | select * from aspnet_error_events limit 0, 1 |
    +----------+------------+----------------------------------------------+
    1 row in set (0.00 sec)

    mysql> show profile for query 1;
    +--------------------------------+----------+
    | Status                         | Duration |
    +--------------------------------+----------+
    | starting                       | 0.010001 |
    | Waiting for query cache lock   | 0.000006 |
    | checking query cache for query | 0.000057 |
    | checking permissions           | 0.000010 |
    | Opening tables                 | 0.000023 |
    | System lock                    | 0.000012 |
    | Waiting for query cache lock   | 0.000020 |
    | init                           | 0.000019 |
    | optimizing                     | 0.000006 |
    | statistics                     | 0.000016 |
    | preparing                      | 0.000010 |
    | executing                      | 0.000005 |
    | Sending data                   | 0.000256 |
    | end                            | 0.000006 |
    | query end                      | 0.000005 |
    | closing tables                 | 0.000010 |
    | freeing items                  | 0.000006 |
    | Waiting for query cache lock   | 0.000004 |
    | freeing items                  | 0.000034 |
    | Waiting for query cache lock   | 0.000005 |
    | freeing items                  | 0.000004 |
    | storing result in query cache  | 0.000005 |
    | logging slow query             | 0.000004 |
    | cleaning up                    | 0.000005 |
    +--------------------------------+----------+
    24 rows in set (0.01 sec)

To check the profiling status use `@@profiling` variable:

    mysql> select @@profiling;
    +-------------+
    | @@profiling |
    +-------------+
    |           1 |
    +-------------+
    1 row in set (0.00 sec)

Additionally you may filter profiling information to only specific elements: ALL, BLOCK IO, CONTEXT SWITCHES, CPU, IPC, MEMORY, PAGE FAULTS, SOURCE, SWAPS.

### Using INFORMATION\_SCHEMA.PROFILING table ###

    mysql> show columns from information_schema.profiling;
    +---------------------+--------------+------+-----+----------+-------+
    | Field               | Type         | Null | Key | Default  | Extra |
    +---------------------+--------------+------+-----+----------+-------+
    | QUERY_ID            | int(20)      | NO   |     | 0        |       |
    | SEQ                 | int(20)      | NO   |     | 0        |       |
    | STATE               | varchar(30)  | NO   |     |          |       |
    | DURATION            | decimal(9,6) | NO   |     | 0.000000 |       |
    | CPU_USER            | decimal(9,6) | YES  |     | NULL     |       |
    | CPU_SYSTEM          | decimal(9,6) | YES  |     | NULL     |       |
    | CONTEXT_VOLUNTARY   | int(20)      | YES  |     | NULL     |       |
    | CONTEXT_INVOLUNTARY | int(20)      | YES  |     | NULL     |       |
    | BLOCK_OPS_IN        | int(20)      | YES  |     | NULL     |       |
    | BLOCK_OPS_OUT       | int(20)      | YES  |     | NULL     |       |
    | MESSAGES_SENT       | int(20)      | YES  |     | NULL     |       |
    | MESSAGES_RECEIVED   | int(20)      | YES  |     | NULL     |       |
    | PAGE_FAULTS_MAJOR   | int(20)      | YES  |     | NULL     |       |
    | PAGE_FAULTS_MINOR   | int(20)      | YES  |     | NULL     |       |
    | SWAPS               | int(20)      | YES  |     | NULL     |       |
    | SOURCE_FUNCTION     | varchar(30)  | YES  |     | NULL     |       |
    | SOURCE_FILE         | varchar(20)  | YES  |     | NULL     |       |
    | SOURCE_LINE         | int(20)      | YES  |     | NULL     |       |
    +---------------------+--------------+------+-----+----------+-------+
    18 rows in set (0.00 sec)

The above query might be rewritten to use PROFILING table:

    SELECT STATE, FORMAT(DURATION, 6) AS DURATION
        FROM INFORMATION_SCHEMA.PROFILING
          WHERE QUERY_ID = 1 ORDER BY SEQ;

PERFORMANCE\_SCHEMA
-------------------

By default, the Performance Schema is disabled, and you have to turn it on and enable specific instrumentation points (“consumers”) that you wish to collect.

MySql Server Query Logging
--------------------------

### General and slow query logs ###

MySql can save logs to either a file or a table (`general_log` or `slow_log` tables) although logging to tables imposes higher server overhead.

To start logging you should start a server with `--log-output[=TABLE|FILE|NONE]` option (or set `log_output` variable) and either `--general_log[={0|1}]` or `--slow_query_log[={0|1}]`. The `general_log` variable informs what is the status of logging:

    mysql> show variables like 'general_log';
    +---------------+-------+
    | Variable_name | Value |
    +---------------+-------+
    | general_log   | OFF   |
    +---------------+-------+
    1 row in set (0.00 sec)

And `general_log_file` stores the name of the log file:

    mysql> show variables like 'general_log_file';
    +------------------+-------------------------+
    | Variable_name    | Value                   |
    +------------------+-------------------------+
    | general_log_file | C:\mysql\data\PECET.log |
    +------------------+-------------------------+
    1 row in set (0.00 sec)

Similarly `slow_query_log` variable stores configuration of a slow query logging and `slow_query_log_file` contains a name of the log file:

    mysql> show variables like 'slow_query%';
    +---------------------+------------------------------+
    | Variable_name       | Value                        |
    +---------------------+------------------------------+
    | slow_query_log      | OFF                          |
    | slow_query_log_file | C:\mysql\data\PECET-slow.log |
    +---------------------+------------------------------+
    2 rows in set (0.00 sec)

**Slow query logs** stores queries that took **longer than `long_query_time` seconds** to execute and required at least `min_examined_row_limit` rows to be examined. To include **queries that do not use indexes** for row lookups in the statements written to the slow query log, enable the `log_queries_not_using_indexes` system variable.

    mysql> show variables like 'long%';
    +-----------------+-----------+
    | Variable_name   | Value     |
    +-----------------+-----------+
    | long_query_time | 10.000000 |
    +-----------------+-----------+
    1 row in set (0.00 sec)

To disable or enable general query logging for the current connection, set the session `sql_log_off` variable to `ON` or `OFF`. To see a structure of the log tables you can use:

    mysql> SHOW CREATE TABLE mysql.general_log;
    +-------------+----------------------------------------------------------------------------
    | Table       | Create Table
    +-------------+----------------------------------------------------------------------------
    | general_log | CREATE TABLE `general_log` (
      `event_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      `user_host` mediumtext NOT NULL,
      `thread_id` int(11) NOT NULL,
      `server_id` int(10) unsigned NOT NULL,
      `command_type` varchar(64) NOT NULL,
      `argument` mediumtext NOT NULL
    ) ENGINE=CSV DEFAULT CHARSET=utf8 COMMENT='General log' |
    +-------------+----------------------------------------------------------------------------
    1 row in set (0.03 sec)

    mysql> SHOW CREATE TABLE mysql.slow_log;
    +----------+-------------------------------------------------------------------------------
    | Table    | Create Table
    +----------+-------------------------------------------------------------------------------
    | slow_log | CREATE TABLE `slow_log` (
      `start_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      `user_host` mediumtext NOT NULL,
      `query_time` time NOT NULL,
      `lock_time` time NOT NULL,
      `rows_sent` int(11) NOT NULL,
      `rows_examined` int(11) NOT NULL,
      `db` varchar(512) NOT NULL,
      `last_insert_id` int(11) NOT NULL,
      `insert_id` int(11) NOT NULL,
      `server_id` int(10) unsigned NOT NULL,
      `sql_text` mediumtext NOT NULL
    ) ENGINE=CSV DEFAULT CHARSET=utf8 COMMENT='Slow log' |
    +----------+-------------------------------------------------------------------------------
    1 row in set (0.02 sec)

By default, the log tables use the CSV storage engine that writes data in comma-separated values format. The log tables can be altered to use the MyISAM storage engine. You cannot use ALTER TABLE to alter a log table that is in use. The log must be disabled first. No engines other than CSV or MyISAM are legal for the log tables:

    SET @old_log_state = @@global.general_log;
    SET GLOBAL general_log = 'OFF';
    ALTER TABLE mysql.general_log ENGINE = MyISAM;
    SET GLOBAL general_log = @old_log_state;

`TRUNCATE TABLE` is a valid operation on a log table. It can be used to expire log entries. To create a log rotation you may use `RENAME` statement on the log table:

    USE mysql;
    DROP TABLE IF EXISTS general_log2;
    CREATE TABLE general_log2 LIKE general_log;
    RENAME TABLE general_log TO general_log_backup, general_log2 TO general_log;

##### Usages #####

Enable general log to a MySql table:

    mysql> set global log_output='TABLE';
    Query OK, 0 rows affected (0.00 sec)

    mysql> set global general_log=1;
    Query OK, 0 rows affected (0.02 sec)

    mysql> select * from information_schema.tables;
    ...

    mysql> select * from general_log\G
    *************************** 1. row ***************************
      event_time: 2012-07-26 23:46:02
       user_host: root[root] @ localhost [127.0.0.1]
       thread_id: 1
       server_id: 1
    command_type: Query
        argument: select * from information_schema.tables
    *************************** 2. row ***************************
      event_time: 2012-07-26 23:46:24
       user_host: root[root] @ localhost [127.0.0.1]
       thread_id: 1
       server_id: 1
    command_type: Query
        argument: select * from general_log
    *************************** 3. row ***************************
      event_time: 2012-07-26 23:46:51
       user_host: root[root] @ localhost [127.0.0.1]
       thread_id: 1
       server_id: 1
    command_type: Query
        argument: select * from general_log
    *************************** 4. row ***************************
      event_time: 2012-07-26 23:46:55
       user_host: root[root] @ localhost [127.0.0.1]
       thread_id: 1
       server_id: 1
    command_type: Query
        argument: select * from general_log
    4 rows in set (0.00 sec)

    mysql> set global general_log=0;
    Query OK, 0 rows affected (0.02 sec)

Enable log to a file:

    FIXME

### Binary log ###

Binary log stores information about all operations that change the database content. This may be extremely useful for replication scenarios. To view the content of the binary log use `mysqlbinlog` command.

### Error log ###

To enable error logging you need to start the server with a `--log-error[=file_name]` option. If the `file_name` is not set mysqld uses by default `host_name.err` log file. There is a `log_error` variable which you can set to control logging errors at runtime. Finally `--log-warnings` switch or `log_warnings` variable instructs MySql to log warnings to the error log. The default value is enabled (1). Warning logging can be disabled using a value of 0. If the value is greater than 1, aborted connections are written to the error log, and access-denied errors for new connection attempts are written.

### Flushing Logs ###

To flush logs to the hard drive you can either issue `FLUSH LOGS` statemant or `mysqladmin flush-logs/refresh` command.

Tracing the query optimizer
---------------------------

Starting from version 5.6 there is a special variable `optimizer_trace` which turns on/off traces from the optimizer. Example usage:

    # Turn tracing on (it's off by default):
    SET optimizer_trace="enabled=on";
    SELECT ...; # your query here
    SELECT * FROM INFORMATION_SCHEMA.OPTIMIZER_TRACE;
    # possibly more queries...
    # When done with tracing, disable it:
    SET optimizer_trace="enabled=off";

Links
-----

- [Profiling MySQL queries from Performance Schema](http://www.percona.com/blog/2015/04/16/profiling-mysql-queries-from-performance-schema/)

