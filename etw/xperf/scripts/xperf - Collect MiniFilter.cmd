@echo off
echo Press a key when ready to start...
pause
echo .
echo ...Capturing...
echo .

xperf -on PROC_THREAD+LOADER+FLT_IO_INIT+FLT_IO+FLT_FASTIO+FLT_IO_FAILURE+FILENAME -stackwalk MiniFilterPreOpInit+MiniFilterPostOpInit -BufferSize 1024 -MinBuffers 256 -MaxBuffers 256 -MaxFile 256 -FileMode Circular

echo Press a key when you want to stop...
pause
echo .
echo ...Stopping...
echo .

xperf -stop -d minifilter.etl
