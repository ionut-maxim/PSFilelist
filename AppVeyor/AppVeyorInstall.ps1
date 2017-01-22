Write-Host 'Running AppVeyor install script' -ForegroundColor Yellow
Write-Host 'Installing NuGet PackageProvide'
$Nuget = Install-PackageProvider -Name NuGet -Force -ErrorAction Stop
Write-Host ('Installed NuGet version: {0}' -f $Nuget.Version)
Install-Module -Name 'Pester' -Repository PSGallery -Force -ErrorAction Stop

#Write-Host 'Updating PSModulePath for DSC resource testing'
#$env:PSModulePath = $env:PSModulePath + ";" + "C:\projects"

$RequiredModules  = 'Pester'
$InstalledModules = Get-Module -Name $RequiredModules -ListAvailable
if ( ($InstalledModules.count -lt $RequiredModules.Count) -or ($Null -eq $InstalledModules)) { 
  Throw 'Required modules are missing.'
} else {
  Write-Host 'All modules required found' -ForegroundColor Green
}