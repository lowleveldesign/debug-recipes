
HTTP Server API (HTTP.SYS) error logging
========================================

Configuration
-------------

Based on: <http://support.microsoft.com/?id=820729>

All logging configuration is stored under the key: `HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\HTTP\Parameters`. In order to apply the settings you need to restart the HTTP driver:

    net stop http
    net start http

Log files are named using the following convention: 1`httperr + sequence number + .log`, eg. httperr4.log. The following parameters configure how the logs will be created:

- `EnableErrorLogging` - A DWORD that controls if logging is enabled (1 - enabled)
- `ErrorLogFileTruncateSize` - A DWORD that specified the maximum size of an error log file, in bytes. The value can't be less than the default one 1MB (0x100000)
- `ErrorLoggingDir` - A STRING that specifies the folder where the HTTP API puts its logging files. The HTTP API creates then a subfolder `HTTPERR` and there stores the error log files. The default path is `%SystemRoot%\System32\LogFiles\HTTPERR`

### Commands ###

    reg add HKLM\System\CurrentControlSet\Services\HTTP\Parameters /v EnableErrorLogging /t REG_DWORD /d 0x1

To disable log buffering (IIS6 - do not use it on production):

    reg add HKLM\System\CurrentControlSet\Services\HTTP\Parameters /v DisableLogBuffering /t REG_DWORD /d 0x1

Log format
----------

Generally, HTTP API error log files have the same format as W3C error logs, except that HTTP API error log files do not contain column headings. Each line of an HTTP API error log records one error. The fields appear in a specific order. A single space character (0x0020) separates each field from the previous field. In each field, plus signs (0x002B) replace space characters, tabs, and nonprintable control characters. Fields in order of appearing:

- `Date` (UTC)
- `Time` (UTC)
- `Client IP Address`
- `Client Port`
- `Server IP Address`
- `Server Port`
- `Protocol Version`
- `Verb`
- `CookedURL+Query`
- `Protocol Status`
- `SiteId`
- `Reason Phrase` (the type of error that is being logged)
- `Queue Name` (the request queue name)

Guidlines and usage samples
---------------------------

### Flushing requests log (IIS7) ###

Because of perfomance reasons HTTP.SYS buffers log messages before writing them to disk. This causes some delay between the moment that the request came and the moment when it was actually logged. To force HTTP.SYS to flush all its log buffers you may issue following command:

    netsh http flush logbuffer

based on <http://blogs.msdn.com/b/amb/archive/2011/12/06/why-does-not-iis-log-requests-immediately.aspx>

Links
-----

- [Properties available in the log file](http://support.microsoft.com/kb/832975)
- [Using HTTP ETW tracing to troubleshoot HTTP issues](https://blogs.msdn.microsoft.com/benjaminperkins/2014/03/10/using-http-etw-tracing-to-troubleshoot-http-issues/)
