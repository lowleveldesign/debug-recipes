
*This is work in progress*

.NET Framework contains many internal static classes exposing Win32 API methods. We can access them from PowerShell. For example, 
to call `DestroyWindow`, we could use the following commands:

```powershell
$hwnd = New-Object System.Runtime.InteropServices.HandleRef @($null, 0x123) 
$win32 = [System.Uri].Assembly.GetType('Microsoft.Win32.UnsafeNativeMethods')
$win32::DestroyWindow($hwnd)
```

A more complicated scenario when I create a Windows hook (FIXME: test):

```powershell
Add-Type -AssemblyName System.Windows.Forms
$user32 = [Windows.Forms.Form].Assembly.GetType('System.Windows.Forms.UnsafeNativeMethods')

$natives = Add-Type -TypeDefinition @'
using System;
using System.Drawing;

public struct MSLLHOOKSTRUCT {
  public Point pt;
  public uint mouseData;
  public uint flags;
  public uint time;
  public UIntPtr dwExtraInfo;
}
'@

$hook = {
    param([int]$nCode, [IntPtr]$wParam, [IntPtr]$lParam)

    Write-Host $nCode

    if ($nCode -lt 0) {
        $user32::CallNextHookEx([IntPtr]::Zero, $nCode, $wParam, $lParam)
    }
}

$href = New-Object System.Runtime.InteropServices.HandleRef $null, $user32::GetModuleHandle($null)
$user32::SetWindowsHookEx(14, $hook, $href, 0)

$hhook = [IntPtr]599917967
$user32::UnhookWindowsHookEx($(New-Object System.Runtime.InteropServices.HandleRef $null, $hhook))

using namespace System.Runtime.InteropServices
$s = New-Object MSLLHOOKSTRUCT
$hmem = [Marshal]::AllocHGlobal([Marshal]::SizeOf($s))
[Marshal]::StructureToPtr($s, $hmem, $false)

$m = [Marshal].GetMethods() | ? { $_.Name -eq "PtrToStructure" -and $_.IsGenericMethod -and $_.ReturnType -ne [Void] }
$m = $m.MakeGenericMethod([MSLLHOOKSTRUCT])

$m.Invoke($null, $hmem)
```

Static classes with unsafe methods:

- FIXME: links to https://referencesource.microsoft.com

