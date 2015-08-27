
Setup Windows kernel debugging
------------------------------

In order to debug windows kernel you need to configure the `/debug` option during a system boot. You can do this etiher using **msconfig.exe** (Boot -> Advanced Options...) or using **bcdedit.exe** (`bcdedit /debug '{current}' on`).

### Configure LAN debugging ###

Supported in Windows 8 up.

    C:\Windows\system32>bcdedit /dbgsettings NET HOSTIP:192.168.1.13 PORT:60000
    Key=3ma3qyz02ptls.23uxbvnd0e2zh.1gnwiqb6v3mpb.mjltos9cf63x

    C:\Windows\system32>bcdedit /debug {current} on
    The operation completed successfully.

Starting from Debugging Tools for Windows 10 we have an additional tool: **kdnet.exe**. By running it on the guest you may see if your network card supports kernel debugging. You may later enable them by using: `kdnet 192.168.0.1 50000`. This should return an encryption key used later when connecting from the remote windbg.

### Configure Serial port debugging ###

    C:\Windows\system32>bcdedit /debug {current} on
    The operation completed successfully.

    C:\Windows\system32>bcdedit /dbgsettings SERIAL DEBUGPORT:1 BAUDRATE:115200
    The operation completed successfully.

### Local kernel debugging ###

To start a local kernel debugging you may run from the elevated command prompt either:

    kd -kl
    windbg -kl
    livekd (sysinternals)

Setup kernel debugging on virtual machine
-----------------------------------------

### Using VMWare to debug kernel ###

You can add a serial port to a VMWare machine - then check to which port (COM1, COM2) was it assigned in the virtual machine (using for instance Device Manager in guest). Next step is to enable debugging through this serial port (using msconfig for instance).

On the client computer you can connect to the VM using windbg by using a given named pipe:

    windbg -k com:pipe,port=\\.\pipe\PipeName,resets=0,reconnect
    windbg -k com:pipe,port=\\VMHost\pipe\PipeName,resets=0,reconnect (if the VM is running on another machine then the debugger)

In virtualbox remember to always specify the whole path to the named pipe, eg. `\\.\pipe\dbgpipe`.

### Using Hyper-V to debug kernel ###

Enable COM1 debug port configuration.

Add COM1 serial port emulated by a named pipe.

On the host computer you can connect to the VM using windbg by using a given named pipe:

    windbg -k com:pipe,port=\\.\pipe\PipeName,resets=0,reconnect

