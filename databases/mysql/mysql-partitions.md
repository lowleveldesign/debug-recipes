
Partitions
----------

### Querying information about the partitions ###

**show table create** displays create statement for a table:

    mysql> show create table test;
    +-------+--------------------------------------------------------------------
    | Table | Create Table
    +-------+--------------------------------------------------------------------
    | test  | CREATE TABLE `test` (
      `EventId` int(11) NOT NULL,
      `EventTimeUtc` datetime NOT NULL,
      PRIMARY KEY (`EventId`,`EventTimeUtc`)
    ) ENGINE=InnoDB DEFAULT CHARSET=latin1
    /*!50500 PARTITION BY RANGE  COLUMNS(EventTimeUtc)
    (PARTITION p1307 VALUES LESS THAN ('2012-07-13 23:59') ENGINE = InnoDB,
     PARTITION p1407 VALUES LESS THAN ('2012-07-14 23:59') ENGINE = InnoDB,
     PARTITION p1507 VALUES LESS THAN ('2012-07-15 23:59') ENGINE = InnoDB,
     PARTITION pMax VALUES LESS THAN (MAXVALUE) ENGINE = InnoDB) */ |
    +-------+--------------------------------------------------------------------
    1 row in set (0.00 sec)

**show table status** informs whether a table is partitioned (in the *create_options* column):

    mysql> show table status like 'test'\G
    *************************** 1. row ***************************
               Name: test
             Engine: InnoDB
            Version: 10
         Row_format: Compact
               Rows: 4
     Avg_row_length: 16384
        Data_length: 65536
    Max_data_length: 0
       Index_length: 0
          Data_free: 54525952
     Auto_increment: NULL
        Create_time: NULL
        Update_time: NULL
         Check_time: NULL
          Collation: latin1_swedish_ci
           Checksum: NULL
     Create_options: partitioned
            Comment:
    1 row in set (0.00 sec)


**select * from information_schema.partitions** displays information about partitions in mysql databases:

    mysql> select * from information_schema.partitions where table_rows > 0 and table_name like 'test';
    +---------------+---------------+------------+----------------+-------------------+----------------------------+-------------------------------+------------------+---------------------+-------------------------+-------------------------+-----------------------+------------+----------------+-------------+-----------------+--------------+-----------+-------------+-------------+------------+----------+-------------------+-----------+-----------------+
    | TABLE_CATALOG | TABLE_SCHEMA  | TABLE_NAME | PARTITION_NAME | SUBPARTITION_NAME | PARTITION_ORDINAL_POSITION | SUBPARTITION_ORDINAL_POSITION | PARTITION_METHOD | SUBPARTITION_METHOD | PARTITION_EXPRESSION    | SUBPARTITION_EXPRESSION | PARTITION_DESCRIPTION | TABLE_ROWS | AVG_ROW_LENGTH | DATA_LENGTH | MAX_DATA_LENGTH | INDEX_LENGTH | DATA_FREE | CREATE_TIME | UPDATE_TIME | CHECK_TIME | CHECKSUM | PARTITION_COMMENT | NODEGROUP | TABLESPACE_NAME |
    +---------------+---------------+------------+----------------+-------------------+----------------------------+-------------------------------+------------------+---------------------+-------------------------+-------------------------+-----------------------+------------+----------------+-------------+-----------------+--------------+-----------+-------------+-------------+------------+----------+-------------------+-----------+-----------------+
    | def           | diagnosticsdb | test       | p32            | NULL              |                         33 |                          NULL | HASH             | NULL                | dayofyear(EventTimeUtc) | NULL                    | NULL                  |          2 |           8192 |       16384 |            NULL |            0 |         0 | NULL        | NULL        | NULL       |     NULL |                   | default   | NULL            |
    | def           | diagnosticsdb | test       | p33            | NULL              |                         34 |                          NULL | HASH             | NULL                | dayofyear(EventTimeUtc) | NULL                    | NULL                  |          1 |          16384 |       16384 |            NULL |            0 |         0 | NULL        | NULL        | NULL       |     NULL |                   | default   | NULL            |
    +---------------+---------------+------------+----------------+-------------------+----------------------------+-------------------------------+------------------+---------------------+-------------------------+-------------------------+-----------------------+------------+----------------+-------------+-----------------+--------------+-----------+-------------+-------------+------------+----------+-------------------+-----------+-----------------+
    2 rows in set (0.07 sec)
    
    mysql> select partition_name, table_rows from information_schema.partitions where table_name like 'aspnet_heartbeat_events';
    +----------------+------------+
    | partition_name | table_rows |
    +----------------+------------+
    | p1307          |          1 |
    | p1407          |          2 |
    | p1507          |          0 |
    | pMax           |          0 |
    +----------------+------------+
    4 rows in set (0.02 sec)

To show which partitions are being used in a particular query use **explain partitions <query>** statement:

    mysql> create table test2 (
        -> id int not null,
        -> test int,
        -> constraint primary key (id))
        -> partition by key(id)
        -> partitions 4;
    Query OK, 0 rows affected (0.20 sec)

    mysql> insert into test2 values(1,1);
    Query OK, 1 row affected (0.04 sec)

    mysql> insert into test2 values(2,2);
    Query OK, 1 row affected (0.03 sec)

    mysql> insert into test2 values(3,3);
    Query OK, 1 row affected (0.03 sec)

    mysql> explain partitions select * From test2 where id = 2;
    +----+-------------+-------+------------+-------+---------------+---------+---------+-------+------+-------+
    | id | select_type | table | partitions | type  | possible_keys | key     | key_len | ref   | rows | Extra |
    +----+-------------+-------+------------+-------+---------------+---------+---------+-------+------+-------+
    |  1 | SIMPLE      | test2 | p3         | const | PRIMARY       | PRIMARY | 4       | const |    1 |       |
    +----+-------------+-------+------------+-------+---------------+---------+---------+-------+------+-------+
    1 row in set (0.00 sec)

### Maintening partitions ###

**Rebuilding partition** (drop and insert):

    ALTER TABLE t1 REBUILD PARTITION p0, p1;

**Analyzing partitions**:  this reads and stores the key distributions for partitions

    ALTER TABLE t1 ANALYZE PARTITION p3;

**Repairing partitions**: this repairs corrupted partitions.

    ALTER TABLE t1 REPAIR PARTITION p0,p1;

**Checking partitions**: you can check partitions for errors in much the same way that you can use CHECK TABLE with nonpartitioned tables:

    ALTER TABLE trb3 CHECK PARTITION p1;

You can **add a new partition to a table**:

    ALTER TABLE trb3 ADD PARTITION (PARTITION p3 VALUES LESS THAN (2000));

**drop**:

    ALTER TABLE trb3 DROP PARTITION p3

or reorganize them:

    ALTER TABLE members REORGANIZE PARTITION p0 INTO (
        PARTITION s0 VALUES LESS THAN (1960),
        PARTITION s1 VALUES LESS THAN (1970)
    );
    
To **remove completely partitioning for a table** use `REMOVE PARTITIONING` command:

    ALTER TABLE trb3 REMOVE PATITIONING

Beginning with MySQL 5.5.0, it is possible to delete all rows from one or more selected partitions using `ALTER TABLE ... TRUNCATE PARTITION`.
