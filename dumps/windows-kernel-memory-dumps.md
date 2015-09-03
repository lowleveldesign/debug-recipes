
Generating Windows kernel memory dumps
======================================

Generate the kernel memory dump on keypress
-------------------------------------------

Based on <https://msdn.microsoft.com/en-us/library/windows/hardware/ff545499(v=vs.85).aspx>

Add **CrashOnCtrlScroll** `REG_DWORD` set to 1 to:

- `HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\i8042prt\Parameters` for PS/2 keyboards
- `HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\kbdhid\Parameters` for USB keyboards

To generate a dump hold down the rightmost CTRL and press the SCROLL LOCK twice.

Links
-----

- [How to Force a Diagnostic Memory Dump When a Computer Hangs](http://blogs.technet.com/b/askpfeplat/archive/2015/04/06/how-to-force-a-diagnostic-memory-dump-when-a-computer-hangs.aspx)
