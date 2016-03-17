
$probcnt = 0

while ($true) {

    gc "c:\temp\mysql\log-query.sql" | c:\mysql\bin\mysql.exe -u user --password=pass -h testsrv -P 3306 -b testdb | Out-File "c:\temp\mysql\output_$(get-date -format 'yyyyMMdd_hhmmss.ff').log"

    start-sleep -s 30

    if ($probcnt++ -gt 60) { break }
}
