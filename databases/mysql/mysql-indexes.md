
MySql Indexes and constraints
=============================

Query information
-----------------

### Indexes (SHOW INDEX [FROM tbl_name]) ###

Syntax:

    SHOW {INDEX | INDEXES | KEYS}
        {FROM | IN} tbl_name
        [{FROM | IN} db_name]
        [WHERE expr]

Example:

    mysql> show index from tproducts;
    +-----------+------------+----------+--------------+-------------+-----------+-------------+----------+--------+------+------------+---------+---------------+
    | Table     | Non_unique | Key_name | Seq_in_index | Column_name | Collation | Cardinality | Sub_part | Packed | Null | Index_type | Comment | Index_comment |
    +-----------+------------+----------+--------------+-------------+-----------+-------------+----------+--------+------+------------+---------+---------------+
    | tproducts |          0 | PRIMARY  |            1 | pID         | A         |           4 |     NULL | NULL   |      | BTREE      |         |               |
    +-----------+------------+----------+--------------+-------------+-----------+-------------+----------+--------+------+------------+---------+---------------+
    1 row in set (0.00 sec)

The SHOW INDEX statement displays a cardinality value based on N/S, where N is the number of rows in the table and S is the average value group size.
That ratio yields an approximate number of value groups in the table.

### Constraints ###

Constraints defined on a table can be view also by using `SHOW CREATE TABLE tablname` statement, eg.:

    mysql> show create table test2\G;
    *************************** 1. row ***************************
           Table: test2
    Create Table: CREATE TABLE `test2` (
      `id` int(11) NOT NULL,
      `test` int(11) DEFAULT NULL,
      PRIMARY KEY (`id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=latin1
    /*!50100 PARTITION BY KEY (id)
    PARTITIONS 4 */
    1 row in set (0.00 sec)

**INFORMATION\_SCHEMA.TABLE\_CONSTRAINTS** contains information about all constraints defined on a given table (and thus indexes):

    mysql> select * from information_schema.table_constraints;
    +--------------------+-------------------+-----------------+---------------+-------------------------------+-----------------+
    | CONSTRAINT_CATALOG | CONSTRAINT_SCHEMA | CONSTRAINT_NAME | TABLE_SCHEMA  | TABLE_NAME                    | CONSTRAINT_TYPE |
    +--------------------+-------------------+-----------------+---------------+-------------------------------+-----------------+
    | def                | diagnosticsdb     | PRIMARY         | diagnosticsdb | aspnet_applicationlife_events | PRIMARY KEY     |
    | def                | diagnosticsdb     | PRIMARY         | diagnosticsdb | aspnet_error_events           | PRIMARY KEY     |
    | def                | diagnosticsdb     | PRIMARY         | diagnosticsdb | aspnet_heartbeat_events       | PRIMARY KEY     |
    | def                | diagnosticsdb     | PRIMARY         | diagnosticsdb | aspnet_other_events           | PRIMARY KEY     |
    | def                | diagnosticsdb     | PRIMARY         | diagnosticsdb | aspnet_webevent_events        | PRIMARY KEY     |
    | def                | diagnosticsdb     | PRIMARY         | diagnosticsdb | deployed_applications         | PRIMARY KEY     |
    | def                | diagnosticsdb     | PRIMARY         | diagnosticsdb | test2                         | PRIMARY KEY     |
    | def                | diagnosticsdb     | PRIMARY         | diagnosticsdb | tproducts                     | PRIMARY KEY     |
    | def                | mysql             | PRIMARY         | mysql         | time_zone_transition          | PRIMARY KEY     |
    | def                | mysql             | PRIMARY         | mysql         | time_zone_transition_type     | PRIMARY KEY     |
    | def                | mysql             | PRIMARY         | mysql         | user                          | PRIMARY KEY     |
    +--------------------+-------------------+-----------------+---------------+-------------------------------+-----------------+
    33 rows in set (0.40 sec)

**INFORMATION\_SCHEMA.KEY\_COLUMN\_USAGE** describes which key columns have constraints. For instance to get a list of columns that
belong to a given constraint one may issue:

    mysql> select * from information_schema.key_column_usage as u where table_schema = 'diagnosticsdb' and table_name = 'test2' and constraint_name = 'PRIMARY';
    +--------------------+-------------------+-----------------+---------------+---------------+------------+-------------+------------------+-------------------------------+-------------------------+-----------------------+------------------------+
    | CONSTRAINT_CATALOG | CONSTRAINT_SCHEMA | CONSTRAINT_NAME | TABLE_CATALOG | TABLE_SCHEMA  | TABLE_NAME | COLUMN_NAME | ORDINAL_POSITION | POSITION_IN_UNIQUE_CONSTRAINT | REFERENCED_TABLE_SCHEMA | REFERENCED_TABLE_NAME | REFERENCED_COLUMN_NAME |
    +--------------------+-------------------+-----------------+---------------+---------------+------------+-------------+------------------+-------------------------------+-------------------------+-----------------------+------------------------+
    | def                | diagnosticsdb     | PRIMARY         | def           | diagnosticsdb | test2      | id          |                1 |                          NULL | NULL                    | NULL                  | NULL                   |
    +--------------------+-------------------+-----------------+---------------+---------------+------------+-------------+------------------+-------------------------------+-------------------------+-----------------------+------------------------+
    1 row in set (0.00 sec)

