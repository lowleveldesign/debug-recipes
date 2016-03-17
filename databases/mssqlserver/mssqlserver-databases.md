
DATABASES
========

A database is owned by a single SQL Server login account. It maintains its own set of user accounts, roles, schemas, and security. It has its own set of system tables to hold the database catalog. It has its own transaction log and manages its own transactions.

A new SQL Server installation always includes four databases: master, model, tempdb, and msdb.

Example of creating a database:

    CREATE DATABASE Archive
    ON
    PRIMARY
    ( NAME = Arch1,
    FILENAME =
        'c:\program files\microsoft sql server\mssql.1\mssql\data\archdat1.mdf',
    SIZE = 100MB,
    MAXSIZE = 200MB,
    FILEGROWTH = 20MB),
    ( NAME = Arch2,
    FILENAME =
        'c:\program files\microsoft sql server\mssql.1\mssql\data\archdat2.ndf',
    SIZE = 10GB,
    MAXSIZE = 50GB,
    FILEGROWTH = 250MB)
    LOG ON
    ( NAME = Archlog1,
    FILENAME =
        'c:\program files\microsoft sql server\mssql.1\mssql\data\archlog1.ldf',
    SIZE = 2GB,
    MAXSIZE = 10GB,
    FILEGROWTH = 100MB);


Database snapshots
----------------

You can create a database snapshot by using `CREATE DATABASE` command:

    create database ordersdb_snapshot
        on (name='ordersdb',
            filename = 'C:\Program Files\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\DATA\ordersdb_snapshot.mdf'
        ) as snapshot of ordersdb

Under the hood snapshots profit from sparse files which are available in NTFS file system. Anytime a change is made to the origin database, a copy of the updated page is created in snapshot keeping the old data.

We can also revert the origin database state to a state represented by a snapshot:

    restore database ordersdb
        from database_snapshot = 'ordersdb_snapshot';

Finally we can drop the database snapshot using `DROP DATABASE` statement:

    DROP DATABASE ordersdb_snapshot;

Query database logical information
-------------------------------

### Rename a database ###

    ALTER DATABASE [Statistics] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;

    Alter database [Statistics] modify name = TestDb

    ALTER DATABASE [TestDb] SET multi_user;

### DATABASEPROPERTY(EX) ###

The allowed properties are listed in SQL Books Online. Some interesting ones include

- Collation
- IsAutoUpdateStatistics
- IsFulltextEnabled
- IsAutoShrink
- Status (`ONLINE, OFFLINE, RESTORING, RECOVERING, SUSPECT, EMERGENCY`)
- Updateability (`READ_ONLY, READ_WRITE`)
- UserAccess (`SINGLE_USER, RESTRICTED_USER, MULTI_USER`)

Example queries:

    select DATABASEPROPERTY('Performance', 'IsAutoUpdateStatistics')
    1

### sys.databases ###

Global view for all the databases and information about their statuses.

    select * from sys.databases

### sp\_msforeachdb ###

This stored procedure allows you to run a particular query across all database. For instance the following query will search all databases for a table named AspSqlSessions:

    sp_msforeachdb 'select "?" AS db, * from [?].sys.tables where name like ''AspSqlSessions'''

### sp\_helpdb ###

This stored procedure returns information about a database and its transaction log, eg:

    sp_helpdb ordersdb

Query database physical information
-------------------------------

### Database files ###

SQL Server allows the following three types of database files:

- **primary data files** - Every database has one primary data file that keeps track of all the rest of the files in the database, in addition to storing data. By convention, a primary data file has the extension .mdf.
- **secondary data files** - A database can have zero or more secondary data files. By convention, a secondary data file has the extension .ndf.
- **log files** - Every database has at least one log file that contains the information necessary to recover all transactions in a database. By convention, a log file has the extension .ldf.

In addition, SQL Server 2008 databases can have filestream data files and full-text data files. Each database file has five properties that can be specified when you create the file: a logical filename, a physical filename, an initial size, a maximum size, and a growth increment. The value of these properties, along with other information about each file, can be seen through the metadata view `sys.database_files`, which contains one row for each file used by the current database:

    select * from sys.databases_files

To query all database files use `sys.master_files` view:

    select * from sys.master_files

### Space used by a database ###

The below queries return space usage information for each file in the current database:

    SELECT
        a.file_id ,
        CONVERT(DECIMAL(12,2),ROUND(a.size/128.000,2)) AS [file_size_mb],
        CONVERT(DECIMAL(12,2),ROUND(FILEPROPERTY(a.name,'SpaceUsed')/128.000,2)) AS [space_used_mb] ,
        CONVERT(DECIMAL(12,2),ROUND((a.size-FILEPROPERTY(a.name,'SpaceUsed'))/128.000,2)) AS [free_space_mb],
        name,
        a.physical_name
    FROM
        sys.database_files a

    SELECT DB_NAME(database_id) AS DatabaseName, Name AS Logical_Name, Physical_Name, (size*8)/1024 SizeMB FROM sys.master_files

    -- datailed information
    select * from sys.dm_db_file_space_usage

    sys.dm_io_virtual_file_stats ({ database_id | NULL }, { file_id | NULL })

Show database size using the **sp_helpdb** procedure:

    sp_helpdb [ [ @dbname= ] 'name' ]

Example with name:

    sp_helpdb 'testdb'

### Shrink the database ###

You can shrink a database manually using one of the following DBCC commands:

    DBCC SHRINKFILE ( {file_name | file_id }
    [, target_size][, {EMPTYFILE | NOTRUNCATE | TRUNCATEONLY} ]  )

    DBCC SHRINKDATABASE (database_name [, target_percent]
    [, {NOTRUNCATE | TRUNCATEONLY} ]  )

`DBCC SHRINKDATABASE` shrinks all files in a database but does not allow any file to be shrunk smaller than its minimum size. Shrinking a database or any data files is a resource-intensive operation. If you absolutely need to recover disk space from the database, you should plan the shrink operation carefully and perform it when it has the least impact on the rest of the system.
