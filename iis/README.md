
IIS Troubleshooting
===================

The notes are divided based on the IIS versions:

- [IIS6](iis6.md)
- [IIS7up](iis7up.md)
- [IIS Express](iisexpress.md)

In the notes folder you may also find scripts to collect ETW traces from IIS server and [WMI API description](wmi/iis-wmi.md).

### Powershell module ###

Also in this folder you may find my **Powershell LLDIIS module** which contains following methods:

```powershell
Get-HttpSysLog [[-ComputerName] <string>] [[-Newest] <int>]

Get-IISLog [[-ComputerName] <string>] [-ApplicationName] <string> [[-Newest] <int>] [[-HttpStatus] <int>]
    [<CommonParameters>]

Get-IISWmiObject [[-ComputerName] <string>] [[-Class] <string>] [[-Filter] <string>] [[-Query] <string>]
    [[-Credential] <pscredential>]

Get-VDirByPath [[-ComputerName] <string>] [-Path] <string>  [<CommonParameters>]

New-WebSiteFromConfigurationFile [[-ComputerName] <string>] [-ConfigFile] <string> [[-NewWebsiteId] <string>]
        [-ServerBinding] <string> [-ApplicationName] <string> [-AppPoolId] <string>  [<CommonParameters>]

Restart-IISAppPool
```

