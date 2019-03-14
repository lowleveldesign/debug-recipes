## Windows Kernel Debugging (TCP)

When debugging a Gen 2 VM remember to turn off the secure booting: 
**Set-VMFirmware -VMName "Windows 2012 R2" -EnableSecureBoot Off -Confirm**

C:\Windows\system32>**bcdedit /dbgsettings NET HOSTIP:172.25.121.1 PORT:60000**
Key=3ma3qyz02ptls.23uxbvnd0e2zh.1gnwiqb6v3mpb.mjltos9cf63x

C:\Windows\system32>**bcdedit /debug {current} on**
The operation completed successfully.

Starting from Debugging Tools for Windows 10 we have an additional tool: **kdnet.exe**. By running it on the guest you may see if your network card supports kernel debugging and get the instructions for the host machine: 

```
C:\tools\x64>kdnet 172.25.121.1 60000

Enabling network debugging on Microsoft Hypervisor Virtual Machine.
Key=1a88vu15z4lta.8q4ler06jr8v.1fv4h88r9e0ob.1139s57nv8obj

To finish setting up KDNET for this VM, run the following command from an
elevated command prompt running on the Windows hyper-v host.  (NOT this VM!)
powershell -ExecutionPolicy Bypass kdnetdebugvm.ps1 -vmguid DD4F4AFE-9B5F-49AD-8
775-20863740C942 -port 60000

To debug this vm, run the following command on your debugger host machine.
windbg -k net:port=60000,key=1a88vu15z4lta.8q4ler06jr8v.1fv4h88r9e0ob.1139s57nv8
obj,target=DELAPTOP

Then make sure to SHUTDOWN (not restart) the VM so that the new settings will
take effect.  Run shutdown -s -t 0 from this command prompt.
```