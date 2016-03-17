
MySql transaction and locking
=============================

### Check running processes ###

    select * from information_schema.processlist

### Check used and open tables ###

    > show open tables;

    Database	Table	In_use	Name_locked
    kropka_stats	daily_stats_others	0	0
    kropka_stats	services	0	0
    kropka_stats	log_entries	0	0
    kropka_stats	daily_stats_rejected	0	0
    kropka_stats	event_types	0	0
    kropka_stats	stats_tables_maintenance	0	0

### Check INNODB monitor structures ###

    show engine innodb status;

    select * from information_schema.INNODB_LOCKS;
    select * from information_schema.INNODB_TRX;

### List running transactions on a server (INFORMATION\_SCHEMA.INNODB_TRX) ###

List all the transactions that are using InnoDB engine:

    mysql> select * from information_schema.innodb_trx\G;
    *************************** 1. row ***************************
                        trx_id: 1B06
                     trx_state: RUNNING
                   trx_started: 2012-10-15 11:47:36
         trx_requested_lock_id: NULL
              trx_wait_started: NULL
                    trx_weight: 2
           trx_mysql_thread_id: 2
                     trx_query: NULL
           trx_operation_state: NULL
             trx_tables_in_use: 0
             trx_tables_locked: 0
              trx_lock_structs: 1
         trx_lock_memory_bytes: 376
               trx_rows_locked: 0
             trx_rows_modified: 1
       trx_concurrency_tickets: 0
           trx_isolation_level: REPEATABLE READ
             trx_unique_checks: 1
        trx_foreign_key_checks: 1
    trx_last_foreign_key_error: NULL
     trx_adaptive_hash_latched: 0
     trx_adaptive_hash_timeout: 10000
    1 row in set (0.00 sec)


### Server table locking ###

By default MySql locks the whole table for write/update operations. This does not apply to InnoDB engine which keeps locks at the row level. To see tables that are locked on a server level use **show open tables** command, eg.

    mysql> show open tables like 't1';
    +---------------+-------+--------+-------------+
    | Database      | Table | In_use | Name_locked |
    +---------------+-------+--------+-------------+
    | diagnosticsdb | t1    |      0 |           0 |
    +---------------+-------+--------+-------------+
    1 row in set (0.00 sec)

http://stackoverflow.com/questions/3230693/get-locked-tables-in-mysql-query

The default MySQL setting `AUTOCOMMIT=1` can impose performance limitations on a busy database server. Where practical, wrap
several related DML operations into a single transaction, by issuing `SET AUTOCOMMIT=0` or a `START TRANSACTION` statement,
followed by a `COMMIT` statement after making all the changes.
