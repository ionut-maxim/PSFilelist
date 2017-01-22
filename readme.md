[![Build status](https://ci.appveyor.com/api/projects/status/2bgd59miae4dcmbd?svg=true)](https://ci.appveyor.com/project/bahaula/psfilelist)

Description
=============================

Powershell Module for filelist

The module is using `Invoke-WebRequest` to get the HTML documents and parses them using [HtmlAgilityPack](http://htmlagilitypack.codeplex.com/)

Installation
=============================

1. You can install this module from the [Powershell Gallery](https://www.powershellgallery.com/packages/PSFilelist). Run this command in powershell:
```powershell
Install-Module -Name PSFilelist
```
2. You can also install it running the following command in the powershell console in case you are not on the latest version of Powershell:
```powershell
iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/ionut-maxim/PSFilelist/master/install.ps1'))
```

Using this module
=============================

1. Import the module
```powershell
Import-Module PSFilelist
```
2. We must run `Invoke-FLLogin` once per session. It will create a websession variable that will be used troughout the current powershell session.
```powershell
Invoke-FLLogin -Username 'username' -Password 'password'
```
3. You can now start searching, browsing and filtering for torrents using the `Get-FLTorrent` cmdlet.
```powershell
Get-FLTorrent

Get-FLTorrent -Name 'Deadpool 2016'

Get-FLTorrent -Name 'Deadpool 2016' -Category 'Filme Blu-Ray'

$Torrent = Get-FLTorrent -Name 'Star Wars' | Where-Object {$_.Length -gt 10GB} | Select-Object -First 1
```
4. You can download the torrent file/files using `Start-FLDownload`
```powershell
#We can pipe the variable defined earlier to the our download cmdlet
$Torrent | Start-FLDownload
```