# Get all subscriptions user has access to
$subs = Get-AzSubscription

# create empty array to populate in the loop
$Output = @()

###################################################################################################
# Storage Account
###################################################################################################

Write-Host -ForegroundColor DarkMagenta "Storage Accounts"

$store = @()

$accounts = @()

foreach ($sub in $subs) {
    Write-Host -ForegroundColor Cyan "Retrieving Storage Accounts from -" $sub.name
    Set-AzContext -Subscription $sub.id | Out-Null
    $accounts += Get-AzStorageAccount
}

foreach ($account in $accounts) {
    $store = New-Object psobject -Property @{
        "StorageAccount"     = $account.StorageAccountName
        "Blob"               = $account.PrimaryEndpoints.Blob
        "DFS"                = $account.PrimaryEndpoints.Dfs
        "File"               = $account.PrimaryEndpoints.File
        "Queue"              = $account.PrimaryEndpoints.Queue
        "Table"              = $account.PrimaryEndpoints.Table
        "Web"                = $account.PrimaryEndpoints.Web
        "InternetEndpoints"  = $account.PrimaryEndpoints.InternetEndpoints
        "MicrosoftEndpoints" = $account.PrimaryEndpoints.MicrosoftEndpoints
    }

    $Output += $store | Select-Object @{L = 'Resource Name'; E = { $account.StorageAccountName } }, @{L = 'Resource Type'; E = { 'Storage Account' } }, @{L = 'Resource Group'; E = { $account.ResourceGroupName } }, @{L = 'URL'; E = {} }, Blob, DFS, File, Queue, Table, Web, InternetEndpoints, MicrosoftEndpoints
}

###################################################################################################
# Key Vault
###################################################################################################

Write-Host -ForegroundColor DarkMagenta "Key Vaults"

# gets all Key Vaults in all subscriptions
foreach ($sub in $subs) {
    Write-Host -ForegroundColor Cyan "Retrieving Key Vaults from -" $sub.name
    Set-AzContext -Subscription $sub.id | Out-Null
    $keyvaults = Get-AzKeyVault -WarningAction:SilentlyContinue

    Foreach ($keyvault in $keyvaults) {
        $Output += Get-AzKeyVault  -VaultName $keyvault.VaultName -WarningAction:SilentlyContinue | Select-Object @{L = 'Resource Name'; E = { $_.VaultName } }, @{L = 'Resource Type'; E = { 'KeyVault' } }, @{L = 'Resource Group'; E = { $_.ResourceGroupName } }, @{L = 'URL'; E = { $_.VaultUri } }
    }
}

###################################################################################################
# Function App 
###################################################################################################

Write-Host -ForegroundColor DarkMagenta "Function Apps"

# gets all function apps in all subscriptions
foreach ($sub in $subs) {
    Write-Host -ForegroundColor Cyan "Retrieving Function Apps from -" $sub.name
    Set-AzContext -Subscription $sub.id | Out-Null
    $FunctionApps = Get-AzFunctionApp | Out-Null
            
    Foreach ($FunctionApp in $FunctionApps) {
        $Output += Get-AzFunctionApp  -Name $FunctionApp.Name -ResourceGroupName $FunctionApp.ResourceGroupName | Select-Object @{L = 'Resource Name'; E = { $_.Name } }, @{L = 'Resource Type'; E = { 'Function App' } }, @{L = 'Resource Group'; E = { $_.ResourceGroupName } }, @{L = 'URL'; E = { $_.DefaultHostName } }
    }
}

###################################################################################################
# Web Apps
###################################################################################################

Write-Host -ForegroundColor DarkMagenta "Web Apps"

# gets all web apps in all subscriptions
foreach ($sub in $subs) {
    Write-Host -ForegroundColor Cyan "Retrieving Web Apps from -" $sub.name
    Set-AzContext -Subscription $sub.id | Out-Null
    $ProgressPreference = "SilentlyContinue"
    $WebApps = Get-AzWebApp
            
    Foreach ($WebApp in $WebApps) {
        $Output += Get-AzWebApp -Name $WebApp.Name -ResourceGroupName $WebApp.ResourceGroup | Select-Object @{L = 'Resource Name'; E = { $_.Name } }, @{L = 'Resource Type'; E = { 'Web App' } }, @{L = 'Resource Group'; E = { $_.ResourceGroup } }, @{L = 'URL'; E = { $_.DefaultHostName } }
    }
}

###################################################################################################
# SQL Servers
###################################################################################################

Write-Host -ForegroundColor DarkMagenta "SQL Servers"

foreach ($sub in $subs) {
    Write-Host -ForegroundColor Cyan "Retrieving SQL Servers from -" $sub.name
    Set-AzContext -Subscription $sub.id | Out-Null
    $SqlServers = Get-AzSqlServer
            
    Foreach ($SqlServer in $SqlServers) {
        $Output += Get-AzSqlServer -Name $SqlServer.ServerName | Select-Object @{L = 'Resource Name'; E = { $_.ServerName } }, @{L = 'Resource Type'; E = { 'SQL Server' } }, @{L = 'Resource Group'; E = { $_.ResourceGroupName } }, @{L = 'URL'; E = { $_.FullyQualifiedDomainName } }
    }
}

###################################################################################################
# Front Door
###################################################################################################

Write-Host -ForegroundColor DarkMagenta "Front Doors"

foreach ($sub in $subs) {
    Write-Host -ForegroundColor Cyan "Retrieving Front Doors from -" $sub.name
    Set-AzContext -Subscription $sub.id | Out-Null
    $FrontDoors = Get-AzFrontDoor
            
    Foreach ($FrontDoor in $FrontDoors) {
        $hostnames = Get-AzFrontDoor -Name $FrontDoor.Name | Select-Object -ExpandProperty FrontendEndpoints
        $Output += Get-AzFrontDoor -Name $FrontDoor.Name | Select-Object @{L = 'Resource Name'; E = { $_.Name } }, @{L = 'Resource Type'; E = { 'Front Door' } }, @{L = 'Resource Group'; E = { $_.ResourceGroupName } }, @{L = 'URL'; E = { $hostnames.hostname } }
    }
}

###################################################################################################
# CDNs 
###################################################################################################

Write-Host -ForegroundColor DarkMagenta "Content Delivery Networks"

$cdnprofiles = @()

foreach ($sub in $subs) {
    Write-Host -ForegroundColor Cyan "Retrieving CDNs from -" $sub.name
    Set-AzContext -Subscription $sub.id | Out-Null
    $cdnprofiles = Get-AzFrontDoorCdnProfile | Select-Object name, ResourceGroupName
}

foreach ($cdnprofile in $cdnprofiles) {
    Set-AzContext -Subscription $subs
    $Output += Get-AzFrontDoorCdnEndpoint -ResourceGroupName $cdnprofile.ResourceGroupName -ProfileName $cdnprofile.Name | Select-Object @{L = 'Resource Name'; E = { $_.Name } }, @{L = 'Resource Type'; E = { 'Front Door CDN' } }, @{L = 'Resource Group'; E = { $_.ResourceGroup } }, @{L = 'URL'; E = { $_.HostName } }
}

###################################################################################################
# Traffic Managers 
###################################################################################################

Write-Host -ForegroundColor DarkMagenta "Traffic Managers"

$trafficprofiles = @()

foreach ($sub in $subs) {
    Write-Host -ForegroundColor Cyan "Retrieving Traffic Managers from -" $sub.name
    Set-AzContext -Subscription $sub.id | Out-Null
    $trafficprofiles = Get-AzTrafficManagerProfile | Select-Object -ExpandProperty Endpoints
    $Output += $trafficprofiles | Select-Object @{ L = 'Resource Name'; E = { $_.ProfileName } }, @{L = 'Resource Type'; E = { 'Traffic Manager' } }, @{L = 'Resource Group'; E = { $_.ResourceGroupName } }, @{L = 'URL'; E = { $_.Target } }
}


###################################################################################################
# Application Gateways 
###################################################################################################

Write-Host -ForegroundColor DarkMagenta "App Gateways"

foreach ($sub in $subs) {
    Write-Host -ForegroundColor Cyan "Retrieving App Gateways from -" $sub.name
    Set-AzContext -Subscription $sub.id | Out-Null
    $AppGateways = Get-AzApplicationGateway
    Foreach ($AppGateway in $AppGateways) {
        
        $PIPsetting = Get-AzApplicationGateway -Name $AppGateway.Name -ResourceGroupName $AppGateway.ResourceGroupName | Select-Object -ExpandProperty FrontendIPConfigurations
        $RGTrimPrefix = $pipsetting.PublicIpAddressText.Substring(79) 
        $RGTrimSuffix = $RGTrimPrefix.Substring(0, $RGTrimPrefix.IndexOf('/'))
        $pipTrimPrefix = $PIPsetting.PublicIpAddressText.Split('/')[-1]
        $pipTrimSuffix = $pipTrimPrefix.Substring(0, $pipTrimPrefix.Length - 4)
        $PIP = Get-AzPublicIpAddress -Name $pipTrimSuffix -ResourceGroupName $RGTrimSuffix
        $Output += Get-AzApplicationGateway -Name $AppGateway.Name -ResourceGroupName $AppGateway.ResourceGroupName | Select-Object @{ L = 'Resource Name'; E = { $_.Name } }, @{L = 'Resource Type'; E = { 'Application Gateway' } }, @{L = 'Resource Group'; E = { $_.ResourceGroupName } }, @{L = 'URL'; E = { $PIP.IpAddress } }
    }
}

###################################################################################################
# AD App Reg 
###################################################################################################

Write-Host -ForegroundColor DarkMagenta "Retrieving App Registrations" 
$Output += Get-AzADApplication | Select-Object @{L = 'Resource Name'; E = { $_.DisplayName } }, @{L = 'Resource Type'; E = { 'App Registration' } }


###################################################################################################
# Export 
###################################################################################################


$Output | Export-Csv "C:\temp\All Resources.csv" -NoTypeInformation

