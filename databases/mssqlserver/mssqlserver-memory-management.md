MS SQL Server memory management
===============================

General information
-------------------

SQL Server keeps information about free memory pages in a buffer pool. When any SQL Server component requests memory it's is provided with first available buffer. A buffer is a page in memory usually of the same size as a table or index page.

SQL Server periodically scans the buffer memory in order to write dirty pages to disk - this operation is called **a checkpoint** and can be triggered also manually by using the `CHECKPOINT` command. If you’re interested in tracing when checkpoints actually occur, you can use the SQL Server extended events sqlserver.checkpoint_begin and sqlserver.checkpoint_end to monitor checkpoint activity.

if you take a look at the DMV `sys.dm_os_memory_cache_clock_hands`, specifically at the removed_last_round_count column, you can look for a value that is very large compared to other values. If you notice that value increasing dramatically, that is a strong indication of memory pressure.


The DMV called sys.dm_os_memory_clerks has a column called multi_pages_kb that shows how much space is used by a memory component outside the buffer pool:

    SELECT type, sum(multi_pages_kb)
      FROM sys.dm_os_memory_clerks
        WHERE multi_pages_kb != 0
        GROUP BY type;

`View Server State` is required to access the control dynamic views.

### Clear buffer pool ###

The below command clears SQL Server buffer pool:

    -- Let's get it out of cache
    DBCC DROPCLEANBUFFERS;

### Check if a page is in the buffer pool ###

The below commands checks whether a page is in the buffer pool:

    SELECT COUNT(*)
    FROM [sys].[dm_os_buffer_descriptors]
    WHERE [page_id] = 248 AND
        [database_id] = DB_ID();

### sys.dm\_os\_memory\_clerks ###

This view returns one row per memory clerk that is currently active in the instance of SQL Server. You can think of a clerk as an accounting unit. Each store described earlier is a clerk, but some clerks are not stores, such as those for the CLR and for full-text search. The following query returns a list of all the types of clerks:

    SELECT DISTINCT type FROM sys.dm_os_memory_clerks;

Interesting columns include the following:

- `single_pages_kb` The amount of single-page memory allocated, in kilobytes. This is the amount of memory allocated by using the single-page allocator of a memory node. This single-page allocator steals pages directly from the buffer pool.
- `multi_pages_kb` The amount of multiple-page memory allocated, in kilobytes. This is the amount of memory allocated by using the multiple-page allocator of the memory nodes. This memory is allocated outside the buffer pool and takes advantage of the virtual allocator of the memory nodes.
- `virtual_memory_reserved_kb` The amount of virtual memory reserved by a memory clerk. This is the amount of memory reserved directly by the component that uses this clerk. In most situations, only the buffer pool reserves VAS directly by using its memory clerk.
- `virtual_memory_committed_kb` The amount of memory committed by the clerk. The amount of committed memory should always be less than the amount of Reserved Memory.
- `awe_allocated_kb` The amount of memory allocated by the memory clerk by using AWE. In SQL Server, only buffer pool clerks (`MEMORYCLERK_SQLBUFFERPOOL`) use this mechanism, and only when AWE is enabled.


### sys.dm\_os\_memory\_cache\_counters ###

This view returns a snapshot of the health of each cache of type userstore and cachestore. It provides run-time information about the cache entries allocated, their use, and the source of memory for the cache entries. Interesting columns include the following:

- `single_pages_kb` The amount of single-page memory allocated, in kilobytes. This is the amount of memory allocated by using the single-page allocator. This refers to the 8-KB pages that are taken directly from the buffer pool for this cache.
- `multi_pages_kb` The amount of multiple-page memory allocated, in kilobytes. This is the amount of memory allocated by using the multiple-page allocator of the memory node. This memory is allocated outside the buffer pool and takes advantage of the virtual allocator of the memory nodes.
- `multi_pages_in_use_kb` The amount of multiple-page memory being used, in kilobytes.
- `single_pages_in_use_kb` The amount of single-page memory being used, in kilobytes.
- `entries_count` The number of entries in the cache.
- `entries_in_use_count` The number of entries in use in the cache.

### sys.dm\_os\_memory\_cache\_hash\_tables ###

This view returns a row for each active cache in the instance of SQL Server. This view can be joined to `sys.dm_os_memory_cache_counters` on the `cache_address` column. Interesting columns include the following:

- `buckets_count` The number of buckets in the hash table.
- `buckets_in_use_count` The number of buckets currently being used.
- `buckets_min_length` The minimum number of cache entries in a bucket.
- `buckets_max_length` The maximum number of cache entries in a bucket.
- `buckets_avg_length` The average number of cache entries in each bucket. If this number gets very large, it might indicate that the hashing algorithm is not ideal.
- `buckets_avg_scan_hit_length` The average number of examined entries in a bucket before the searched-for item was found. As above, a big number might indicate a less-than-optimal cache. You might consider running `DBCC FREESYSTEMCACHE` to remove all unused entries in the cache stores. You can get more details on this command in SQL Server Books Online.

### sys.dm\_os\_memory\_cache\_clock\_hands ###

This DMV, discussed earlier, can be joined to the other cache DMVs using the cache_address column. Interesting columns include the following:

- `clock_hand` The type of clock hand, either external or internal. Remember that there are two clock hands for every store.
- `clock_status` The status of the clock hand: suspended or running. A clock hand runs when a corresponding policy kicks in.
- `rounds_count` The number of rounds the clock hand has made. All the external clock hands should have the same (or close to the same) value in this column.
- `removed_all_rounds_count` The number of entries removed by the clock hand in all rounds.

Memory issues
-------------

### Check memory usage (DBCC MEMORYSTATUS) ###

    dbcc memorystatus

### SQL Server caches ###

There are four types of caches in SQL Server that can be queried using **sys.dm\_os\_memory\_cache\_counters**:

- Object Plans (`CACHESTORE_OBJCP`) - Object Plans include plans for stored procedures, functions, and triggers.
- SQL Plans (`CACHESTORE_SQLCP`) -  SQL Plans include the plans for adhoc cached plans, autoparameterized plans, and prepared plans. The memory clerk that manages the SQLCP cache store is also used for the SQL Manager, which manages all the T-SQL text used in your adhoc queries.
- Bound Trees (`CACHESTORE_PHDR`) - Bound Trees are the structures produced by the algebrizer in SQL Server for views, constraints, and defaults.
- Extended Stored Procedures (`CACHESTORE_XPROC`) - Extended Procs (Xprocs) are predefined system procedures, like `sp_executesql` and `sp_tracecreate`, that are defined using a dynamic link library (DLL), not using T-SQL statements. The cached structure contains only the function name and the DLL name in which the procedure is implemented.

You can query this view to retrieve the number of buckets for each of the plan cache stores using the following query:

    SELECT type as 'plan cache store', buckets_count
    FROM sys.dm_os_memory_cache_hash_tables
    WHERE type IN ('CACHESTORE_OBJCP', 'CACHESTORE_SQLCP',
       'CACHESTORE_PHDR', 'CACHESTORE_XPROC');

The following query returns the size of all the cache stores holding plans, plus the size of the SQL Manager, which stores the T-SQL text of all the adhoc and prepared queries:

    SELECT type AS Store, SUM(pages_allocated_count) AS Pages_used
    FROM sys.dm_os_memory_objects
    WHERE type IN ('MEMOBJ_CACHESTOREOBJCP', 'MEMOBJ_CACHESTORESQLCP',
      'MEMOBJ_CACHESTOREXPROC', 'MEMOBJ_SQLMGR')
    GROUP BY type

### Buffer pools usage ###

When pages are fragmented it may happen that the SQL Server buffer pool contains pages which unnecessarily occupy space (are half or more empty). To examine buffer pool usage among databases you may use the query below (after <http://www.sqlskills.com/blogs/paul/performance-issues-from-wasted-buffer-pool-memory/>):

     SELECT
        (CASE WHEN ([database_id] = 32767)
            THEN N'Resource Database'
            ELSE DB_NAME ([database_id]) END) AS [DatabaseName],
        COUNT (*) * 8 / 1024 AS [MBUsed],
        SUM (CAST ([free_space_in_bytes] AS BIGINT)) / (1024 * 1024) AS [MBEmpty]
    FROM sys.dm_os_buffer_descriptors
    GROUP BY [database_id];
    GO

To break things to table level use the following sql:

    EXEC sp_MSforeachdb
        N'IF EXISTS (SELECT 1 FROM (SELECT DISTINCT DB_NAME ([database_id]) AS [name]
        FROM sys.dm_os_buffer_descriptors) AS names WHERE [name] = ''?'')
    BEGIN
    USE [?]
    SELECT
        ''?'' AS [Database],
        OBJECT_NAME (p.[object_id]) AS [Object],
        p.[index_id],
        i.[name] AS [Index],
        i.[type_desc] AS [Type],
        --au.[type_desc] AS [AUType],
        --DPCount AS [DirtyPageCount],
        --CPCount AS [CleanPageCount],
        --DPCount * 8 / 1024 AS [DirtyPageMB],
        --CPCount * 8 / 1024 AS [CleanPageMB],
        (DPCount + CPCount) * 8 / 1024 AS [TotalMB],
        --DPFreeSpace / 1024 / 1024 AS [DirtyPageFreeSpace],
        --CPFreeSpace / 1024 / 1024 AS [CleanPageFreeSpace],
        ([DPFreeSpace] + [CPFreeSpace]) / 1024 / 1024 AS [FreeSpaceMB],
        CAST (ROUND (100.0 * (([DPFreeSpace] + [CPFreeSpace]) / 1024) / (([DPCount] + [CPCount]) * 8), 1) AS DECIMAL (4, 1)) AS [FreeSpacePC]
    FROM
        (SELECT
            allocation_unit_id,
            SUM (CASE WHEN ([is_modified] = 1)
                THEN 1 ELSE 0 END) AS [DPCount],
            SUM (CASE WHEN ([is_modified] = 1)
                THEN 0 ELSE 1 END) AS [CPCount],
            SUM (CASE WHEN ([is_modified] = 1)
                THEN CAST ([free_space_in_bytes] AS BIGINT) ELSE 0 END) AS [DPFreeSpace],
            SUM (CASE WHEN ([is_modified] = 1)
                THEN 0 ELSE CAST ([free_space_in_bytes] AS BIGINT) END) AS [CPFreeSpace]
        FROM sys.dm_os_buffer_descriptors
        WHERE [database_id] = DB_ID (''?'')
        GROUP BY [allocation_unit_id]) AS buffers
    INNER JOIN sys.allocation_units AS au
        ON au.[allocation_unit_id] = buffers.[allocation_unit_id]
    INNER JOIN sys.partitions AS p
        ON au.[container_id] = p.[partition_id]
    INNER JOIN sys.indexes AS i
        ON i.[index_id] = p.[index_id] AND p.[object_id] = i.[object_id]
    WHERE p.[object_id] > 100 AND ([DPCount] + [CPCount]) > 12800 -- Taking up more than 100MB
    ORDER BY [FreeSpacePC] DESC;
    END';

System memory information
-----------------------

You can gt information about operating system memory using one of the views:

    select * from sys.dm_os_sys_memory
    select * from sys.dm_os_sys_info

Examine errors
--------------

### Memory dumps (sys.dm\_server\_memory\_dumps) ###

Displays memory dumps generated by the SQL Server Database Engine.
