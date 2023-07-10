########################################################
########      Authentication           #################
########################################################

function GetAuthToken
{
    if(-not (Get-Module AzureRm.Profile)) {Import-Module AzureRm.Profile}
    $clientId = "44fbf3af-ab38-4819-ba05-ae1cc022ea51"
    $redirectUri = "urn:ietf:wg:oauth:2.0:oob"
    $resourceAppIdURI = "https://analysis.windows.net/powerbi/api"
    $authority = "https://login.microsoftonline.com/common/oauth2/authorize";
    $authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authority
    $authResult = $authContext.AcquireToken($resourceAppIdURI, $clientId, $redirectUri, "Auto")
    return $authResult
}

$token = GetAuthToken
Add-Type -AssemblyName System.Net.Http
$auth_header = @{
   'Content-Type'='application/json'
   'Authorization'=$token.CreateAuthorizationHeader()
}

########################################################


# Output path
$Output = 'C:\Users\Mike\Downloads\Desk\Power BI\Files'



# Bring back all workspaces
$uri = "https://api.powerbi.com/v1.0/myorg/groups/"
$Workspaces = (Invoke-RestMethod -Uri $uri –Headers $auth_header –Method GET).value
$Workspaces | select id,name | Export-Csv -Path "$Output\Workspaces.csv"-NoTypeInformation