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

#########################################################


# Bring back all workspaces
$uri = "https://api.powerbi.com/v1.0/myorg/groups"
$Workspaces = (Invoke-RestMethod -Uri $uri -Headers $auth_header -Method GET).value




Foreach($workspace in $workspaces)
    {
    $path = $workspace.name
    $ID = $workspace.id
    $WorkID = "myorg/groups/$ID"
    $reports = get-childitem "C:\Users\Mike\Downloads\Desk\Power BI\Files\$path"

    Foreach($report in $reports)
        {
        "Importing $report into $path"
        $name = $report.Name
        $URIRport = [System.Web.httpUtility]::UrlEncode($name) #UrlEncode report name to allow for special characters in URL
        $uri = "https://api.powerbi.com/v1.0/$WorkID/imports/?datasetDisplayName=$URIRport&nameConflict=Abort"
        $PBIXPath = "C:\Users\Mike\Downloads\Desk\Power BI\Files\$path\$name"
        $httpClient = New-Object System.Net.Http.Httpclient $httpClientHandler
        $httpClient.DefaultRequestHeaders.Authorization = New-Object System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", $token.AccessToken);
        $packageFileStream = New-Object System.IO.FileStream @($PBIXPath, [System.IO.FileMode]::Open)
        $contentDispositionHeaderValue = New-Object System.Net.Http.Headers.ContentDispositionHeaderValue "form-data"
        $contentDispositionHeaderValue.Name = "file0"
        $contentDispositionHeaderValue.FileName = $file_name
        $streamContent = New-Object System.Net.Http.StreamContent $packageFileStream
        $streamContent.Headers.ContentDisposition = $contentDispositionHeaderValue
        $content = New-Object System.Net.Http.MultipartFormDataContent
        $content.Add($streamContent)
        $response = $httpClient.PostAsync($Uri, $content).Result
        }

    }

