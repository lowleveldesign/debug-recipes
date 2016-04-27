
Troubleshooting ADO.NET
=======================

Table of contents:

- [ADO.NET ETW Tracing](#etw)
- [ADO.NET in a debugger](#debug)

## <a name="etw">ADO.NET ETW Tracing</a>

### Setup ADO.NET tracing

Based on <http://msdn.microsoft.com/en-us/library/cc765421.aspx>

#### Enable tracing in the registry ###

We need to add new values to the `HKEY_LOCAL_MACHINE\Software\Microsoft\BidInterface\Loader` and in case of x64 architecture also `HKEY_LOCAL_MACHINE\software\Wow6432Node\Microsoft\BidInterface\Loader` to be able to trace 32-bit applications. Bid comes from *Built-in Diagnostics (BID)*. The value should point to the valid `AdoNetDiag.dll` path on the system, ex.

    [HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\BidInterface\Loader]
    ":Path"="C:\\Windows\\Microsoft.NET\\Framework64\\v4.0.30319\\AdoNetDiag.dll"

You can filter which applications will be traced by replacing `:Path` with a path to the application executable. You can also configure an entire directory to be traceable by using the path name and the * wildcard. If there is a path you can restrict applications or applications in a specific directory from being traced by adding a REG_SZ entry with their path and a single colon (:) as the value. For example following configuration will restrict all SQL Server application from being traced:

    [HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\BidInterface\Loader]
    ":Path"="C:\\Windows\\Microsoft.NET\\Framework64\\v4.0.30319\\AdoNetDiag.dll"
    "c:\\Program Files\\Microsoft SQL Server\\MSSQL10_50.SQLEXPRESS\\MSSQL\\Binn\\*"=":"

#### Register the WMI schemas (MOF) ###

In order to use the profiling adapter you need to register the ETW providers and their WMI schemas for the events that the BID adapter exposes. You can do this using the `mofcomp.exe` tool. ADO.NET provides the MOF file in the .NET Framework directory:

    c:\Windows\Microsoft.NET\Framework64\v4.0.30319>mofcomp adonetdiag.mof

    Microsoft (R) MOF Compiler Version 6.1.7600.16385
    Copyright (c) Microsoft Corp. 1997-2006. All rights reserved.
    Parsing MOF file: adonetdiag.mof
    MOF file has been successfully parsed
    Storing data in the repository...
    WARNING: File adonetdiag.mof does not contain #PRAGMA AUTORECOVER.
    If the WMI repository is rebuilt in the future, the contents of this MOF file will not be included in the new WMI repository.
    To include this MOF file when the WMI Repository is automatically reconstructed, place the #PRAGMA AUTORECOVER statement on the first line of the MOF file.
    Done!

### Collecting ADO.NET Tracing

Available providers:

- `{7ACDCAC8-8947-F88A-E51A-24018F5129EF}` - `Bid2Etw_ADONETDIAG_ETW`
- `{914ABDE2-171E-C600-3348-C514171DE148}` - `Bid2Etw_System_Data_1`
- `{A68D8BB7-4F92-9A7A-D50B-CEC0F44C4808}` - `Bid2Etw_System_Data_Entity_1`
- `{C9996FA5-C06F-F20C-8A20-69B3BA392315}` - `Bid2Etw_System_Data_SNI_1` (SQL Server Networking Interface)
- `{DCD90923-4953-20C2-8708-01976FB15287}` - `Bid2Etw_System_Data_OracleClient_1`

#### Starting the trace session

To start collecting trace events from all the ADO.NET providers run the following command:

    logman start adonettrace -pf ctrl.guid.adonet -ct perf -o out.etl -ets

And stop it with the command:

    logman stop adonettrace -ets

You can control which events are collected by specifing control bits and control values fields. You first specify the control bits:

    0x00000002 Regular tracepoints
    0x00000004 Execution flow (function enter/leave)
    0x00000080 Advanced Output

and then control bits which depend on the chosen event provider.

#### Reading trace files

Each line of the trace can be decoded as follows:

    <namespace_ abbreviation.classname.methodname|keyword> parms

For instance: `"enter_01 <sc.SqlConnection.Close|API> 1# "` means that there is an **API** call to the **Close** method of `System.Data.SqlClient` class. The number followed by a pound sign (1#) after the parameter number serves to identify the specific instance of the DbConnectionBase object; this is helpful when you are working with a complex trace and watching many instances.

Namespace shortcuts:

Description|Abbreviation|Namespace
-----------|------------|---------
SqlClient managed provider|sc|System.Data.SqlClient
OleDb managed provider|oledb|System.Data.OleDb
Odbc managed provider|odbc|System.Data.Odbc
Oracle managed provider|ora|System.Data.OracleClient
DataSet/DataTable/Data|ds|System.Data
Common code|comn|System.Data.Common
Provider base implementation classes|prov|System.Data.ProviderBase

Event categories:

Keyword|Category
-------|--------
API|Public API (method, property) is called
OLEDB|Code calls OLEDB component
ODBC|Code calls ODBC API
SNI|Code calls SNI
ERR|Error
WARN|Warning
INFO|Information
RET|Return value, usually in the form of API|RET
THROW|An new exception is being thrown (not applicable to exceptions being re-thrown)
CATCH|Code catches an exception
CPOOL|Connection pool activities
ADV|Advanced trace points

## <a name="debug">Debugging ADO.NET</a>

### Getting information about connections from a dump

Based on: <http://blogs.msdn.com/b/spike/archive/2012/05/21/quot-system-invalidoperationexception-timeout-expired-the-timeout-period-elapsed-prior-to-obtaining-a-connection-from-the-pool-quot.aspx>

To list all connections in the dump:

    0:000> !dumpheap -type System.Data.SqlClient.SqlConnection
             Address               MT     Size
    0000000002d8dfb8 000007fee36532a8       64
    0000000002db0360 000007fee36542b8      184
    …
    00000000030e7928 000007fee364fba8      104

Pick one connection:

    0:000> !do 00000000030e7928
    Name:        System.Data.SqlClient.SqlConnection
    MethodTable: 000007fee364fba8
    EEClass:     000007fee34d1c38
    Size:        104(0x68) bytes
    File:        C:\Windows\Microsoft.Net\assembly\GAC_64\System.Data\v4.0_4.0.0.0__b77a5c561934e089\System.Data.dll
    Fields:
                  MT    Field   Offset                 Type VT     Attr            Value Name
    …
    000007fee36543a8  4001775       38 ...ConnectionOptions  0 instance 0000000002db0360 _userConnectionOptions
    000007fee3653700  4001776       40 ...nnectionPoolGroup  0 instance 0000000002db0bb0 _poolGroup
    …

Dump its connection string information:

    0:000> !do 0000000002db0360
    Name:        System.Data.SqlClient.SqlConnectionString
    MethodTable: 000007fee36542b8
    EEClass:     000007fee34f53b0
    Size:        184(0xb8) bytes
    File:        C:\Windows\Microsoft.Net\assembly\GAC_64\System.Data\v4.0_4.0.0.0__b77a5c561934e089\System.Data.dll
    Fields:
                  MT    Field   Offset                 Type VT     Attr            Value Name
    000007fee5e96728  4000c17        8        System.String  0 instance 0000000002d8de10 _usersConnectionString
    …

And finally the raw connection string:

    0:000> !do 0000000002d8de10
    Name:        System.String
    MethodTable: 000007fee5e96728
    EEClass:     000007fee5a1ed68
    Size:        256(0x100) bytes
    File:        C:\Windows\Microsoft.Net\assembly\GAC_64\mscorlib\v4.0_4.0.0.0__b77a5c561934e089\mscorlib.dll
    String:      Data Source=<server>;Initial Catalog=<database>;Integrated Security=True; Max Pool Size=20; Connection Timeout=10


### Getting information about connection pools from a dump

Based on: <http://blogs.msdn.com/b/spike/archive/2012/05/21/quot-system-invalidoperationexception-timeout-expired-the-timeout-period-elapsed-prior-to-obtaining-a-connection-from-the-pool-quot.aspx>

Anytime you experience:

    "System.InvalidOperationException: Timeout expired. The timeout period elapsed prior to obtaining a connection from the pool."

You can take a dump of the faulty application and run following commands in Windbg to diagnose the state of the connection pool:

    0:000> !dumpheap -stat -type System.Data.ProviderBase.DbConnectionPool
    total 0 objects
    Statistics:
                  MT    Count    TotalSize Class Name
    …
    000007fee3653dc0        1          176 System.Data.ProviderBase.DbConnectionPool
    0:000> !dumpheap -mt 000007fee3653dc0
             Address               MT     Size
    0000000002db24c0 000007fee3653dc0      176

Dump the connection pool properties:

    0:000> !do 0000000002db24c0
    Name:        System.Data.ProviderBase.DbConnectionPool
    MethodTable: 000007fee3653dc0
    EEClass:     000007fee34d26f8
    Size:        176(0xb0) bytes
    File:        C:\Windows\Microsoft.Net\assembly\GAC_64\System.Data\v4.0_4.0.0.0__b77a5c561934e089\System.Data.dll
    Fields:
                  MT    Field   Offset                 Type VT     Attr            Value Name
    000007fee5e9c610  4001579       88         System.Int32  1 instance           190000 _cleanupWait
    000007fee3652e80  400157a        8 ...ctionPoolIdentity  0 instance 0000000002db24a0 _identity
    000007fee36535f0  400157b       10 ...ConnectionFactory  0 instance 0000000002d8dfb8 _connectionFactory
    000007fee3653700  400157c       18 ...nnectionPoolGroup  0 instance 0000000002db0bb0 _connectionPoolGroup
    000007fee36546d0  400157d       20 ...nPoolGroupOptions  0 instance 0000000002db0b88 _connectionPoolGroupOptions
    000007fee3b82610  400157e       28 ...nPoolProviderInfo  0 instance 0000000000000000 _connectionPoolProviderInfo
    …
    000007fee5e9c610  400158e       98         System.Int32  1 instance               20 _totalObjects

And pool options:

    0:000> !do 0000000002db0b88
    Name:        System.Data.ProviderBase.DbConnectionPoolGroupOptions
    MethodTable: 000007fee36546d0
    EEClass:     000007fee34f5620
    Size:        40(0x28) bytes
    File:        C:\Windows\Microsoft.Net\assembly\GAC_64\System.Data\v4.0_4.0.0.0__b77a5c561934e089\System.Data.dll
    Fields:
                  MT    Field   Offset                 Type VT     Attr            Value Name
    000007fee5e9d440  40015d8       14       System.Boolean  1 instance                1 _poolByIdentity
    000007fee5e9c610  40015d9        8         System.Int32  1 instance                0 _minPoolSize
    000007fee5e9c610  40015da        c         System.Int32  1 instance               20 _maxPoolSize

### List all recently ran SQL commands

The below command will list all the SQL commands associated with `SqlCommand` instances on the stack:

    .foreach (addr {!DumpHeap -type System.Data.SqlClient.SqlCommand -short}) { r$t1 = poi( addr + 0x10); !do @$t1 }

Example output:

    ...
    Name:        System.String
    MethodTable: 7358224c
    EEClass:     731b3444
    Size:        750(0x2ee) bytes
    File:        C:\Windows\Microsoft.Net\assembly\GAC_32\mscorlib\v4.0_4.0.0.0__b77a5c561934e089\mscorlib.dll
    String:      SELECT
        [Extent1].[EntityName] AS [EntityName],
        [Extent1].[LastProcessingDate] AS [LastProcessingDate],
        [Extent1].[LastProcessedItemModifyDate] AS [LastProcessedItemModifyDate],
        [Extent1].[LastProcessedItemId] AS [LastProcessedItemId],
        [Extent1].[IsMigrationFinished] AS [IsMigrationFinished]
        FROM [dbo].[SyncStatus] AS [Extent1]
    Fields:
          MT    Field   Offset                 Type VT     Attr    Value Name
    73583aa8  40000aa        4         System.Int32  1 instance      368 m_stringLength
    73582c44  40000ab        8          System.Char  1 instance       53 m_firstChar
    7358224c  40000ac        c        System.String  0   shared   static Empty
        >> Domain:Value  00571188:NotInit  <<
    Name:        System.String
    MethodTable: 7358224c
    EEClass:     731b3444
    Size:        678(0x2a6) bytes
    File:        C:\Windows\Microsoft.Net\assembly\GAC_32\mscorlib\v4.0_4.0.0.0__b77a5c561934e089\mscorlib.dll
    String:      SELECT TOP (100)
        [Extent1].[Id] AS [Id],
        [Extent1].[InsertionDateUtc] AS [InsertionDateUtc],
        [Extent1].[Entity] AS [Entity],
        [Extent1].[EntityKeyPart1] AS [EntityKeyPart1],
        [Extent1].[EntityKeyPart2] AS [EntityKeyPart2]
        FROM [dbo].[ItemsToResync] AS [Extent1]
        ORDER BY [Extent1].[Id] ASC
    Fields:
          MT    Field   Offset                 Type VT     Attr    Value Name
    73583aa8  40000aa        4         System.Int32  1 instance      332 m_stringLength
    73582c44  40000ab        8          System.Char  1 instance       53 m_firstChar
    7358224c  40000ac        c        System.String  0   shared   static Empty
        >> Domain:Value  00571188:NotInit  <<
    ...

