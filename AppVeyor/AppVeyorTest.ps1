Write-Host 'Running AppVeyor test script' -ForegroundColor Yellow
Write-Host ('Current working directory: {0}' -f $PWD)

$ResultsFile = '.\TestsResults.xml'
$TestFiles = Get-ChildItem -Path ('{0}\Tests' -f $PWD) |
    Where-Object {$_.FullName -match 'Tests.ps1$'} |
    Select-Object -ExpandProperty FullName
$Results = Invoke-Pester -Script $TestFiles -OutputFormat NUnitXml -OutputFile $ResultsFile -PassThru

Write-Host 'Uploading test results'
try {
  (New-Object 'System.Net.WebClient').UploadFile('https://ci.appveyor.com/api/testresults/nunit/{0}' -f $env:APPVEYOR_JOB_ID, (Resolve-Path $resultsFile))
} catch {
  throw "Upload failed."
}

if (($Results.FailedCount -gt 0) -or ($Results.PassedCount -eq 0) -or ($null -eq $Results)) { 
  throw '{0} tests failed.' -f $Results.FailedCount
} else {
  Write-Host 'All tests passed' -ForegroundColor Green
}