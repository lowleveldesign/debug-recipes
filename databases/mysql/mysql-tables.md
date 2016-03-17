
Tables
------

**SHOW TABLES \[LIKE tblname\]** displays all tables in a current database. **SHOW CREATE TABLE tblname** displays script that will create a given table.

### INFORMATION\_SCHEMA.TABLES ###

    mysql> select * From information_schema.tables where table_name like 'test'\G;
    *************************** 1. row ***************************
      TABLE_CATALOG: def
       TABLE_SCHEMA: diagnosticsdb
         TABLE_NAME: test
         TABLE_TYPE: BASE TABLE
             ENGINE: InnoDB
            VERSION: 10
         ROW_FORMAT: Compact
         TABLE_ROWS: 806
     AVG_ROW_LENGTH: 101
        DATA_LENGTH: 81920
    MAX_DATA_LENGTH: 0
       INDEX_LENGTH: 0
          DATA_FREE: 13631488
     AUTO_INCREMENT: NULL
        CREATE_TIME: 2012-07-13 23:47:49
        UPDATE_TIME: NULL
         CHECK_TIME: NULL
    TABLE_COLLATION: latin1_swedish_ci
           CHECKSUM: NULL
     CREATE_OPTIONS:
      TABLE_COMMENT:
    1 row in set (0.02 sec)

    ERROR:
    No query specified

### SHOW TABLE STATUS [LIKE tblname] ###

The same display as above can be achieved using:

    mysql> show table status like 'test'\G;

Columns
-------

### INFORMATION\_SCHEMA.COLUMNS ###

    mysql> select * from information_schema.columns where table_schema like 'diagnosticsdb' and table_name like 'test';
    +---------------+---------------+------------+-------------+------------------+----------------+-------------+-----------+--------------------------+------------------------+-------------------+---------------+--------------------+----------------+---------------------+------------+-------+---------------------------------+----------------+
    | TABLE_CATALOG | TABLE_SCHEMA  | TABLE_NAME | COLUMN_NAME | ORDINAL_POSITION | COLUMN_DEFAULT | IS_NULLABLE | DATA_TYPE | CHARACTER_MAXIMUM_LENGTH | CHARACTER_OCTET_LENGTH | NUMERIC_PRECISION | NUMERIC_SCALE | CHARACTER_SET_NAME | COLLATION_NAME | COLUMN_TYPE         | COLUMN_KEY | EXTRA | PRIVILEGES                      | COLUMN_COMMENT |
    +---------------+---------------+------------+-------------+------------------+----------------+-------------+-----------+--------------------------+------------------------+-------------------+---------------+--------------------+----------------+---------------------+------------+-------+---------------------------------+----------------+
    | def           | diagnosticsdb | test       | a           |                1 | 0              | YES         | tinyint   |                     NULL |                   NULL |                 3 |             0 | NULL               | NULL           | tinyint(3) unsigned |            |       | select,insert,update,references |                |
    | def           | diagnosticsdb | test       | b           |                2 | 0              | YES         | tinyint   |                     NULL |                   NULL |                 3 |             0 | NULL               | NULL           | tinyint(3) unsigned |            |       | select,insert,update,references |                |
    | def           | diagnosticsdb | test       | c           |                3 | 0              | YES         | tinyint   |                     NULL |                   NULL |                 3 |             0 | NULL               | NULL           | tinyint(3) unsigned |            |       | select,insert,update,references |                |
    | def           | diagnosticsdb | test       | d           |                4 | 0              | YES         | tinyint   |                     NULL |                   NULL |                 3 |             0 | NULL               | NULL           | tinyint(3) unsigned |            |       | select,insert,update,references |                |
    | def           | diagnosticsdb | test       | e           |                5 | 0              | YES         | tinyint   |                     NULL |                   NULL |                 3 |             0 | NULL               | NULL           | tinyint(3) unsigned |            |       | select,insert,update,references |                |
    +---------------+---------------+------------+-------------+------------------+----------------+-------------+-----------+--------------------------+------------------------+-------------------+---------------+--------------------+----------------+---------------------+------------+-------+---------------------------------+----------------+
    5 rows in set (0.03 sec)


### SHOW COLUMNS statement ###

Show information about columns in a table:

    mysql> show columns from aspnet_error_events;
    +------------------------+---------------+------+-----+---------+-------+
    | Field                  | Type          | Null | Key | Default | Extra |
    +------------------------+---------------+------+-----+---------+-------+
    | EventId                | char(32)      | NO   | PRI | NULL    |       |
    | EventTimeUtc           | datetime      | NO   | PRI | NULL    |       |
    | EventTime              | datetime      | NO   |     | NULL    |       |
    | EventType              | varchar(256)  | NO   |     | NULL    |       |
    | EventSequence          | bigint(20)    | NO   |     | NULL    |       |
    | EventOccurrence        | bigint(20)    | NO   |     | NULL    |       |
    | EventCode              | int(11)       | NO   |     | NULL    |       |
    | EventDetailCode        | int(11)       | NO   |     | NULL    |       |
    | Message                | varchar(1024) | YES  |     | NULL    |       |
    | ApplicationPath        | varchar(256)  | YES  |     | NULL    |       |
    | ApplicationPathHash    | binary(16)    | YES  |     | NULL    |       |
    | ApplicationVirtualPath | varchar(256)  | YES  |     | NULL    |       |
    | MachineName            | varchar(256)  | NO   |     | NULL    |       |
    | RequestUrl             | varchar(1024) | YES  |     | NULL    |       |
    | ExceptionType          | varchar(256)  | YES  |     | NULL    |       |
    | Details                | text          | YES  |     | NULL    |       |
    +------------------------+---------------+------+-----+---------+-------+
    16 rows in set (0.01 sec)

### Optimize column types ###

You may ask MySql to provide type definitions that will best fit your column values by using `PROCEDURE ANALYSE`:

    SELECT ... FROM ... WHERE ... PROCEDURE ANALYSE([max_elements,[max_memory]])
    
For example:

    mysql> select * from test2 procedure analyse();
    +--------------------------+-----------+-----------+------------+------------+------------------+-------+-------------------------+--------+----------------------------+
    | Field_name               | Min_value | Max_value | Min_length | Max_length | Empties_or_zeros | Nulls | Avg_value_or_avg_length | Std    | Optimal_fieldtype          |
    +--------------------------+-----------+-----------+------------+------------+------------------+-------+-------------------------+--------+----------------------------+
    | diagnosticsdb.test2.id   | 1         | 3         |          1 |          1 |                0 |     0 | 2.0000                  | 0.8165 | ENUM('1','2','3') NOT NULL |
    | diagnosticsdb.test2.test | 1         | 3         |          1 |          1 |                0 |     0 | 2.0000                  | 0.8165 | ENUM('1','2','3') NOT NULL |
    +--------------------------+-----------+-----------+------------+------------+------------------+-------+-------------------------+--------+----------------------------+
    2 rows in set (0.01 sec)