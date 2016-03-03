@echo off
echo Press a key when ready to start...
pause
echo .
echo ...Capturing...
echo .

logman start iiss -pf ctrl-aspnet-iis6.guids -ct perf -o iiss.etl -bs 64 -nb 200 400 -ets

echo Press a key when you want to stop...
pause
echo .
echo ...Stopping...
echo .

logman stop iiss -ets

echo .
echo ...Create text logs...
echo .

tracerpt -y iiss.etl -o iiss.csv -summary iiss-summary.txt

