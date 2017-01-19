function Invoke-FLLogin {
    #TODO 'Add a secure method to pass credentials'
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true)][string]$Username,
        [Parameter(Mandatory=$true)][string]$Password
    )
    
    $Request = Invoke-WebRequest -Uri $Script:BaseUri -SessionVariable Script:session
    $Form = $Request.Forms[0]
    $Form.Fields['username'] = $Username
    $Form.Fields['password'] = $Password
    Invoke-WebRequest -Uri "$Script:BaseUri/$($Form.Action)" -WebSession $Script:session -Method POST -Body $Form.Fields | Out-Null
}