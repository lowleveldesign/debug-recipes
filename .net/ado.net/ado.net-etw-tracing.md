
ADO.NET ETW Tracing
===================

You may also read my blog post dedicated to this subject: [Diagnosing ADO.NET with ETW traces](https://lowleveldesign.wordpress.com/2012/09/07/diagnosing-ado-net-with-etw-traces/)

Setup ADO.NET tracing
---------------------

Based on <http://msdn.microsoft.com/en-us/library/cc765421.aspx>

### Enable tracing in the registry ###

We need to add new values to the `HKEY_LOCAL_MACHINE\Software\Microsoft\BidInterface\Loader` and in case of x64 architecture also `HKEY_LOCAL_MACHINE\software\Wow6432Node\Microsoft\BidInterface\Loader` to be able to trace 32-bit applications. Bid comes from *Built-in Diagnostics (BID)*. The value should point to the valid `AdoNetDiag.dll` path on the system, ex.

    [HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\BidInterface\Loader]
    ":Path"="C:\\Windows\\Microsoft.NET\\Framework64\\v4.0.30319\\AdoNetDiag.dll"

You can filter which applications will be traced by replacing `:Path` with a path to the application executable. You can also configure an entire directory to be traceable by using the path name and the * wildcard. If there is a path you can restrict applications or applications in a specific directory from being traced by adding a REG_SZ entry with their path and a single colon (:) as the value. For example following configuration will restrict all SQL Server application from being traced:

    [HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\BidInterface\Loader]
    ":Path"="C:\\Windows\\Microsoft.NET\\Framework64\\v4.0.30319\\AdoNetDiag.dll"
    "c:\\Program Files\\Microsoft SQL Server\\MSSQL10_50.SQLEXPRESS\\MSSQL\\Binn\\*"=":"

### Register the WMI schemas (MOF) ###

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

Collecting ADO.NET Tracing
--------------------------

### Available providers ###

- `{7ACDCAC8-8947-F88A-E51A-24018F5129EF}` - `Bid2Etw_ADONETDIAG_ETW`
- `{914ABDE2-171E-C600-3348-C514171DE148}` - `Bid2Etw_System_Data_1`
- `{A68D8BB7-4F92-9A7A-D50B-CEC0F44C4808}` - `Bid2Etw_System_Data_Entity_1`
- `{C9996FA5-C06F-F20C-8A20-69B3BA392315}` - `Bid2Etw_System_Data_SNI_1` (SQL Server Networking Interface)
- `{DCD90923-4953-20C2-8708-01976FB15287}` - `Bid2Etw_System_Data_OracleClient_1`

### Starting the trace session ###

To start collecting trace events from all the ADO.NET providers run the following command:

    logman start adonettrace -pf ctrl.guid.adonet -ct perf -o out.etl -ets

And stop it with the command:

    logman stop adonettrace -ets

You can control which events are collected by specifing control bits and control values fields. You first specify the control bits:

    0x00000002 Regular tracepoints
    0x00000004 Execution flow (function enter/leave)
    0x00000080 Advanced Output

and then control bits which depend on the chosen event provider.

### Reading trace files ###

Each line of the trace can be decoded as follows:

    <namespace_ abbreviation.classname.methodname|keyword> parms

For instance: `"enter_01 <sc.SqlConnection.Close|API> 1# "` means that there is an **API** call to the **Close** method of `System.Data.SqlClient` class. The number followed by a pound sign (1#) after the parameter number serves to identify the specific instance of the DbConnectionBase object; this is helpful when you are working with a complex trace and watching many instances.

#### Namespace shortcuts ####

Description|Abbreviation|Namespace
-----------|------------|---------
SqlClient managed provider|sc|System.Data.SqlClient
OleDb managed provider|oledb|System.Data.OleDb
Odbc managed provider|odbc|System.Data.Odbc
Oracle managed provider|ora|System.Data.OracleClient
DataSet/DataTable/Data|ds|System.Data
Common code|comn|System.Data.Common
Provider base implementation classes|prov|System.Data.ProviderBase

#### Event categories ####

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

