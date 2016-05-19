@echo off
echo Press a key when ready to start...
pause
echo .
echo ...Capturing...
echo .

netsh trace start capture=yes overwrite=yes maxsize=500 tracefile=c:\com_rpc.etl provider="Microsoft-Windows-RPC" keywords=0xffffffffffffffff level=0xff provider="Microsoft-Windows-RPC-Events" keywords=0xffffffffffffffff level=0xff provider="Microsoft-Windows-RPCSS" keywords=0xffffffffffffffff level=0xff

echo Press a key when you want to stop...
pause
echo .
echo ...Stopping...
echo .

netsh trace stop




