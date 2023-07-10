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

##########################################################

# Input path
$input = 'C:\Users\Mike\Downloads\Desk\Power BI\Step 1 - Export Permissions\workspacepermissions.csv'

# Output path
$Output = 'C:\Users\Mike\Downloads\Desk\Power BI\Files'

# Bring back all workspaces
$uri = "https://api.powerbi.com/v1.0/myorg/groups/"
$Workspaces = (Invoke-RestMethod -Uri $uri –Headers $auth_header –Method GET).value


#import list of workspaces and permissions
$permissions = Import-Csv -Path $input


foreach ($permission in $permissions)
    {
    $findid = $Workspaces | where name -EQ $permission.Workspace | select id #gets the new ID that matches the workspace name.
    $id = $findid.id
    $permission | Add-Member -Force -Name NewID -Value $id -MemberType NoteProperty #creates new field with ID
    }

$permissions | Export-Csv -Path "$Output\Newperms.csv"-NoTypeInformation