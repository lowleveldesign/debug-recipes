
Diagnosing queries in MS SQL Server
===================================

Table of contents:

- [Order of query execution](#ooqe)
- [Query plans](#qp)
- [Query statistics](#qs)
- [Compiled plans and query caching](#cpqc)
- [Query Optimizer](#qo)
- [Query hints](#qh)

<a href="ooqe">Order of query execution</a>
-------------------------------------------

The order in which SQL directives get executed:

1. FROM clause (and JOINs)
2. WHERE clause
3. GROUP BY clause
4. HAVING clause
5. SELECT clause
6. ORDER BY clause

<a name="qp">Query plans</a>
----------------------------

Usually, you read a graphical execution plan from right to left and top to bottom.

### Examining query plans ###

    SET SHOWPLAN_ALL { ON | OFF }
    SET SHOWPLAN_TEXT { ON | OFF }
    SET SHOWPLAN_XML { ON | OFF }

    SET STATISTICS PROFILE { ON | OFF }
    SET STATISTICS XML { ON | OFF }

All those commands cause SQL Server not to execute a statement but display its estimated plan. `SET SHOWPLAN_ALL` is intended to be used by applications written to handle its output. Use `SET SHOWPLAN_TEXT` to return readable output for Microsoft Win32 command prompt applications, such as the osql utility. When we would like to see the actual plan, we need to use the `set statistics profile|xml on` option.

### Links ###

- Explanation of different sql plan symbols:
  <http://msdn.microsoft.com/en-us/library/ms191158.aspx>
- Execution Plan Analysis: The Mystery Work Table
  <http://sqlblog.com/blogs/paul_white/archive/2013/03/08/execution-plan-analysis-the-mystery-work-table.aspx>
- Spooling in SQL execution plans
  <http://sqlblog.com/blogs/rob_farley/archive/2013/06/11/spooling-in-sql-execution-plans.aspx>

<a name="qs">Query statistics</a>
---------------------------------

### Configuration ###

We can configure the way how statistics are generated on a database level:

    ALTER DATABASE . . . SET AUTO_CREATE_STATISTICS {ON | OFF }
    ALTER DATABASE . . . SET AUTO_UPDATE_STATISTICS {ON | OFF }

or for an index:

    CREATE INDEX . . . WITH (STATISTICS_NORECOMPUTE = ON)
    CREATE STATISTICS . . . WITH (NORECOMPUTE)

If automatic statistics management is turned off we need to periodically update them:

    UPDATE STATISTICS table_or_indexed_view_name

`sp_updatestats` runs UPDATE STATISTICS against all user-defined and internal tables in the current database.

#### Display information on executed query ####

    SET STATISTICS IO { ON | OFF }
    SET STATISTICS TIME { ON | OFF }

Display number of pages that were affected by a query. When SET STATISTICS TIME is ON, the time statistics for a statement are displayed.

    SET STATISTICS PROFILE { ON | OFF }
    SET STATISTICS XML { ON | OFF }

When **STATISTICS PROFILE** is ON, each executed query returns its regular result set, followed by an additional result set that shows a profile of the query execution.

`SET STATISTICS PROFILE` and `SET STATISTICS XML` are counterparts of each other. The former produces textual output; the latter produces XML output. In future versions of SQL Server, new query execution plan information will only be displayed through the `SET STATISTICS XML` statement, not the `SET STATISTICS PROFILE` statement.

#### Statistics on computed columns ####

In SQL Server 2005, the query optimizer will detect the use of the computed column in queries, just as it does for any unindexed column reference, and it will create statistics on the computed column. The statistics will allow the optimizer to determine the appropriate cardinality estimation on the filter. So instead of writing `WHERE UnitPrice * Quantity > 1000` consider creating a computed column:

    ALTER TABLE [Order Details]
    ADD TotalSale AS UnitPrice * Quantity;

### Display information on collected statistics ###

#### sys.stats, sys.stats\_columns ####

Statistics information are stored in `sys.stats` table. Following query will tell you which statistics SQL Server created on the Orders table:

    EXEC sp_helpstats 'Orders', 'ALL';
    GO

    SELECT  [sch].[name] + '.' + [so].[name] AS [TableName] ,
            [si].[index_id] AS [Index ID] ,
            [ss].[name] AS [Statistic] ,
            STUFF(( SELECT  ', ' + [c].[name]
                    FROM    [sys].[stats_columns] [sc]
                            JOIN [sys].[columns] [c]
                             ON [c].[column_id] = [sc].[column_id]
                                AND [c].[object_id] = [sc].[OBJECT_ID]
                    WHERE   [sc].[object_id] = [ss].[object_id]
                            AND [sc].[stats_id] = [ss].[stats_id]
                    ORDER BY [sc].[stats_column_id]
                  FOR
                    XML PATH('')
                  ), 1, 2, '') AS [ColumnsInStatistic] ,
            [ss].[auto_Created] AS [WasAutoCreated] ,
            [ss].[user_created] AS [WasUserCreated] ,
            [ss].[has_filter] AS [IsFiltered] ,
            [ss].[filter_definition] AS [FilterDefinition] ,
            [ss].[is_temporary] AS [IsTemporary]
    FROM    [sys].[stats] [ss]
            JOIN [sys].[objects] AS [so] ON [ss].[object_id] = [so].[object_id]
            JOIN [sys].[schemas] AS [sch] ON [so].[schema_id] = [sch].[schema_id]
            LEFT OUTER JOIN [sys].[indexes] AS [si]
                  ON [so].[object_id] = [si].[object_id]
                     AND [ss].[name] = [si].[name]
    WHERE   [so].[object_id] = OBJECT_ID(N'Orders')
    ORDER BY [ss].[user_created] ,
            [ss].[auto_created] ,
            [ss].[has_filter];
    GO

    select name from sys.stats where object_id = OBJECT_ID('dbo.Orders') and auto_created = 1

#### sp\_helpstats (obsolete) ####

    sp_helpstats[ @objname = ] 'object_name'
         [ , [ @results = ] 'value' ]

#### DBCC SHOW\_STATISTICS ####

To examine statistics information for a given column we can use **DBCC SHOW_STATISTICS** command:

    DBCC SHOW_STATISTICS ( table_or_indexed_view_name , target )
    [ WITH [ NO_INFOMSGS ] < option > [ , n ] ]
    < option > :: =
        STAT_HEADER | DENSITY_VECTOR | HISTOGRAM | STATS_STREAM

`target` is either name of the index, statistics or column for which statistics should be displayed. If an automatically created statistic does not exist for a column target, error message 2767 is returned.

Example (output in a seperate file):

    dbcc show_statistics (Users, name)

As there is no DMV view for displaying statistics we can store DBCC command results in tables (check stats-in-tables.sql).

### Measure rate of modifications ###

    -- all statistics, ordered by update_date descending
    SELECT  [sch].[name] + '.' + [so].[name] AS [TableName] ,
            [ss].[name] AS [Statistic] ,
            [ss].[auto_Created] AS [WasAutoCreated] ,
            [ss].[user_created] AS [WasUserCreated] ,
            [ss].[has_filter] AS [IsFiltered] ,
            [ss].[filter_definition] AS [FilterDefinition] ,
            [ss].[is_temporary] AS [IsTemporary],
            [sp].[last_updated] AS [StatsLastUpdated],
            [sp].[rows] AS [RowsInTable],
            [sp].[rows_sampled] AS [RowsSampled],
            [sp].[unfiltered_rows] AS [UnfilteredRows],
            [sp].[modification_counter] AS [RowModifications],
            [sp].[steps] AS [HistogramSteps]
    FROM    [sys].[stats] [ss]
            JOIN [sys].[objects] [so] ON [ss].[object_id] = [so].[object_id]
            JOIN [sys].[schemas] [sch] ON [so].[schema_id] = [sch].[schema_id]
            OUTER APPLY [sys].[dm_db_stats_properties]
                                  ([so].[object_id],[ss].[stats_id]) sp
    WHERE   [so].[type] = 'U'
    ORDER BY [sp].[last_updated] DESC;

    -- statistics with more than 10% change
    SELECT
        [sch].[name] + '.' + [so].[name] AS [TableName],
        [ss].[name] AS [Statistic],
        [ss].[auto_Created] AS [WasAutoCreated],
        [ss].[user_created] AS [WasUserCreated],
        [ss].[has_filter] AS [IsFiltered],
        [ss].[filter_definition] AS [FilterDefinition],
        [ss].[is_temporary] AS [IsTemporary],
        [sp].[last_updated] AS [StatsLastUpdated],
        [sp].[rows] AS [RowsInTable],
        [sp].[rows_sampled] AS [RowsSampled],
        [sp].[unfiltered_rows] AS [UnfilteredRows],
        [sp].[modification_counter] AS [RowModifications],
        [sp].[steps] AS [HistogramSteps],
        CAST(100 * [sp].[modification_counter] / [sp].[rows]
                                AS DECIMAL(18,2)) AS [PercentChange]
    FROM [sys].[stats] [ss]
    JOIN [sys].[objects] [so] ON [ss].[object_id] = [so].[object_id]
    JOIN [sys].[schemas] [sch] ON [so].[schema_id] = [sch].[schema_id]
    OUTER APPLY [sys].[dm_db_stats_properties]
                        ([so].[object_id], [ss].[stats_id]) sp
    WHERE [so].[type] = 'U'
    AND CAST(100 * [sp].[modification_counter] / [sp].[rows]
                                            AS DECIMAL(18,2)) >= 10.00
    ORDER BY CAST(100 * [sp].[modification_counter] / [sp].[rows]
                                            AS DECIMAL(18,2)) DESC;

### Links ###

- Geek City: Accessing Distribution Statistics
  <http://sqlblog.com/blogs/kalen_delaney/archive/2013/01/18/accessing-distribution-statistics.aspx>
- Managing SQL Server Statistics - very detailed article
  <https://www.simple-talk.com/sql/performance/managing-sql-server-statistics/>
- Stats on Stats
  <http://sqlblog.com/blogs/merrill_aldrich/archive/2013/09/18/stats-on-stats.aspx>

<a name="cpqc">Compiled plans and query caching</a>
---------------------------------------------------

Each query passed to MS SQL Server is compiled and then cached. The following query returns information about cached compiled plans:

    SELECT usecounts, cacheobjtype, objtype, [text], query_plan
    FROM sys.dm_exec_cached_plans P
        CROSS APPLY sys.dm_exec_sql_text(plan_handle)
        CROSS APPLY sys.dm_exec_query_plan(plan_handle)
    WHERE cacheobjtype = 'Compiled Plan'
        AND [text] NOT LIKE '%dm_exec_cached_plans%';

To get information about cached plan generated for our current request use the following query:

    select * from sys.dm_exec_cached_plans where plan_handle =
        (select plan_handle from sys.dm_exec_requests where session_id = @@spid)

`sql_handle` is a handle to the SQL statement that was executed in the batch, `plan_handle` is its corresponding query plan. Additionally the `sys.dm_exec_query_stats` view contains offsets which allow us to extract particular queries from the batch.

    SELECT execution_count, text, sql_handle, query_plan
    FROM sys.dm_exec_query_stats
       CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS TXT
           CROSS APPLY sys.dm_exec_query_plan(plan_handle)AS PLN;

Cached query plans are retrieved using the following functions:

- `sys.dm_exec_query_plan` - returns xml query plan
- `sys.dm_exec_text_query_plan` - returns text query plan
- `sys.dm_exec_cached_plans`
- `sys.dm_exec_cached_plan_dependent_objects` - query plan dependent objects (must be a compiled plan)

It is very important to **use db objects with a schema name** as omitting it might force SQL Server to invalidate the cached plan. For adhoc queries, only another connection with the same user ID value can use the same plan. The one exception is if the user ID value is recorded as –2 in `syscacheobjects`, which indicates that the query submitted does not depend on implicit name resolution and can be shared among different users.

### Plan cache attributes ###

Anytime a query plan gets generated SQL Server saves additional properties that describe its execution environment. This is further used to recompile plans that are not valid after some configuration changes. You can get plan cache attributes by issuing:

    SELECT * FROM sys.dm_exec_plan_attributes(0x06001200CF0B831CB821AA05000000000000000000000000)

We can get the **sql\_handle** value that corresponds to a particular **plan\_handle** from the `sys.dm_exec_plan_attributes` function. Here is the query to return attribute information and pivot it so that three of the attributes are returned in the same row as the plan_handle value.

    SELECT plan_handle, pvt.set_options, pvt.object_id, pvt.sql_handle
    FROM (SELECT plan_handle, epa.attribute, epa.value
         FROM sys.dm_exec_cached_plans
            OUTER APPLY sys.dm_exec_plan_attributes(plan_handle) AS epa
         WHERE cacheobjtype = 'Compiled Plan'
         ) AS ecpa
    PIVOT (MAX(ecpa.value) FOR ecpa.attribute
       IN ("set_options", "object_id", "sql_handle")) AS pvt;

And here is the query that creates a stored procedure that will combine the above results with XML plans:

    USE master
    GO
    CREATE VIEW sp_cacheobjects
       (bucketid, cacheobjtype, objtype, objid, dbid, dbidexec, uid,
       refcounts, usecounts, pagesused, setopts, langid, dateformat,
       status, lasttime, maxexectime, avgexectime, lastreads,
       lastwrites, sqlbytes, sql)
    AS
       SELECT pvt.bucketid,
          CONVERT(nvarchar(17), pvt.cacheobjtype) AS cacheobjtype,
          pvt.objtype,
          CONVERT(int, pvt.objectid) AS object_id,
          CONVERT(smallint, pvt.dbid) AS dbid,
          CONVERT(smallint, pvt.dbid_execute) AS execute_dbid,
          CONVERT(smallint, pvt.user_id) AS user_id,
          pvt.refcounts, pvt.usecounts,
          pvt.size_in_bytes / 8192 AS size_in_bytes,
          CONVERT(int, pvt.set_options) AS setopts,
          CONVERT(smallint, pvt.language_id) AS langid,
          CONVERT(smallint, pvt.date_format) AS date_format,
          CONVERT(int, pvt.status) AS status,
          CONVERT(bigint, 0),
          CONVERT(bigint, 0),
          CONVERT(bigint, 0),
          CONVERT(bigint, 0),
          CONVERT(bigint, 0),
          CONVERT(int, LEN(CONVERT(nvarchar(max), fgs.text)) * 2),
          CONVERT(nvarchar(3900), fgs.text)
    FROM (SELECT ecp.*, epa.attribute, epa.value
      FROM sys.dm_exec_cached_plans ecp
       OUTER APPLY
         sys.dm_exec_plan_attributes(ecp.plan_handle) epa) AS ecpa
    PIVOT (MAX(ecpa.value) for ecpa.attribute IN
       ("set_options", "objectid", "dbid",
       "dbid_execute", "user_id", "language_id",
       "date_format", "status")) AS pvt
    OUTER APPLY sys.dm_exec_sql_text(pvt.plan_handle) fgs

### Plan cache dependent objects ###

The `sys.dm_exec_cached_plan_dependent_objects` contains information about all objects that a given cached plan depends on.  The example below uses `sys.dm_exec_cached_plan_dependent_objects`, as well as `sys.dm_exec_cached_plans`, to retrieve the dependent objects for all compiled plans, the `plan_handle`, and their usecounts. It also calls the `sys.dm_exec_sql_text function` to return the associated Transact-SQL batch:

    SELECT text, plan_handle, d.usecounts, d.cacheobjtype
    FROM sys.dm_exec_cached_plans
      CROSS APPLY sys.dm_exec_sql_text(plan_handle)
      CROSS APPLY sys.dm_exec_cached_plan_dependent_objects(plan_handle) d;

### Prepared statements ###

Prepared statements can be created either using `sp_executesql` procedure or by calling `PrepareStatement` in a client application. In both cases SQL Server will reuse the already created (and cached) plan. The only difference is that in the latter way application receives a handle to the statement and thus does not need to pass the whole query statement in subsequent queries.

Example of using `sp_executesql` (taken from NHibernate log):

    sp_executesql N'select aggregatio0_.AggregationDay as Aggregat1_0_0_, eventtype1_.Id as Id2_1_,
                        aggregatio0_.AggregatedEventsCount as Aggregat2_0_0_, aggregatio0_.AggregatedEventsSummedValue as Aggregat3_0_0_,
                        aggregatio0_.EventTypeId as EventTyp4_0_0_, eventtype1_.Name as Name2_1_,
                        eventtype1_.Title as Title2_1_, eventtype1_.Description as Descript4_2_1_,
                        eventtype1_.Service_id as Service5_2_1_
                            from AggregationsFromMySql_Numbers aggregatio0_
                                inner join [EventType] eventtype1_ on aggregatio0_.EventTypeId=eventtype1_.Id
                                    where eventtype1_.Service_id=@p0 and aggregatio0_.AggregationDay>@p1',
                                        N'@p0 int, @p1 datetime',
                                        @p0 = 6, @p1 = '2012-10-29 00:00:00'

We can also force parametrization of an adhoc statements by using **PARAMETRIZATION FORCED** - though it's not a recommended approach as it may cause invalid plans to be generated by SQL Server:

    USE Northwind2
    GO
    ALTER DATABASE Northwind2 SET PARAMETERIZATION FORCED
    GO
    SET STATISTICS IO ON
    GO
    DBCC FREEPROCCACHE
    GO
    SELECT * FROM BigOrders WHERE CustomerID = 'CENTC'
    GO
    SELECT * FROM BigOrders WHERE CustomerID = 'SAVEA'
    GO
    SELECT usecounts, cacheobjtype, objtype, [text]
    FROM sys.dm_exec_cached_plans P
       CROSS APPLY sys.dm_exec_sql_text (plan_handle)
    WHERE cacheobjtype = 'Compiled Plan'
       AND [text] NOT LIKE '%dm_exec_cached_plans%';
    GO
    ALTER DATABASE Northwind2 SET PARAMETERIZATION SIMPLE
    GO

### Stored procedures cache ###

SQL Server caches also plans generated when executing Stored Procedures. If the generated plan becomes invalid we can force SQL Server to rebuild it for one execution of the query:

    EXECUTE ... WITH RECOMPILE

### Clearing query caches ###

Clears out all SQL Server memory caches:

    DBCC FREESYSTEMCACHE

Clears all plans from the particular database:

    DBCC FLUSHPROCINDB(<dbid>)

Removes all cached plans from memory:

    DBCC FREEPROCCACHE [ ( { plan_handle | sql_handle | pool_name } ) ] [ WITH NO_INFOMSGS ]

### Find parameters stored in a query plan cache ###

    -- list query parameters
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    GO
    WITH XMLNAMESPACES (DEFAULT
    'http://schemas.microsoft.com/sqlserver/2004/07/showplan')
    ,PlanParameters
    AS (
      SELECT ph.plan_handle, qp.query_plan, qp.dbid, qp.objectid
      FROM sys.dm_exec_cached_plans ph
        OUTER APPLY sys.dm_exec_query_plan(ph.plan_handle) qp
      WHERE qp.query_plan.exist('//ParameterList')=1
      and OBJECT_NAME(qp.objectid, qp.dbid) = 'uspGetWhereUsedProductID'
    )
    SELECT
      DB_NAME(pp.dbid) AS DatabaseName
      ,OBJECT_NAME(pp.objectid, pp.dbid) AS ObjectName
      ,n2.value('(@Column)[1]','sysname') AS ParameterName
      ,n2.value('(@ParameterCompiledValue)[1]','varchar(max)')
    AS ParameterValue
    From PlanParameters pp
      CROSS APPLY query_plan.nodes('//ParameterList') AS q1(n1)
      CROSS APPLY n1.nodes('ColumnReference') as q2(n2)

### Query cache internals

SQL Server's plan cache is made up of four separate memory areas, called cache stores. There are actually other stores in SQL Server's memory, which can be seen in the Dynamic Management View (DMV) called `sys.dm_os_memory_cache_counters`, but there are only four that contain query plans. The DMV `sys.dm_os_memory_cache_hash_tables` contains information about each hash table, including its size. You can query this view to retrieve the number of buckets for each of the plan cache stores using the following query:

    SELECT type as 'plan cache store', buckets_count
    FROM sys.dm_os_memory_cache_hash_tables
    WHERE type IN ('CACHESTORE_OBJCP', 'CACHESTORE_SQLCP', 'CACHESTORE_PHDR', 'CACHESTORE_XPROC');

The DMV `sys.dm_os_memory_cache_entries` can show you the current and original cost of any cache entry, as well as the components that make up that cost.

    SELECT text, objtype, refcounts, usecounts, size_in_bytes,
       disk_ios_count, context_switches_count,
       pages_allocated_count, original_cost, current_cost
    FROM sys.dm_exec_cached_plans p
       CROSS APPLY sys.dm_exec_sql_text(plan_handle)
       JOIN sys.dm_os_memory_cache_entries e
         ON p.memory_object_address = e.memory_object_address
      WHERE cacheobjtype = 'Compiled Plan'
         AND type in ('CACHESTORE_SQLCP', 'CACHESTORE_OBJCP')
      ORDER BY objtype desc, usecounts DESC;

Note that we can find the specific entry in `sys.dm_os_memory_cache_entries` that corresponds to a particular plan in `sys.dm_exec_cached_plans` by joining on the memory\_object\_address column.

### Using query plan hints ###

#### KEEP PLAN / KEEPFIXED PLAN ####

Use of this hint changes the recompilation thresholds for temporary tables and makes them identical to those for permanent tables. So if changes to temporary tables are causing many recompilations, and you suspect that the recompilations are affecting overall system performance, you can use this hint and see if there is a performance improvement. The hint can be specified as shown in this query:

    SELECT <column list>
      FROM dbo.PermTable A INNER JOIN #TempTable B ON A.col1 = B.col2
    WHERE <filter conditions> OPTION (KEEP PLAN)

To avoid all recompilations that are caused by changes in statistics, whether on a permanent or a temporary table, you can specify the **KEEPFIXED PLAN** query hint. With this hint, recompilations can only happen because of correctness-related reasons. An example might be when a recompilation occurs if the schema of a table that is referenced by a statement changes, or if a table is marked for recompile by using the `sp_recompile` stored procedure.

#### RECOMPILE ####

Causes plan to be recompiled for a given query, example:

    USE Northwind2;
    DECLARE @custID nchar(10);
    SET @custID = 'LAZYK';
    SELECT * FROM Orders WHERE CustomerID = @custID
    OPTION (RECOMPILE);

#### OPTIMIZE FOR ####

Informs SQL Server for what parameters' values the query plan should be generated. To force SQL Server to rather use average statistics use `OPTIMIZE FOR (@parameter UNKNOWN)` or `OPTIMIZE FOR UNKNOWN`.

#### USE PLAN ####

Forces SQL Server to use a plan provided as a parameter (Plan must be in a form of XML).

### Using plan guides ###

When it's impossible to change the query sent to SQL Server we can create a plan guide for it. The three types of plan types can all be created using the `sp_create_plan_guide` procedure. The general form of the `sp_create_plan_guide` procedure is as follows:

    sp_create_plan_guide 'plan_guide_name', 'statement_text',
       'type_of_plan_guide', 'object_name_or_batch_text',
       'parameter_list', 'hints'

Example of creating a plan guide with an `OPTIMIZE FOR` hint for a query:

    EXEC sp_create_plan_guide
       @name = N'plan_US_Country',
       @stmt =
          N'SELECT SalesOrderID, OrderDate, h.CustomerID, h.TerritoryID
               FROM Sales.SalesOrderHeader AS h
               INNER JOIN Sales.Customer AS c
                  ON h.CustomerID = c.CustomerID
               INNER JOIN Sales.SalesTerritory AS t
                  ON c.TerritoryID = t.TerritoryID
               WHERE t.CountryRegionCode = @Country',
    @type = N'OBJECT',
    @module_or_batch = N'Sales.GetOrdersByCountry',
    @params = NULL,
    @hints = N'OPTION (OPTIMIZE FOR (@Country = N''US''))';

Read "Inside SQL Server querying" for more information on how to manage plan guides.

### Links

- Parameter Sniffing, Embedding, and the RECOMPILE Options
  <http://www.sqlperformance.com/2013/08/t-sql-queries/parameter-sniffing-embedding-and-the-recompile-options>

<a name="qo">Query Optimizer</a>
--------------------------------

### Diagnosing query optimization ###

To display a query tree you need to enable 3604 flag:

     DBCC TRACEON(3604)

     Input tree (ISO-92)
     SELECT
         p.Name,
         Total = SUM(inv.Quantity)
     FROM Production.Product AS p
     JOIN Production.ProductInventory AS inv ON
         inv.ProductID = p.ProductID
     WHERE
         p.Name LIKE N'[A-G]%'
     GROUP BY
         p.Name
     OPTION (RECOMPILE, QUERYTRACEON 8605);

### Emulate production query execution locally ###

There are multiple parameters that define how the query optimizer runs. One of them are statistics which you can export to your system. Other parameters are the number of CPU Cores or the amount of memory. Using **DBCC OPTIMIZER\_WHATIF** you may fool the query optimizer about the actual system settings as described in the first link.

To display the current optimizer settings:

    DBCC TRACEON(3604) WITH NO_INFOMSGS
    DBCC OPTIMIZER_WHATIF(0) WITH NO_INFOMSGS;
    GO

Based on:
- <http://www.simple-talk.com/sql/database-administration/using-optimizer_whatif-and-statsstream-to-simulate-a-production-environment/>


### Links ###

- [Query Optimizer Deep Dive - Part 1](http://sqlblog.com/blogs/paul_white/archive/2012/04/28/query-optimizer-deep-dive-part-1.aspx)
- [Query Optimizer Deep Dive - Part 2](http://sqlblog.com/blogs/paul_white/archive/2012/04/28/query-optimizer-deep-dive-part-2.aspx)
- [Query Optimizer Deep Dive - Part 3](http://sqlblog.com/blogs/paul_white/archive/2012/04/29/query-optimizer-deep-dive-part-3.aspx)
- [Query Optimizer Deep Dive - Part 4](http://sqlblog.com/blogs/paul_white/archive/2012/05/01/query-optimizer-deep-dive-part-4.aspx)

- <http://www.simple-talk.com/sql/performance/sql-server-prefetch-and-query-performance/>
- <http://blog.sqlworkshops.com/index.php/prefetch/>

- [Great blog about query optimizer](http://blogs.msdn.com/b/craigfr/)

- [Inside SQL Server Parse, Compile and Optimize](http://sqlmag.com/t-sql/inside-sql-server-parse-compile-and-optimize)

<a name="qh">Query hints</a>
----------------------------

### FAST N ###

It might be useful in situations where SQL Server chooses clustered index scan instead of using nonclustered index and key lookups.

    SELECT [OrderId], [CustomerId], [OrderDate]
    FROM [Orders]
    ORDER BY [OrderDate]
    OPTION (FAST 1)

### OPTIMIZE FOR ###

This might be useful in situation when optimizer does not know the value of the parameter in query and finds a generally good plan, eg.:

    DECLARE @ShipCode nvarchar(20)
    SET @ShipCode = N'05022'
    SELECT [OrderId], [OrderDate]
    FROM [Orders]
    WHERE [ShipPostalCode] = @ShipCodeOPTION (OPTIMIZE FOR (@ShipCode = N'05022'))

### HASH JOIN, MERGE JOIN, LOOP JOIN ###

Those hints forces SQL Server to use the specified join strategy when performing joins during the query execution. You may specify more than one type of join in a query hint, eg.

    SELECT C.custid, C.custname, O.orderid, O.empid, O.shipperid, O.orderdate
    FROM dbo.Customers AS C
      JOIN dbo.Orders AS O
        ON O.custid = C.custid
    OPTION(LOOP JOIN, HASH JOIN);

### ORDER GROUP, HASH GROUP ###

Those hints are used when choosing the grouping strategy for a query. Example:

    SELECT [CustomerId], MAX([OrderDate])
    FROM [Orders]
    GROUP BY [CustomerId]
    OPTION (HASH GROUP)

SQL Server always uses the stream aggregate operator for scalar aggregations. There is
no way to force the optimizer to use a hash aggregate for a scalar aggregation. If you attempt
to use the HASH GROUP hint on a query with a scalar aggregation, the optimizer will fail
with an error.

### CONCAT UNION, MERGE UNION, HASH UNION ###

Example:

    SELECT [CustomerId]
    FROM [Orders]
    WHERE [ShipCity] = N'London'
    UNION
    SELECT [CustomerId]
    FROM [Customers]
    WHERE [City] = N'London'
    OPTION (MERGE UNION)

### FORCE ORDER ###

By using this hint we instruct the query optimizer that it should perform joins in an order that we wrote them. Example:

    SELECT O.[OrderId]
    FROM [Customers] C JOIN [Orders] O
       ON C.[CustomerId] = O.[CustomerId]
       JOIN [Employees] E ON O.[EmployeeId] = E.[EmployeeId]
    WHERE C.[City] = N'London' AND E.[City] = N'London'
    OPTION (FORCE ORDER, HASH JOIN)

This hint is also useful to force the aggregation order, example:

    SELECT O.[CustomerId], COUNT(*)
    FROM [Customers] C JOIN [Orders] O
       ON C.[CustomerId] = O.[CustomerId]
    WHERE C.[Country] = N'USA'
    GROUP BY O.[CustomerId]
    OPTION (FORCE ORDER)

### MAXDOP N ###

This hint is used to change the degree of parallelism for a query.

### EXPAND VIEWS ###

FIXME

