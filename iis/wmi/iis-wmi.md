
Use WMI to administer IIS
-------------------------

### Find all stopped web applications and remove them ###

Get web sites names which are stopped:

    PS powershell> $names = Get-WmiObject -Authentication PacketPrivacy -Namespace "root/MicrosoftIISv2" -ComputerName test-server.pl -Query "select Name from IIsWebServer where ServerState = 4" | % { $_.Name }

As AppDelete does not work I needed to remotely call iisweb.vbs:

    $names | % { psexec \\test-server.pl cscript c:\windows\system32\iisweb.vbs /delete $_ }

### Find and remove pools with no applications ###

We will use apdel.vbs script:

    PS powershell> $pools = Get-WmiObject -Authentication PacketPrivacy -Namespace "root/MicrosoftIISv2" -ComputerName test-server.pl -Class IIsApplicationPool

    PS powershell> $pools | % { if ([string]::IsNullOrEmpty([string]$_.EnumAppsInPool().Applications)) { C:\tools\iis\apdel.vbs /computer:test-server.pl /apname:$($_.Name.Split('/')[2]) } }

### Add new virtual directory to an application ###

Use SiteManager.exe tool:

    > .\SiteManager.exe vdir "IIS://test-server.pl/W3SVC/166004671/Root" "MyDir" "\\test-source\ASP.NET"

### Find Virtual Directory (and application name) by a path ###

    > (Get-IISWmiObject -ComputerName test-server.pl -Class IIsWebVirtualDirSetting -Filter "Path='\\\\test-source\\zrodla\\www\\root'").Name
    W3SVC/1139376013/root

or just `Get-VDirByPath`

or just `Get-VDirByPath` from my Diagnostics module.

### Find application by its name ###

    > Get-IISWmiObject -ComputerName test-server -Class IIsWebServerSetting -Filter "ServerComment='test-app'" | Select Name

    Name
    ----
    W3SVC/1068343083

### Find application pool by its name and recycle it ###

    > $ap = Get-IISWmiObject -ComputerName test-server -Class IIsApplicationPool -Filter "Name = 'W3SVC/AppPools/Test'"
    > $ap.Recycle()
