#TODO 'Generate help with platyPS'
$BaseUri = 'http://filelist.ro'
Import-Module ('{0}\lib\HtmlAgilityPack.dll' -f $PSScriptRoot)
$ProgressPreference = 'SilentlyContinue'

$Public  = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue )

Foreach($import in @($Public + $Private)) {
    Try {
        . $import.fullname
    }
    Catch {
        Write-Error -Message "Failed to import function $($import.fullname): $_"
    }
}