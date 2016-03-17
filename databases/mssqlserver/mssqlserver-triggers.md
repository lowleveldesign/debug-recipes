
MS SQL Server - triggers
========================

Recursive triggers
------------------

If in our trigger we modify another table that also has a trigger assigned, the other trigger by default will not fire. In order to enable **nested triggers** we need to reconfigure SQL Server instance:

    sp_configure 'nested triggers', 1
    go
    reconfigure
    go

This might cause indirect recursive triggers. Direct recursive calls are configured on a database level using **'recursive trigger'**:

    alter database SecretRanks set RECURSIVE_TRIGGERS OFF

and check the configuration using:

    select databasepropertyex('TestDb', 'IsRecursiveTriggersEnabled')

Disable trigger in specific session
-----------------------------------

Based on <http://www.mssqltips.com/sqlservertip/1591/disabling-a-trigger-for-a-specific-sql-statement-or-session/>

### Using temporary table ###

    USE AdventureWorks;
    GO
    -- creating the table in AdventureWorks database
    IF OBJECT_ID('dbo.Table1') IS NOT NULL
    DROP TABLE dbo.Table1
    GO
    CREATE TABLE dbo.Table1(ID INT)
    GO
    -- Creating a trigger
    CREATE TRIGGER TR_Test ON dbo.Table1 FOR INSERT,UPDATE,DELETE
    AS
    IF OBJECT_ID('tempdb..#Disable') IS NOT NULL RETURN
    PRINT 'Trigger Executed'
    -- Actual code goes here
    -- For simplicity, I did not include any code
    GO

And example session code:

    CREATE TABLE #Disable(ID INT)
    -- Actual statement
    INSERT dbo.Table1 VALUES(600)
    DROP TABLE #Disable

### Using session context info ###

    USE AdventureWorks;
    GO
    -- creating the table in AdventureWorks database
    IF OBJECT_ID('dbo.Table1') IS NOT NULL
    DROP TABLE dbo.Table1
    GO
    CREATE TABLE dbo.Table1(ID INT)
    GO
    -- Creating a trigger
    CREATE TRIGGER TR_Test ON dbo.Table1 FOR INSERT,UPDATE,DELETE
    AS
    DECLARE @Cinfo VARBINARY(128)
    SELECT @Cinfo = Context_Info()
    IF @Cinfo = 0x55555
    RETURN
    PRINT 'Trigger Executed'
    -- Actual code goes here
    -- For simplicity, I did not include any code
    GO

And example session code:

    SET Context_Info 0x55555
    INSERT dbo.Table1 VALUES(100)

