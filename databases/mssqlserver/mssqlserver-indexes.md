
Indexes in SQL Server
===================

Constraints are based on indexes that's why they will also be added in this section.

Indexes
------

An index in SQL Server is a B-Tree:

- **FILLFACTOR** applies to the bottom layer. This is the leaf node/data layer in the picture below.
- **PAD\_INDEX** ON means "Apply FILLFACTOR to all layers". This is the root node and intermediate level in the picture below

This means that **PAD\_INDEX** is only useful if **FILLFACTOR** is set. **FILLFACTOR** determines how much free space in an data page (roughly).

### Query table index information ###

Query indexes belonging to a particular table:

    select * from sys.indexes i
      inner join sys.tables t on t.object_id = i.object_id and t.name = 'users'

Query columns belonging to a particular index (by name):

    select i.name as indname, t.name as tblname, c.name as colname, ic.key_ordinal, ic.partition_ordinal, ic.is_descending_key, ic.is_included_column from sys.index_columns ic
        join sys.columns c on ic.column_id = c.column_id and c.object_id = ic.object_id
        join sys.tables t on t.object_id = c.object_id
        join sys.indexes i on i.index_id = ic.index_id and ic.object_id = i.object_id
        where i.name = 'IX_Adverts_ModificationTime_InvestmentId'

Query columns belonging to a particular index (`index_id`) and table (`object_id`):

    select * from sys.index_columns where index_id = 1 and object_id = 1668874495

You can get information about index  using **sp\_helpindex** procedure:

    sp_helpindex [ @objname = ] 'name'

    sp_helpindex users

### Query index properties ###

There is a special `INDEXPROPERTY( object_ID , index_or_statistics_name , property )` function that returns properties of an index. Following queries return different properties of a sample `IX_FOR_PIVOT` index:

    declare @idxname varchar(100);
    declare @tblid int;
    set @idxname = 'IX_FOR_PIVOT';
    set @tblid = object_id('CounterMonthly');
    select object_name(@tblid) as [Table], @idxname as IndexName,
           indexproperty(@tblid, @idxname, 'IndexID') as IndexID,
           indexproperty(@tblid, @idxname, 'IndexDepth') as IndexDepth,
           indexproperty(@tblid, @idxname, 'IndexFillFactor') as IndexFillFactor,
           indexproperty(@tblid, @idxname, 'IsDisabled') as IsDisabled,
           indexproperty(@tblid, @idxname, 'IsUnique') as IsUnique,
           indexproperty(@tblid, @idxname, 'IsClustered') as IsClustered,
           indexproperty(@tblid, @idxname, 'IsAutoStatistics') as IsAutoStatistics,
           indexproperty(@tblid, @idxname, 'IsFulltextKey') as IsFulltextKey,
           indexproperty(@tblid, @idxname, 'IsPageLockDisallowed') as IsPageLockDisallowed,
           indexproperty(@tblid, @idxname, 'IsRowLockDisallowed') as IsRowLockDisallowed,
           /* index_or_statistics_name is statistics created by the
              CREATE STATISTICS statement or by the AUTO_CREATE_STATISTICS
              option of ALTER DATABASE. */
           indexproperty(@tblid, @idxname, 'IsStatistics') as IsStatistics;

### Query index usage statistics (find unused indexes) ###

The view `sys.dm_db_index_usage_stats` provides index usage statistics.

The counters are initialized to empty whenever the SQL Server (MSSQLSERVER) service is started. In addition, whenever a database is detached or is shut down (for example, because AUTO_CLOSE is set to ON), all rows associated with the database are removed.

The below query finds indexes that are used rather for maintenace than for querying:

    with   calced
    as     (select [object_id],
                   index_id,
                   user_seeks + user_scans + user_lookups as reads,
                   user_updates as writes,
                   convert (decimal (10, 2), user_updates * 100.0 / (user_seeks + user_scans + user_lookups + user_updates)) as perc
            from   sys.dm_db_index_usage_stats
            where  database_id = DB_ID())
    select case
    when reads = 0 and writes = 0 then 'Consider dropping : not used at all'
    when reads = 0 and writes > 0 then 'Consider dropping : only writes'
    when writes > reads then 'Consider dropping : more writes (' + RTRIM(perc) + '% of activity)'
    when reads = writes then 'Reads and writes equal'
    end as [status],
           c.[object_id] as [table],
           i.Name as [index],
           c.reads,
           c.writes
    from   calced as c
           inner join
           sys.indexes as i
           on c.[object_id] = i.[object_id]
              and c.index_id = i.index_id
    where  c.writes >= c.reads;

We can also use plan cache content in order to find those indexes:

-- finding indexes to remove based on the cached plan information

    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    GO
    DECLARE @IndexName sysname = 'PK_SalesOrderHeader_SalesOrderID';
    SET @IndexName = QUOTENAME(@IndexName,'[');
    WITH XMLNAMESPACES (DEFAULT
    'http://schemas.microsoft.com/sqlserver/2004/07/showplan')
    ,IndexSearch
    AS (
      SELECT qp.query_plan
        ,cp.usecounts
        ,ix.query('.')AS StmtSimple
      FROM sys.dm_exec_cached_plans cp
        OUTER APPLY sys.dm_exec_query_plan(cp.plan_handle) qp
        CROSS APPLY qp.query_plan.nodes('//StmtSimple') AS p(ix)
    WHERE query_plan.exist('//Object[@Index = sql:variable("@IndexName")]') =1)
    SELECT StmtSimple.value('StmtSimple[1]/@StatementText', 'VARCHAR(4000)') AS
    sql_text
      ,obj.value('@Database','sysname') AS database_name
      ,obj.value('@Schema','sysname') AS schema_name
      ,obj.value('@Table','sysname') AS table_name
      ,obj.value('@Index','sysname') AS index_name
      ,ixs.query_plan
    FROM IndexSearch ixs
      CROSS APPLY StmtSimple.nodes('//Object') AS o(obj)
    WHERE obj.exist('//Object[@Index = sql:variable("@IndexName")]') = 1;

### Find missing indexes ###

The `sys.dm_db_missing_index_*` views provide information about missing indexes. Missing indexes might be grouped into missing indexes groups.

    select   'CREATE INDEX [<<index name>>] ON ' + [table] + ' (' + coalesce (eq + coalesce (', ' + iq, ''), iq) +
            ')' + coalesce (' INCLUDE(' + ic + ');', ';') as [statement]
    from     (select object_name(d.[object_id]) as [table],
                     d.equality_columns as eq,
                     d.inequality_columns as iq,
                     d.included_columns as ic,
                     (s.user_seeks + s.user_scans) * (s.avg_total_user_cost * s.avg_user_impact) as relative_benefit,
                     s.user_seeks,
                     s.user_scans,
                     s.last_user_seek,
                     s.last_user_scan
              from   sys.dm_db_missing_index_details as d
                     inner join sys.dm_db_missing_index_groups as g
                        on d.index_handle = g.index_handle
                     inner join sys.dm_db_missing_index_group_stats as s
                        on g.index_group_handle = s.group_handle
              where  d.database_id = DB_ID()
              ) as x
    -- CROSS JOIN AB_Utility.dbo.AB_Uptime()
    order by relative_benefit desc;

We can also query plan cache tables for missing index information (although it's much more expensive):

    -- find missing indexes based on query plans information
    WITH XMLNAMESPACES (DEFAULT
    'http://schemas.microsoft.com/sqlserver/2004/07/showplan')
    ,PlanMissingIndexes
    AS (
      SELECT query_plan, cp.usecounts
      FROM sys.dm_exec_cached_plans cp
        OUTER APPLY sys.dm_exec_query_plan(cp.plan_handle) tp
      WHERE tp.query_plan.exist('//MissingIndex')=1
    )
    SELECT
      stmt.value('(//MissingIndex/@Database)[1]', 'sysname') AS database_name
      ,stmt.value('(//MissingIndex/@Schema)[1]', 'sysname') AS [schema_name]
      ,stmt.value('(//MissingIndex/@Table)[1]', 'sysname') AS [table_name]
      ,stmt.value('(@StatementText)[1]', 'VARCHAR(4000)') AS sql_text
      ,pmi.usecounts
      ,stmt.value('(//MissingIndexGroup/@Impact)[1]', 'FLOAT') AS impact
      ,stmt.query('for $group in //ColumnGroup
      for $column in $group/Column
      where $group/@Usage="EQUALITY"
      return string($column/@Name)
      ').value('.', 'varchar(max)') AS equality_columns
      ,stmt.query('for $group in //ColumnGroup
      for $column in $group/Column
      where $group/@Usage="INEQUALITY"
      return string($column/@Name)
      ').value('.', 'varchar(max)') AS inequality_columns
      ,stmt.query('for $group in //ColumnGroup
      for $column in $group/Column
      where $group/@Usage="INCLUDE"
      return string($column/@Name)
      ').value('.', 'varchar(max)') AS include_columns
      ,pmi.query_plan
    FROM PlanMissingIndexes pmi
      CROSS APPLY pmi.query_plan.nodes('//StmtSimple') AS p(stmt)
    ORDER BY stmt.value('(//MissingIndexGroup/@Impact)[1]', 'FLOAT') DESC

### Find duplicate indexes ###

The query below finds duplicate indices (after <http://blogs.lessthandot.com/index.php/DataMgmt/DataDesign/finding-exact-duplicate-indexes>):

    With IndexColumns As
    (
        select  I.object_id,
                I.index_id,
                SubString(
                    (
                        select  ',' + Convert(VarChar(10), Column_id)
                        from    sys.index_columns as k
                        where   k.object_id = i.object_id
                                and k.index_id = i.index_id
                                and is_included_column = 0
                        Order By key_ordinal
                        for xml path('')
                    ), 2, 1000) As KeyColumns,
                SubString(Coalesce(
                    (
                        select  ',' + Convert(VarChar(10), Column_id)
                        from    sys.index_columns as k
                        where   k.object_id = i.object_id
                                and k.index_id = i.index_id
                                and is_included_column = 1
                        Order By column_id
                        for xml path('')
                    ), ''), 2, 1000) As IncludeColumns
        From    sys.indexes As I
                Inner Join sys.Tables As T
                    On I.object_id = T.object_id
        Where   I.type_desc <> 'Clustered'
                And T.is_ms_shipped = 0
    )
    Select  Object_Name(AIndex.object_id) As TableName,
            AIndex.name As Index1,
            bIndex.Name As Index2,
            'Drop Index [' + bIndex.Name + '] On [' + Object_Name(AIndex.object_id) + ']' As DropCode
    From    IndexColumns As A
            Inner Join IndexColumns  As B
                On A.object_id = B.object_id
                And A.index_id < B.index_id
                And A.KeyColumns = B.KeyColumns
                And A.IncludeColumns = B.IncludeColumns
            Inner Join sys.indexes As AIndex
                On A.object_id = AIndex.object_id
                And A.index_id = AIndex.index_id
            Inner Join sys.indexes As BIndex
                On B.object_id = BIndex.object_id
                And B.index_id = BIndex.index_id

### Retrieve index scans from cached query plans ###

    -- find index scans
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    GO
    DECLARE @IndexName sysname;
    DECLARE @op sysname;
    SET @IndexName = 'IX_SalesOrderHeader_SalesPersonID';
    SET @op = 'Index Scan';
    WITH XMLNAMESPACES(DEFAULT
    N'http://schemas.microsoft.com/sqlserver/2004/07/showplan')
    SELECT
         cp.plan_handle
         ,DB_NAME(dbid) + '.' + OBJECT_SCHEMA_NAME(objectid, dbid) + '.'
    + OBJECT_NAME(objectid, dbid) AS database_object
      ,qp.query_plan
      ,c1.value('@PhysicalOp','nvarchar(50)') as physical_operator
      ,c2.value('@Index','nvarchar(max)') AS index_name
    FROM sys.dm_exec_cached_plans cp
      CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) qp
      CROSS APPLY query_plan.nodes('//RelOp') r(c1)
      OUTER APPLY c1.nodes('IndexScan/Object') as o(c2)
    WHERE c2.value('@Index','nvarchar(max)') = QUOTENAME(@IndexName,'[')
    AND c1.exist('@PhysicalOp[. = sql:variable("@op")]') = 1;


### Disable index ###

    alter index Uzytkownik_Uzytkownicy on users disable

### Drop index ###

Be careful - dropping index blocks any table modification queries (inserts and updates) and waits for all selects to finish.

    drop index testindex on testtbl

### Query the number of rows over time ###

To monitor the change in the number of rows for a table over time, use any of the following catalog or Dynamic Management Views:

    SELECT  OBJECT_NAME([p].[object_id]) AS [Table] ,
            [p].[index_id] AS [Index ID] ,
            [i].[name] AS [Index] ,
            [p].[rows] AS "Number of Rows"
    FROM    [sys].[partitions] AS [p]
            JOIN [sys].[indexes] AS [i] ON [p].[object_id] = [i].[object_id]
                                      AND [p].[index_id] = [i].[index_id]
    WHERE   [p].[object_id] = OBJECT_ID(N'Sales.SalesOrderDetail');

    SELECT  OBJECT_NAME([ips].[object_id]) AS [Table] ,
            [ips].[index_id] AS [Index ID] ,
            [i].[name] AS [Index] ,
            [ips].[record_count] AS [NumberOfRows]
    FROM    [sys].[dm_db_index_physical_stats](DB_ID(N'AdventureWorks2012'),
                                         OBJECT_ID(N'Sales.SalesOrderDetail'),
                                           NULL, NULL, 'DETAILED') AS [ips]
            JOIN [sys].[indexes] AS [i] ON [ips].[object_id] = [i].[object_id]
                                      AND [ips].[index_id] = [i].[index_id]
    WHERE   [ips].[index_level] = 0;


Constraints
----------

### Primary keys ###

If we define a primary key on a column SQL Server will implicitly create a `UNIQUE` constraint (and thus index - which by default is clustered).

#### Query retrieving primary keys on tables ####

    SELECT c.name, b.name, a.name
    FROM sys.key_constraints a
    INNER JOIN sys.tables b ON a.parent_object_id = b.OBJECT_ID
    INNER JOIN sys.schemas c ON a.schema_id = c.schema_id
    WHERE a.type = 'PK'

#### Query finding missing primary keys on tables ####

    SELECT c.name, b.name
      FROM sys.tables b
      INNER JOIN sys.schemas c ON b.schema_id = c.schema_id
        WHERE b.type = 'U'
        AND NOT EXISTS
        (SELECT a.name
          FROM sys.key_constraints a
          WHERE a.parent_object_id = b.OBJECT_ID
          AND a.schema_id = c.schema_id
          AND a.type = 'PK' )

### Foreign keys ###

Foreign keys can reference only columns that have unique constraint assigned (thus there is an index on them).

#### Query foreign keys defined on table `advertproducts` ####

    select fk.* from sys.foreign_keys fk
        inner join sys.tables t on t.object_id = fk.parent_object_id and t.name = 'advertproducts'

#### Query foreign key columns with their references defined on table `advertproducts` ####

    select pt.name as 'parent_table'
          ,pc.name as 'parent_column'
          ,ct.name as 'referenced_table'
          ,cc.name as 'referenced_column'
            from sys.foreign_key_columns fkc
                inner join sys.tables pt on pt.object_id = fkc.parent_object_id
                inner join sys.columns pc on pc.object_id = fkc.parent_object_id and pc.column_id = fkc.parent_column_id
                inner join sys.tables ct on ct.object_id = fkc.referenced_object_id
                inner join sys.columns cc on cc.object_id = fkc.referenced_object_id and cc.column_id = fkc.referenced_column_id
                    where pt.name = 'advertproducts'

#### Query foreign key references to a given table ####

    select pt.name as 'parent_table'
          ,pc.name as 'parent_column'
          ,ct.name as 'referenced_table'
          ,cc.name as 'referenced_column'
            from sys.foreign_key_columns fkc
                inner join sys.tables pt on pt.object_id = fkc.parent_object_id
                inner join sys.columns pc on pc.object_id = fkc.parent_object_id and pc.column_id = fkc.parent_column_id
                inner join sys.tables ct on ct.object_id = fkc.referenced_object_id
                inner join sys.columns cc on cc.object_id = fkc.referenced_object_id and cc.column_id = fkc.referenced_column_id
                    where ct.name = 'users'z

Clustered view
-------------

We can create a clustered index on a view, causing it to have duplicated data from the table.

    create view CounterMonthly_View
    with schemabinding
    as select
        item,
        EventType_Id,
        sum(value) as value,
        count_big(*) as cnt
        from dbo.CounterMonthly
        where Eventtype_id in (
         77	,303 ,353 ,354 ,174 ,151)
        group by item, EventType_Id;
    go

    create unique clustered index CIX_CounterMonthly_View
        on CounterMonthly_View(Item, EventType_Id)
    go

`COUNT_BIG` is unfortunately required if we would like to use `GROUP BY` statement in the definition of a view.

**REMARK:** When altering the clustered view, the clustered index is removed and we need to create it back.

Physical index structure
----------------------

The `sys.dm_db_index_physical_stats` function is one of the most useful functions to determine table structures:

    sys.dm_db_index_physical_stats (
        { database_id | NULL | 0 | DEFAULT }
      , { object_id | NULL | 0 | DEFAULT }
      , { index_id | NULL | 0 | -1 | DEFAULT }
      , { partition_number | NULL | 0 | DEFAULT }
      , { mode | NULL | DEFAULT }
    )

Examples:

    SELECT * FROM sys.dm_db_index_physical_stats (NULL, NULL, NULL, NULL, NULL);

    SELECT * FROM sys.dm_db_index_physical_stats
      (DB_ID (N'pubs'), OBJECT_ID (N'dbo.authors'), NULL, NULL, NULL);

Its parameters are: `database_id`, `object_id`, `index_id`, `partition_number` and `mode` (LIMITED, SAMPLED, DETAILED). If we choose LIMITED than parent pages will be examined and the fragmentation will be calculated based on continuity of ids of leaf pages. SAMPLED means that every 100 leaf page will be examined and DETAILED mode will force SQL Server to analyze every possible page.

Another useful command to examine a physical structure of an index we can also use `DBCC IND` (in SQL Server 2012 replaced by `sys.dm_db_database_page_allocations`):

    DBCC IND ( { 'dbname' | dbid }, { 'objname' | objid },
          { nonclustered indid | 1 | 0 | -1 | -2 } [, partition_number]  )

To better analyze the data provided by the above command we may create a helper table (when it's created in `master` database and has a name that starts with `sp_` it will be visible in all other databases):

    USE master;
    GO
    CREATE TABLE sp_tablepages
    (PageFID  tinyint,
      PagePID int,
      IAMFID   tinyint,
      IAMPID  int,
      ObjectID  int,
      IndexID  tinyint,
      PartitionNumber tinyint,
      PartitionID bigint,
      iam_chain_type  varchar(30),
      PageType  tinyint,
      IndexLevel  tinyint,
      NextPageFID  tinyint,
      NextPagePID  int,
      PrevPageFID  tinyint,
      PrevPagePID int,
      Primary Key (PageFID, PagePID));

The following code truncates the sp_tablepages table and then fills it with DBCC IND results from the Sales.SalesOrderDetail table in the AdventureWorks2008 database:

    TRUNCATE TABLE sp_tablepages;
    INSERT INTO sp_tablepages
        EXEC ('DBCC IND (AdventureWorks2008, [Sales.SalesOrderDetail], -1)');


### Query index physical stats with partition usage ###

    select   top 10 OBJECT_NAME(s.[object_id]) as [object_name],
                    i.name as index_name,
                    i.is_primary_key,
                    i.is_unique_constraint,
                    s.partition_number,
                    s.index_type_desc,
                    s.alloc_unit_type_desc,
                    s.avg_fragmentation_in_percent,
                    s.page_count,
                    p.reserved_page_count,
                    p.row_count
    from     sys.dm_db_index_physical_stats (DB_ID(), null, null, null, null) as s
             inner join
             sys.dm_db_partition_stats as p
             on s.[object_id] = p.[object_id]
                and s.partition_number = p.partition_number
                and s.index_id = p.index_id
             inner join
             sys.indexes as i
             on s.[object_id] = i.[object_id]
                and s.index_id = i.index_id
    where    OBJECT_NAME(s.[object_id]) like 'advert%'
    order by OBJECT_NAME(s.[object_id]), s.index_id;

### Examine index fragmentation ###

    -- Examine fragmentation on a GUIDTest database
    SELECT
      OBJECT_NAME (ips.[object_id]) AS 'Object Name',
      si.name AS 'Index Name',
      ROUND (ips.avg_fragmentation_in_percent, 2) AS 'Fragmentation',
      ips.page_count AS 'Pages',
      ROUND (ips.avg_page_space_used_in_percent, 2) AS 'Page Density'
    FROM sys.dm_db_index_physical_stats (
      DB_ID (),
      NULL,
      NULL,
      NULL,
      'DETAILED') ips
    CROSS APPLY sys.indexes si
    WHERE
      si.object_id = ips.object_id
      AND si.index_id = ips.index_id
      AND ips.index_level = 0
    GO

### Operational index stats ###

Returns current low-level I/O, locking, latching, and access method activity for each partition of a table or index in the database.

    sys.dm_db_index_operational_stats (
        { database_id | NULL | 0 | DEFAULT }
      , { object_id | NULL | 0 | DEFAULT }
      , { index_id | 0 | NULL | -1 | DEFAULT }
      , { partition_number | NULL | 0 | DEFAULT }
    )

### Size of each index in a table ###

Based on <http://blog.sqlauthority.com/2010/05/09/sql-server-size-of-index-table-for-each-index-solution-2/>

    SELECT
        OBJECT_NAME(i.OBJECT_ID) AS TableName,
        i.name AS IndexName,
        i.index_id AS IndexID,
        8 * SUM(a.used_pages) AS 'Indexsize(KB)'
        FROM sys.indexes AS i
        JOIN sys.partitions AS p ON p.OBJECT_ID = i.OBJECT_ID AND p.index_id = i.index_id
        JOIN sys.allocation_units AS a ON a.container_id = p.partition_id
        where i.object_id = object_id('Users')
        GROUP BY i.OBJECT_ID,i.index_id,i.name
        ORDER BY OBJECT_NAME(i.OBJECT_ID),i.index_id


Links
-----

- [Interesting article no how to maintenace SQL indexes](http://blogs.msdn.com/b/sql_pfe_blog/archive/2013/09/13/an-approach-to-sql-server-index-tuning.aspx)
- [Indexed Views and Statistics](http://www.sqlperformance.com/2014/01/sql-plan/indexed-views-and-statistics)
