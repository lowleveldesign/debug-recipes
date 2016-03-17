
SQL Server Configuration
========================

Sql server version
------------------

    SELECT SERVERPROPERTY('Edition');
    Express Edition with Advanced Services (64-bit)

    SELECT SERVERPROPERTY('EngineEdition');
    4

3 is Enterprise, 2 is Standard, 4 is Express

    SELECT SERVERPROPERTY('EngineId');
    NULL

You can use the `xp_msver` system procedure to return information on your SQL Server version:

    /*------------------------
    xp_msver
    ------------------------*/
    SQL Server parse and compile time:
       CPU time = 0 ms, elapsed time = 0 ms.
    Index  Name                             Internal_Value Character_Value
    ------ -------------------------------- -------------- ----------------------------------------
    1      ProductName                      NULL           Microsoft SQL Server
    2      ProductVersion                   720896         11.0.2100.60
    3      Language                         1033           English (United States)
    4      Platform                         NULL           NT x64
    5      Comments                         NULL           SQL
    6      CompanyName                      NULL           Microsoft Corporation
    7      FileDescription                  NULL           SQL Server Windows NT - 64 Bit
    8      FileVersion                      NULL           2011.0110.2100.060 ((SQL11_RTM).120210-1
    9      InternalName                     NULL           SQLSERVR
    10     LegalCopyright                   NULL           Microsoft Corp. All rights reserved.
    11     LegalTrademarks                  NULL           Microsoft SQL Server is a registered tra
    12     OriginalFilename                 NULL           SQLSERVR.EXE
    13     PrivateBuild                     NULL           NULL
    14     SpecialBuild                     137625660      NULL
    15     WindowsVersion                   602931718      6.2 (9200)
    16     ProcessorCount                   2              2
    17     ProcessorActiveMask              NULL                          3
    18     ProcessorType                    8664           NULL
    19     PhysicalMemory                   6143           6143 (6441582592)
    20     Product ID                       NULL           NULL

You can also use the `@@version` variable:

    select @@version

    Microsoft SQL Server 2008 R2 (SP1) - 10.50.2500.0 (X64)   Jun 17 2011 00:54:03   Copyright (c) Microsoft Corporation  Express Edition with Advanced Services (64-bit) on Windows NT 6.1 <X64> (Build 7601: Service Pack 1)

Configuration options
---------------------

SQL Server 2008 has 68 server configuration options that you can query using the catalog view `sys.configurations`. The server-wide options discussed here can be changed in several ways. All of them can be set via the `sp_configure` system stored procedure. However, of the 68 options, all but 16 are considered advanced options and are not manageable by default using `sp_configure`. You’ll first need to change the Show Advanced Options option to be 1, as shown here:

    EXEC sp_configure 'show advanced options', 1;
    GO
    RECONFIGURE;
    GO

After a configuration change we need to either call `RECONFIGURE [WITH OVERRRIDE]` or restart the SQL Server. When `is_dynamic` column is set to 1, the variable that takes effect when the RECONFIGURE statement is executed (otherwise server restart is required). Before taking any of the above-mentioned actions the new value appears only in the `value` column (and not yet in the `vlue_in_use_column`).

Get information about OS
------------------------

    select * from sys.dm_os_sys_info

    cpu_ticks            ms_ticks             cpu_count   cpu_ticks_in_ms      hyperthread_ratio physical_memory_in_bytes virtual_memory_in_bytes bpool_committed bpool_commit_target bpool_visible stack_size_in_bytes os_quantum           os_error_mode os_priority_class max_workers_count scheduler_count scheduler_total_count deadlock_monitor_serial_number
    -------------------- -------------------- ----------- -------------------- ----------------- ------------------------ ----------------------- --------------- ------------------- ------------- ------------------- -------------------- ------------- ----------------- ----------------- --------------- --------------------- ------------------------------
    29676598751590       2967659856           12          10000                12                51527311360              8796092891136           5767168         5767168             5767168       2093056             40000                5             32                640               12              23                    4898958

