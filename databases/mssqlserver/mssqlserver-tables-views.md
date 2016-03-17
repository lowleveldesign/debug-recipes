TABLES
======

Query tables logical information
-----------------------------

Returns a row for each table object, currently only with sys.objects.type = U.

    select * from sys.tables

    select * from sys.tables where name like 'test%'

The `sp_msforeachtable` stored procedure allows you to run a particular query across all tables in a database.

To query just a column name based on table and column id use **COL\_NAME**:

    COL_NAME ( table_id , column_id )

example:

    select *, col_name(object_id, column_id)  From sys.stats_columns stc

Query columns belonging to a particular table (object\_id from **sys.tables**):

    select * from sys.columns c where c.object_id = object_id('users')

**COLUMNPROPERTY** returns information about a column or parameter. Interesting options include:

- AllowsNull
- ColumnId
- FullTextTypeColumn
- IsComputed
- IsFullTextIndexed
- IsIdentity

Example:

    select COLUMNPROPERTY(object_id('Customers'), 'custname', 'AllowsNull')
    0

Metadata operations
-----------------

### Rename a column / table / index ###

Rename a column in a table:

    sp_rename 'AdvertProducts.FinalExpirationDate', 'LastSavedEndTime'

### Text of the definition of an object ###

To get the transact-sql text of the definition of a database object use:

    SELECT object_definition (object_id('sys.tables'));

    ------
    CREATE VIEW sys.tables AS   SELECT o.name, o.object_id, o.principal_id, o.schema_id, o.parent_object_id,    o.type, o.type_desc, o.create_date, o.modify_date,    o.is_ms_shipped, o.is_published, o.is_schema_published,    lob.lobds AS lob_data_space_id,    rfs.indepid AS filestream_data_space_id,    o.property AS max_column_id_used,    o.lock_on_bulk_load, o.uses_ansi_nulls, o.is_replicated, o.has_replication_filter,    o.is_merge_published, o.is_sync_tran_subscribed, o.has_unchecked_assembly_data,    lob.intprop AS text_in_row_limit,    o.large_value_types_out_of_row,    o.is_tracked_by_cdc,    o.lock_escalation_option AS lock_escalation,    ts.name AS lock_escalation_desc   FROM sys.objects$ o   LEFT JOIN sys.sysidxstats lob ON lob.id = o.object_id AND lob.indid <= 1   LEFT JOIN sys.syssingleobjrefs rfs ON rfs.depid = o.object_id AND rfs.class = 42 AND rfs.depsubid = 0 -- SRC_OBJTOFSDS   LEFT JOIN sys.syspalvalues ts ON ts.class = 'LEOP' AND ts.value = o.lock_escalation_option   WHERE o.type = 'U'

or

    sp_helptext 'sys.tables'

    ------------
    CREATE VIEW sys.tables AS
      SELECT o.name, o.object_id, o.principal_id, o.schema_id, o.parent_object_id,
        o.type, o.type_desc, o.create_date, o.modify_date,
        o.is_ms_shipped, o.is_published, o.is_schema_published,
        lob.lobds AS lob_data_space_id,
        rfs.indepid AS filestream_data_space_id,
        o.property AS max_column_id_used,
        o.lock_on_bulk_load, o.uses_ansi_nulls, o.is_replicated, o.has_replication_filter,
        o.is_merge_published, o.is_sync_tran_subscribed, o.has_unchecked_assembly_data,
        lob.intprop AS text_in_row_limit,
        o.large_value_types_out_of_row,
        o.is_tracked_by_cdc,
        o.lock_escalation_option AS lock_escalation,
        ts.name AS lock_escalation_desc
      FROM sys.objects$ o
      LEFT JOIN sys.sysidxstats lob ON lob.id = o.object_id AND lob.indid <= 1
      LEFT JOIN sys.syssingleobjrefs rfs ON rfs.depid = o.object_id AND rfs.class = 42 AND rfs.depsubid = 0	-- SRC_OBJTOFSDS
      LEFT JOIN sys.syspalvalues ts ON ts.class = 'LEOP' AND ts.value = o.lock_escalation_option
      WHERE o.type = 'U'

Query physical tables information
----------------------------------

Every heap and index has a row in **sys.indexes** and each table and index in a SQL Server can be stored on multiple partitions.

Example queries which show the physical structure of a table:

    SELECT  object_id, name, index_id, type_desc
    FROM sys.indexes
    WHERE object_id=object_id('dbo.Logins');

    SELECT * FROM sys.partitions WHERE object_id=object_id('dbo.Logins');

    SELECT object_name(object_id) AS name,
        partition_id, partition_number AS pnum,  rows,
        allocation_unit_id AS au_id, type_desc as page_type_desc,
        total_pages AS pages
    FROM sys.partitions p JOIN sys.allocation_units a
       ON p.partition_id = a.container_id
    WHERE object_id=object_id('dbo.Logins');

#### Size of a table ####

Determine **size of a table** including the size of the indexes (**sp\_spaceused**):

    sp_spaceused '<table_name>'

Example:

    sp_spaceused 'Adverts'

As those size may somtimes be unrelevant it's worth calling **DBCC UPDATEUSAGE** before issuing the stored procedure:

    DBCC UPDATEUSAGE (0)                                 -- current database
    DBCC UPDATEUSAGE ('<database_name>')                 -- named database
    DBCC UPDATEUSAGE ('<database_name>', '<table_name>') -- just one table

#### Query allocation units of a table ####

    SELECT object_name(object_id) AS name,
           partition_id,
           partition_number AS pnum,
           rows,
           allocation_unit_id AS au_id,
           type_desc as page_type_desc,
           total_pages AS pages
    FROM sys.partitions p JOIN sys.allocation_units a
        ON p.partition_id = a.container_id WHERE object_id=object_id('dbo.bigrows');

### Partitions ###

Before you create a new partition you need to define a partition function, eg.

    CREATE PARTITION FUNCTION [TransactionRangePF1] (datetime)
    AS RANGE RIGHT FOR VALUES ('20081001', '20081101', '20081201',
                   '20090101', '20090201', '20090301', '20090401',
                   '20090501', '20090601', '20090701', '20090801');

The partition function is not tied to any particular table. After you define the partition function, you define a partition scheme, which lists a set of filegroups onto which each range of data is placed. Here is the partition schema for my example:

    CREATE PARTITION SCHEME [TransactionsPS1]
    AS PARTITION [TransactionRangePF1]
    TO ([PRIMARY], [PRIMARY], [PRIMARY]
    , [PRIMARY], [PRIMARY], [PRIMARY]
    , [PRIMARY], [PRIMARY], [PRIMARY]
    , [PRIMARY], [PRIMARY], [PRIMARY]);
    GO

or

    CREATE PARTITION SCHEME [TransactionsPS1]
    AS PARTITION [TransactionRangePF1]
    ALL TO ([PRIMARY]);
    GO

Views that contain metadata about partitions are presented on the image below:

Links
-----

- [SQL Server Partitioning without Enterprise Edition](https://www.simple-talk.com/sql/sql-tools/sql-server-partitioning-without-enterprise-edition/)
