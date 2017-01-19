function Start-FLDownload {
    [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [PSTypeName('Filelist.Torrent')]
        [System.Object[]]
        $InputObject,
        [Parameter()]
        [String]
        $Path = ('{0}\Downloads' -f $env:USERPROFILE)
    )
    Process {
        try {
            Write-Verbose ('{0}\{1}.torrent' -f $Path, $InputObject.ID)
            Invoke-WebRequest -Uri ('{0}/download.php?id={1}' -f $Script:BaseUri, $InputObject.ID) -WebSession $Script:session `
                -OutFile ('{0}\{1}.torrent' -f $Path, $InputObject.ID) -Verbose:$false -ErrorAction Stop
            Write-Output -InputObject (Get-Item -Path ('{0}\{1}.torrent' -f $Path, $InputObject.ID))
        }
        catch {
            Write-Error -Message ('{0}' -f $_.Exception.Message)
        }
    }
    
}