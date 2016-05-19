@echo off
echo Press a key when ready to start...
pause
echo .
echo ...Capturing...
echo .

xperf -on PROC_THREAD+LOADER+FILENAME+FILE_IO+FILE_IO_INIT -stackwalk FileCreate+FileCleanup+FileClose+FileRead+FileWrite -BufferSize 1024 -MinBuffers 256 -MaxBuffers 256 -MaxFile 256 -FileMode Circular


echo Press a key when you want to stop...
pause
echo .
echo ...Stopping...
echo .

xperf -stop -d fileio.etl
