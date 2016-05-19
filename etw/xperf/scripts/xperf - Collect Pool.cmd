@echo off
echo Press a key when ready to start...
pause
echo .
echo ...Capturing...
echo .

Xperf -on PROC_THREAD+LOADER+POOL -stackwalk PoolAlloc+PoolFree+PoolAllocSession+PoolFreeSession -BufferSize 1024 -MinBuffers 256 -MaxBuffers 256 -MaxFile 256 -FileMode Circular

echo Press a key when you want to stop...
pause
echo .
echo ...Stopping...
echo .

xperf -stop -d result.etl
