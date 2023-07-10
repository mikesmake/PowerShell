########################################################
########      Authentication           #################
########################################################
function GetAuthToken
{
    if(-not (Get-Module AzureRm.Profile)) {Import-Module AzureRm.Profile}
    $clientId = '44fbf3af-ab38-4819-ba05-ae1cc022ea51'
    $redirectUri = 'urn:ietf:wg:oauth:2.0:oob'
    $resourceAppIdURI = 'https://analysis.windows.net/powerbi/api'
    $authority = 'https://login.microsoftonline.com/common/oauth2/authorize';
    $authContext = New-Object 'Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext' -ArgumentList $authority
    $authResult = $authContext.AcquireToken($resourceAppIdURI, $clientId, $redirectUri, 'Auto')
    return $authResult
}

$token = GetAuthToken
Add-Type -AssemblyName System.Net.Http
$auth_header = @{
   'Content-Type'='application/json'
   'Authorization'=$token.CreateAuthorizationHeader()
}

########################################################

# Input path
$input = 'C:\Users\Mike\Downloads\Desk\Power BI\Step 6 - Import Permissions\Newperms.csv'
$permissions = Import-Csv -Path $input

foreach ($permission in $permissions)
    {
    "Creating $email in $workspace"
    $workspace = $permission.Workspace
    $email = $permission.emailAddress
    $right = $permission.groupUserAccessRight
    $WID = $permission.NewID
    $uri = "https://api.powerbi.com/v1.0/myorg/groups/$WID/users"
    $body = "{`"emailAddress`":`"$email`",`"groupUserAccessRight`": `"$right`"}"
    Invoke-RestMethod -Uri $uri -Headers $auth_header -Method 'POST' -body $body 
    }






