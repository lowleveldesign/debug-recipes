
### IIS logs ###

function Get-HttpSysLog(
   [string]$ComputerName = '.',
   [int]$Newest = 5)
{
    $path = "c:\Windows\system32\LogFiles\HTTPERR"
    if ($ComputerName -ne '.') {
        $path = $path -replace 'C:',"\\$ComputerName\c`$"
    }
    $query = "select top $Newest * from $path\*.log order by date,time"
    & "logparser" "-i:HttpErr","-rtp:-1",$query
}

function Get-IISLogEntries(
  [Parameter(Mandatory=$True,ValueFromPipeline=$True)][string]$LogDirectoryPath,
  [Parameter(Mandatory=$True)][string]$ApplicationName,
  [Parameter(Mandatory=$False)][int]$Newest = 5,
  [Parameter(Mandatory=$False)][int]$HttpStatus = 0)
{
  $where = "where 1 = 1 "
  if ($HttpStatus -ne 0) {
    Write-Verbose "Applying condition on http status"
    $where = "$where and sc-status = $HttpStatus"
  }
  $query = "select top $Newest date,time,c-ip,cs-username,cs(Cookie),s-sitename,cs-uri-stem,cs-uri-query,sc-status,sc-substatus,sc-win32-status from '$LogDirectoryPath\$ApplicationName\*.log' $where order by date, time desc"
  Write-Verbose "Executing query: '$query'"
  & "logparser" "-i:IISW3C","-rtp:-1",$query
}

function Get-IISLog(
   [Parameter(Mandatory=$False)][string]$ComputerName = ".",
   [Parameter(Mandatory=$True)][string]$ApplicationName,
   [Parameter(Mandatory=$False)][int]$Newest = 5,
   [Parameter(Mandatory=$False)][int]$HttpStatus = 0)
{
    $apps = Get-IISWmiObject -ComputerName $ComputerName -Class IIsWebServerSetting -Filter "Name like '%$ApplicationName%' or ServerComment like '%$ApplicationName%'"

    if ($apps.Count -eq 0) {
        Write-Host "No app found"
    }

    if ($apps.Count -gt 1) {
        Write-Output "More than one app found. Please choose one: "
        for ($i = 0; $i -lt $apps.Count; $i++) {
            Write-Output "`[$i`]: $($apps[$i].ServerComment), $($apps[$i].Name)"
        }
        $app = $apps[$(Read-Host)]
    } else {
        $app = $apps
    }

    $path = $app.LogFileDirectory
    if ($ComputerName -ne '.') {
        $path = $path -replace '(\w):',"\\$ComputerName\`$1`$`$"
    }
    Write-Output "Getting log for $($app.ServerComment), $($app.Name)"
    Get-IISLogEntries -LogDirectoryPath $path `
                      -ApplicationName $($app.Name -replace '/','') `
                      -Newest $Newest `
                      -HttpStatus $HttpStatus
}

function Get-IISWmiObject(
    [string]$ComputerName = '.',
    [string]$Class,
    [string]$Filter = '',
    [string]$Query = '',
    [PSCredential]$Credential)
{
    if (!$Credential) {
        if (-not [string]::IsNullOrEmpty($Query)) {
            Get-WmiObject -Namespace "root/MicrosoftIISv2" -Authentication PacketPrivacy -ComputerName $ComputerName -Query $Query
        } else {
            Get-WmiObject -Namespace "root/MicrosoftIISv2" -Authentication PacketPrivacy -ComputerName $ComputerName -Class $Class -Filter $Filter
        }
    } else {
        if (-not [string]::IsNullOrEmpty($Query)) {
            Get-WmiObject -Namespace "root/MicrosoftIISv2" -Authentication PacketPrivacy -ComputerName $ComputerName -Query $Query -Credential $Credential
        } else {
            Get-WmiObject -Namespace "root/MicrosoftIISv2" -Authentication PacketPrivacy -ComputerName $ComputerName -Class $Class -Filter $Filter -Credential $Credential
        }

    }
}

function Get-VDirByPath([string]$ComputerName = ".", [Parameter(Mandatory=$True)][string]$Path)
{
    # Escape backslashes
    $Path = $Path.Replace("\", "\\")
    Get-IISWmiObject -ComputerName $ComputerName -Class IIsWebVirtualDirSetting -Filter "Path='$Path'"
}

function New-WebSiteFromConfigurationFile(
    [Parameter(Mandatory=$False)][string]$ComputerName = '.',
    [Parameter(Mandatory=$True)][string]$ConfigFile,
    [Parameter(Mandatory=$False)][string]$NewWebsiteId,
    [Parameter(Mandatory=$True)][string]$ServerBinding,
    [Parameter(Mandatory=$True)][string]$ApplicationName,
    [Parameter(Mandatory=$True)][string]$AppPoolId)
{
    $old_ErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'

    $ns = @{ 'ns' = 'urn:microsoft-catalog:XML_Metabase_V64_0' }
    $oldid = (Select-Xml -Path .\test.xml -XPath 'ns:configuration/ns:MBProperty/ns:IIsWebServer/@Location' -Namespace $ns).Node.Value

    $filename = [IO.Path]::GetTempFileName()
    Get-Content $ConfigFile | Set-Content $filename
    if (-not [String]::IsNullOrEmpty($NewWebsiteId)) {
        $NewWebsiteId = "/LM/W3SVC/$NewWebsiteId"
    } else {
        $NewWebsiteId = $oldid
    }

    [xml]$conf = New-Object System.Xml.XmlDocument
    $conf.PreserveWhitespace = $true
    $conf.Load($filename)
    $conf.configuration.MBProperty.IIsWebServer.ServerBindings = $ServerBinding
    $conf.configuration.MBProperty.IIsWebServer.ServerComment = $ApplicationName
    $conf.configuration.MBProperty.IIsWebVirtualDir[0].AppPoolId = $AppPoolId
    $conf.configuration.MBProperty.IIsWebVirtualDir[0].AppFriendlyName = $ApplicationName
    $conf.configuration.MBProperty.IIsWebVirtualDir[0].AppRoot = "$NewWebsiteId/ROOT"
    $conf.configuration.MBProperty.IIsWebVirtualDir[0].SetAttribute("HttpErrors", $conf.configuration.MBProperty.IIsInheritedProperties.HttpErrors)
    $conf.configuration.MBProperty.IIsWebVirtualDir[0].SetAttribute('ScriptMaps', $conf.configuration.MBProperty.IIsInheritedProperties.ScriptMaps)

    $conf.configuration.MBProperty.RemoveChild($conf.configuration.MBProperty.IIsInheritedProperties) | Out-Null # remove inherited stuff

    $conf.Save($filename)

    Copy-Item $filename "\\$ComputerName\c`$\_website.xml"
    $iis = Get-IISWmiObject -ComputerName $ComputerName -Class IIsComputer
    $iis.Import("", "c:\_website.xml", "$oldid", "$NewWebsiteId", 1)
    Remove-Item "\\$ComputerName\c`$\_website.xml"
    Remove-Item $filename

    $ErrorActionPreference = $old_ErrorActionPreference
}


function Restart-IISAppPool(
    [Parameter(Mandatory=$False,ValueFromPipeline=$True)][string]$ComputerName = '.',
    [Parameter(Mandatory=$True)][string]$AppPool)
{
    Write-Host $("Restarting {0} pool on {1}" -f $AppPool,$ComputerName)
    (Get-IISWmiObject -ComputerName $ComputerName -Class IIsApplicationPool -Filter "Name = 'W3SVC/AppPools/$AppPool'").Recycle()
}
