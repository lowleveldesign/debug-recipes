
MySql Query Profiling
=====================

Query profiling information
---------------------------

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

