# Deploy to Powershell Gallery only where there is a tag which will have the version number
    $deploy = ($env:APPVEYOR_REPO_TAG -eq $true)
    if ($deploy)
    {
      $gitOut = git checkout master 2>&1
      Write-Host "Starting Deployment tag $env:APPVEYOR_REPO_TAG_NAME"      
      $moduleName = "PSFilelist"
      $currentVersion = (Import-PowerShellDataFile .\PSFilelist\$moduleName.psd1).ModuleVersion
      ((Get-Content .\PSFilelist\PSFilelist.psd1).replace("ModuleVersion = '$($currentVersion)'", "ModuleVersion = '$($env:APPVEYOR_REPO_TAG_NAME).$($env:APPVEYOR_BUILD_VERSION)'")) | Set-Content .\PSFilelist\$moduleName.psd1
      Publish-Module -Path .\PSFilelist -NuGetApiKey $env:nugetKey
      
      git config --global core.safecrlf false
      git config --global credential.helper store
      Add-Content "$env:USERPROFILE\.git-credentials" "https://$($env:github_access_token):x-oauth-basic@github.com`n"
      git config --global user.email "ionut@ionutmaxim.ro"
      git config --global user.name "Ionut Maxim"
      git add PSFilelist\PSFilelist.psd1  
      git commit -m "Automatic Version Update from CI"
      $gitOut = git push 2>&1
      if ($?) {$out} else {$out.Exception}
      
    }