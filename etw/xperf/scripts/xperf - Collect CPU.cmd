@echo off
echo Press a key when ready to start...
pause
echo .
echo ...Capturing...
echo .

xperf -on PROC_THREAD+LOADER+PROFILE+INTERRUPT+DPC+DISPATCHER -stackwalk Profile -BufferSize 1024 -MinBuffers 256 -MaxBuffers 256 -MaxFile 256 -FileMode Circular

echo Press a key when you want to stop...
pause
echo .
echo ...Stopping...
echo .

xperf -stop -d cpu.etl
