
MySql .NET connector
====================

Replication
-----------

If we specify more than one host in the connection string, the connector will randomly pick connections

.NET Connector Tracing
----------------------

There is a special trace source name `mysql` that you can use to save traces from the MySql .net connector:

    ..
    <system.diagnostics>
      <trace autoflush="true" />
      <sharedListeners>
        <add name="weblistener" type="System.Web.WebPageTraceListener, System.Web, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a" />
      </sharedListeners>
      <sources>
        <source name="mysql" switchValue="Verbose">
          <listeners>
            <add name="weblistener" />
          </listeners>
        </source>
      </sources>
    </system.diagnostics>

    <system.web>
      <trace enabled="true" requestLimit="100" mostRecent="true" />
      ...
    </system.web>
    ...

To enable logging you also need to add `logging=true` to the connection string, eg.:

    string connStr = "server=localhost;user=root;database=world;port=3306;password=******;logging=true;";

Events description and details about logging configuration can be found [here](http://dev.mysql.com/doc/refman/5.5/en/connector-net-programming-tracing.html).

Example output of the trace source is presented below:

    mysql	Event 1: 1: Connection Opened: connection string = 'server=localhost;database=DiagnosticsDB;User Id=test;password=test;logging=True'
    mysql	Event 3: 1: Query Opened: SHOW VARIABLES	0,016148	0,016148
    mysql	Event 4: 1: Resultset Opened: field(s) = 2, affected rows = -1, inserted id = -1	0,020101	0,003953
    mysql	Event 5: 1: Resultset Closed. Total rows=328, skipped rows=0, size (bytes)=8267	0,035241	0,015141
    mysql	Event 6: 1: Query Closed	0,036339	0,001098
    mysql	Event 3: 1: Query Opened: SHOW COLLATION	0,037045	0,000707
    mysql	Event 4: 1: Resultset Opened: field(s) = 6, affected rows = -1, inserted id = -1	0,037647	0,000601
    mysql	Event 5: 1: Resultset Closed. Total rows=197, skipped rows=0, size (bytes)=6583	0,040191	0,002545
    mysql	Event 6: 1: Query Closed	0,040315	0,000124
    mysql	Event 3: 1: Query Opened: SET character_set_results=NULL	0,041348	0,001033
    mysql	Event 4: 1: Resultset Opened: field(s) = 0, affected rows = 0, inserted id = 0	0,041441	0,000093
    mysql	Event 5: 1: Resultset Closed. Total rows=0, skipped rows=0, size (bytes)=0	0,041515	0,000073
    mysql	Event 6: 1: Query Closed	0,041582	0,000067
    mysql	Event 10: 1: Set Database: DiagnosticsDB	0,048349	0,006768
    mysql	Event 3: 1: Query Opened: SELECT ApplicationFullName, Operation, MachineName, LastTime FROM (
       SELECT 'START' AS 'Operation', ApplicationPathHash, MachineName, MAX(eventtimeutc) AS 'LastTime' FROM aspnet_applicationlife_events
           WHERE EventCode = 1001 AND EventTimeUtc >= '2012-07-14 16:31:48.337'
           GROUP BY	0,079826	0,031477
    mysql	Event 14: 1: Query Normalized: SELECT ApplicationFullName, Operation, MachineName, LastTime FROM ( SELECT ? AS ?, ApplicationPathHash, MachineName, MAX(eventtimeutc) AS ? FROM aspnet_applicationlife_events WHERE EventCode = ? AND EventTimeUtc >= ? GROUP BY ApplicationPathHash, MachineName UNION SELECT ?, ApplicationPathHash, MachineName, MAX(eventtimeutc) FROM aspnet_applicationlife_events WHERE EventCode = ? AND EventTimeUtc >= ? GROUP BY ApplicationPathHash, MachineName UNION SELECT ?, ApplicationPathHash, MachineName, MAX(eventtimeutc) FROM aspnet_error_events WHERE EventTimeUtc >= ? GROUP BY ApplicationPathHash, MachineName UNION SELECT ?, ApplicationPathHash, MachineName, MAX(eventtimeutc) FROM aspnet_heartbeat_events WHERE EventTimeUtc >= ? GROUP BY ApplicationPathHash, MachineName ) AS t LEFT JOIN deployed_applications AS d ON d.ApplicationPathHash = t.ApplicationPathHash	0,080101	0,000275
    mysql	Event 4: 1: Resultset Opened: field(s) = 4, affected rows = -1, inserted id = -1	0,081349	0,001248
    mysql	Event 5: 1: Resultset Closed. Total rows=4, skipped rows=0, size (bytes)=139	0,095259	0,013910
    mysql	Event 6: 1: Query Closed


Events include:

    Event	Description
    1	ConnectionOpened: connection string
    2	ConnectionClosed:
    3	QueryOpened: mysql server thread id, query text
    4	ResultOpened: field count, affected rows (-1 if select), inserted id (-1 if select)
    5	ResultClosed: total rows read, rows skipped, size of resultset in bytes
    6	QueryClosed:
    7	StatementPrepared: prepared sql, statement id
    8	StatementExecuted: statement id, mysql server thread id
    9	StatementClosed: statement id
    10	NonQuery: [varies]
    11	UsageAdvisorWarning: usage advisor flag. NoIndex = 1, BadIndex = 2, SkippedRows = 3, SkippedColumns = 4, FieldConversion = 5.
    12	Warning: level, code, message
    13	Error: error number, error message
