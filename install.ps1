$ModuleName = 'PSFilelist'
$ModulePaths = $env:PSModulePath -split ';'
foreach ( $ModulePath in $ModulePaths ) {
	switch -Regex ($ModulePath) {
		"($env:USERNAME).*(WindowsPowershell)" { $CUModulePath = $ModulePath }
        "(Program Files).*(WindowsPowershell)" { $MModulePath = $ModulePath }
	}
}
If ([bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544")) {
	$InstallPath = ('{0}\{1}' -f $MModulePath, $ModuleName)
} else {
    $InstallPath = ('{0}\{1}' -f $CUModulePath, $ModuleName)
}

Remove-Module PSFilelist -ErrorAction SilentlyContinue -Force
Remove-Item -Path $InstallPath -Recurse -ErrorAction SilentlyContinue

$URI = 'https://github.com/ionut-maxim/PSFilelist/archive/master.zip'
$Temp = ([System.IO.Path]::GetTempPath()).TrimEnd("\")
$Zipfile = ('{0}\{1}.zip' -f $Temp, $ModuleName)

Write-Host ('Module will be installed in: {0}' -f $InstallPath) -ForegroundColor Yellow

Write-Host 'Downloading archive from github'
try {
	Invoke-WebRequest -Uri $URI -OutFile $Zipfile
} catch {
	#try with default proxy and usersettings
	Write-Host 'Probably using a proxy for internet access, trying default proxy settings'
	(New-Object System.Net.WebClient).Proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
	Invoke-WebRequest -Uri $URI -OutFile $Zipfile
}

# Unblock if there's a block
Unblock-File -Path $Zipfile -ErrorAction SilentlyContinue

Write-Host 'Unzipping' -ForegroundColor Yellow

# Keep it backwards compatible
$Shell = New-Object -COM Shell.Application
$ZipPackage = $Shell.NameSpace($Zipfile)
$DestinationFolder = $Shell.NameSpace($Temp)
$DestinationFolder.CopyHere($ZipPackage.Items())

Write-Host 'Cleaning up' -ForegroundColor Yellow
Move-Item -Path ('{0}\{1}-master\{1}' -f $Temp, $ModuleName) -Destination $InstallPath -Force
Remove-Item -Path ('{0}\{1}-master' -f $Temp, $ModuleName) -Recurse -Force
Remove-Item -Path $Zipfile -Recurse -Force

Write-Host 'Installation complete!' -ForegroundColor Green
Write-Host 'If you experience any function missing errors after update, please restart PowerShell or reload your profile.' -ForegroundColor Yellow