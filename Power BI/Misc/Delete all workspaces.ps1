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

##############################################################################


# Bring back all workspaces
$uri = "https://api.powerbi.com/v1.0/myorg/groups/"
$Workspaces = (Invoke-RestMethod -Uri $uri –Headers $auth_header –Method GET).value

Foreach($workspace in $workspaces)
{
$ID = $workspace.id
$Workuri = "https://api.powerbi.com/v1.0/myorg/groups/$ID"
Invoke-RestMethod -Uri $Workuri –Headers $auth_header –Method DELETE
}