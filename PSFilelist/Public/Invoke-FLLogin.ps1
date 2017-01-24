function Invoke-FLLogin {
    #TODO 'Add a secure method to pass credentials'
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true)][string]$Username,
        [Parameter(Mandatory=$true)][string]$Password
    )
    
    $Request = Invoke-WebRequest -Uri $Script:BaseUri -SessionVariable Script:session -UseBasicParsing
    $Parameters = @{ 
        username = $Username
        password = $Password 
    }
    Invoke-WebRequest -Uri "$Script:BaseUri/takelogin.php" -WebSession $Script:session -Method POST -Body $Parameters -UseBasicParsing
}