#requires -Version 3
#Variables for Pester tests

$ModulePath = Split-Path -Parent -Path (Split-Path -Parent -Path $MyInvocation.MyCommand.Path)
$ModuleName = 'PSFilelist'
$ManifestPath   = "$ModulePath\PSFilelist\$ModuleName.psd1"
$ModulePSM1file   = "$ModulePath\PSFilelist\$ModuleName.psm1"
if (Get-Module -Name $ModuleName) 
{
  Remove-Module $ModuleName -Force 
}
Import-Module $ManifestPath -Verbose:$false

Describe "Invoke-FLLogin" {
    It "Creates our session variable" {
        {Invoke-FLLogin -Username $env:flusername -Password $env:flpassword} | Should Not Throw
    }
}

Describe "Get-FLTorrent" {
    It "Gets one Filelist.Torrent object" {
        Get-FLTorrent | Select-Object -First 1 | Should Not BeNullOrEmpty
    }
}
