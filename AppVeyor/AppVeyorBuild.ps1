Write-Host ('Running AppVeyor build script') -ForegroundColor Yellow
Write-Host ('ModuleName    : {0}' -f $env:ModuleName)
Write-Host ('Build version : {0}' -f $env:APPVEYOR_BUILD_VERSION)
Write-Host ('Author        : {0}' -f $env:APPVEYOR_REPO_COMMIT_AUTHOR)
Write-Host ('Branch        : {0}' -f $env:APPVEYOR_REPO_BRANCH)
Write-Host ('Repo          : {0}' -f $env:APPVEYOR_REPO_NAME)
Write-Host ('PSModulePath  :')

$env:PSModulePath -split ';'

Write-Host 'Nothing to build, skipping.....'