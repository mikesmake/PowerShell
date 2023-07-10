########################################################
########      Authentication           #################
########################################################
function GetAuthToken
{
    if(-not (Get-Module AzureRm.Profile)) {Import-Module AzureRm.Profile}
    $clientId = "0946c183-2e82-489f-973c-d24065782eb7"
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


# Output path
$Output = 'C:\PowerShell\Berry\Files'

# Bring back all workspaces
$uri = "https://api.powerbi.com/v1.0/myorg/groups/"
$Workspaces = (Invoke-RestMethod -Uri $uri –Headers $auth_header –Method GET).value


Foreach($workspace in $workspaces)
        {
        Write-Host $workspace.name
        $ID = $workspace.id
        $Name = $workspace.name
        $path = "myorg/groups/$ID"
        $Workuri = "https://api.powerbi.com/v1.0/$path/reports"
        $reports_json = Invoke-RestMethod -Uri $Workuri –Headers $auth_header –Method GET
        $reports = $reports_json.value
        New-Item -Path $Output -Name $workspace.name -ItemType "directory"


        Foreach($report in $reports) 
                {
                if ($report.name -ne "Report Usage Metrics Report")
                {
                if ($report.name -ne "Report Usage Metrics Report - Copy")
                {
                if ($report.name -ne "Dashboard Usage Metrics Report")
                {
                    $report_id = $report.id
                    $dataset_id = $report.datasetId
                    $report_name = $report.name
                    $ExportPath = "$Output\$name\$report_name.pbix"
                    "Exporting $report_name with id: $report_id from $Name ID $ID "
                    $uri = "https://api.powerbi.com/v1.0/$path/reports/$report_id/Export"
                    Invoke-RestMethod -Uri $uri –Headers $auth_header –Method GET -OutFile "$ExportPath"

                }
                }
                }
        }
}


