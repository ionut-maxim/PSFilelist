[CmdletBinding()]
param (
	[string]$Path
)

$localpath = $(Join-Path -Path (Split-Path -Path $profile) -ChildPath '\Modules\PSFilelist')

try
{
	if ($Path.length -eq 0)
	{
		
		if ($PSCommandPath.Length -gt 0)
		{
			$path = Split-Path $PSCommandPath
			if ($path -match "github")
			{
				$path = $localpath
			}
		}
		else
		{
			$path = $localpath
		}
	}
}
catch
{
	$path = $localpath
}

if ($path.length -eq 0)
{
	$path = $localpath
}

Write-Output "Installing module to $path"

Remove-Module PSFilelist -ErrorAction SilentlyContinue
$url = 'https://github.com/ionut-maxim/PSFilelist/archive/master.zip'

$temp = ([System.IO.Path]::GetTempPath()).TrimEnd("\")
$zipfile = "$temp\PSFilelist.zip"

if (!(Test-Path -Path $path))
{
	try
	{
		Write-Output "Creating directory: $path"
		New-Item -Path $path -ItemType Directory | Out-Null
	}
	catch
	{
		throw "Can't create $Path. You may need to Run as Administrator"
	}
}
else
{
	try
	{
		Write-Output "Deleting previously installed module"
		Remove-Item -Path "$path\*" -Force -Recurse
	}
	catch
	{
		throw "Can't delete $Path. You may need to Run as Administrator"
	}
}

Write-Output "Downloading archive from github"
	try
	{
		Invoke-WebRequest $url -OutFile $zipfile
	}
	catch
	{
		#try with default proxy and usersettings
		Write-Output "Probably using a proxy for internet access, trying default proxy settings"
		(New-Object System.Net.WebClient).Proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
		Invoke-WebRequest $url -OutFile $zipfile
	}
	
	# Unblock if there's a block
	Unblock-File $zipfile -ErrorAction SilentlyContinue
	
	Write-Output "Unzipping"
	
	# Keep it backwards compatible
	$shell = New-Object -COM Shell.Application
	$zipPackage = $shell.NameSpace($zipfile)
	$destinationFolder = $shell.NameSpace($temp)
	$destinationFolder.CopyHere($zipPackage.Items())
	
	Write-Output "Cleaning up"
	Move-Item -Path "$temp\PSFilelist-master\PSFilelist" $path
	Remove-Item -Path "$temp\PSFilelist-master"
	Remove-Item -Path $zipfile
	
	Write-Output "Done!"
	if ((Get-Command -Module PSFilelist).count -eq 0) { Import-Module "$path\PSFilelist.psd1" -Force }
	Get-Command -Module PSFilelist
	Write-Output "`n`nIf you experience any function missing errors after update, please restart PowerShell or reload your profile."