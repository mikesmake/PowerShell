## Params ##
#$creds = Get-Credential
$RGName = ""
############

# Connect to AZ and get resources
Connect-AzAccount -Subscription ""
$RG = Get-AzResourceGroup -Name $RGName
$Resources = Get-AzResource -ResourceGroupName $RG.ResourceGroupName


# Table craetion/formatting
$Export  = @()

# Loop all resources to get details
ForEach ($Resource in $Resources)
{

    # get resource type to filter though switch below
    $ResourceType = $Resource.ResourceType

    # Where resource type matches perform relavant block
    switch ($ResourceType) 
    {
       
        # Data Factory
        Microsoft.DataFactory/factories
        {
        #Write-host "Data Factory - No URLs"
        }

        # Key Vaults
        Microsoft.KeyVault/vaults
        { 
        $KeyVaultURI = Get-AzKeyVault -VaultName $Resource.Name | select-object VaultURI
        $ExportData = @()
        $ExportData = New-Object System.Object
        $ExportData  | Add-Member -NotePropertyName Name -NotePropertyValue NULL
        $ExportData  | Add-Member -NotePropertyName Type -NotePropertyValue NULL
        $ExportData  | Add-Member -NotePropertyName URI -NotePropertyValue NULL
        #Clear-Variable ExportData
        $ExportData.Name = $Resource.Name
        $ExportData.Type = "Key Vault"
        $ExportData.URI = $KeyVaultURI.VaultUri
        $Export += $ExportData

        # SQL Servers
        }
        Microsoft.Sql/servers
        { 
        $SQLServerURI = Get-AzSqlServer -ServerName $Resource.Name | select-object  FullyQualifiedDomainName
        $ExportData = @()
        $ExportData = New-Object System.Object
        $ExportData  | Add-Member -NotePropertyName Name -NotePropertyValue NULL
        $ExportData  | Add-Member -NotePropertyName Type -NotePropertyValue NULL
        $ExportData  | Add-Member -NotePropertyName URI -NotePropertyValue NULL
        $ExportData.Name = $Resource.Name
        $ExportData.Type = "SQL Server"
        $ExportData.URI = $SQLServerURI.FullyQualifiedDomainName
        $Export += $ExportData
        }

        # SQL Databases
        Microsoft.Sql/servers/databases
        {
            #Write-host "SQL Server DB - No URLs"
        }

        # Analysis Services
        Microsoft.AnalysisServices/servers
        {         
        $AnalysisURI = Get-AzAnalysisServicesServer -ResourceGroupName $RGName -Name $Resource.Name | Select-Object ServerFullName
        $ExportData = @()
        $ExportData = New-Object System.Object
        $ExportData  | Add-Member -NotePropertyName Name -NotePropertyValue NULL
        $ExportData  | Add-Member -NotePropertyName Type -NotePropertyValue NULL
        $ExportData  | Add-Member -NotePropertyName URI -NotePropertyValue NULL
        $ExportData.Name = $Resource.Name
        $ExportData.Type = "Analysis Services"
        $ExportData.URI = $AnalysisURI.ServerFullName
        $Export += $ExportData
        }

        # Websites
        Microsoft.Web/sites 
        {
        $WebAdresses = Get-AzWebApp -ResourceGroupName $RGName -name $Resource.Name | select-object EnabledHostNames
        $Weblist = $WebAdresses.EnabledHostNames
            foreach ($web in $Weblist) 
            {
            $ExportData = @()
            $ExportData = New-Object System.Object
            $ExportData  | Add-Member -NotePropertyName Name -NotePropertyValue NULL
            $ExportData  | Add-Member -NotePropertyName Type -NotePropertyValue NULL
            $ExportData  | Add-Member -NotePropertyName URI -NotePropertyValue NULL
            $ExportData.Name = $Resource.Name
            $ExportData.Type = "Website"
            $ExportData.URI = $web
            $Export += $ExportData
            }
        }

        # Application Insights
        microsoft.insights/components
        {
        #Write-host "Application Insights - No URLs"
        }
        
        # Application Insights
        microsoft.insights/actiongroups
        {
       # Write-host "Application Insights - No URLs"
        }

        # App Service Plans
        Microsoft.Web/serverFarms
        {            
        #Write-host "App Service Plan - No URLs"
        }

         # Storage Accounts 
         Microsoft.Storage/storageAccounts
         { 
         $storage = Get-AzStorageAccount -ResourceGroupName $RGName -Name $Resource.Name
 
         $ExportData = @()
         $ExportData = New-Object System.Object
         $ExportData  | Add-Member -NotePropertyName Name -NotePropertyValue NULL
         $ExportData  | Add-Member -NotePropertyName Type -NotePropertyValue NULL
         $ExportData  | Add-Member -NotePropertyName URI -NotePropertyValue NULL
         $ExportData.Name = $storage.StorageAccountName
         $ExportData.Type = "Blob Storage"
         $ExportData.URI = $storage.PrimaryEndpoints.Blob
         $Export += $ExportData
         $ExportData = @()
         $ExportData = New-Object System.Object
         $ExportData  | Add-Member -NotePropertyName Name -NotePropertyValue NULL
         $ExportData  | Add-Member -NotePropertyName Type -NotePropertyValue NULL
         $ExportData  | Add-Member -NotePropertyName URI -NotePropertyValue NULL
         $ExportData.Name = $storage.StorageAccountName
         $ExportData.Type = "File Storage"
         $ExportData.URI = $storage.PrimaryEndpoints.File
         $Export += $ExportData
         #Write-Host "Queue Service =" $storage.PrimaryEndpoints.Queue
         $ExportData = @()
         $ExportData = New-Object System.Object
         $ExportData  | Add-Member -NotePropertyName Name -NotePropertyValue NULL
         $ExportData  | Add-Member -NotePropertyName Type -NotePropertyValue NULL
         $ExportData  | Add-Member -NotePropertyName URI -NotePropertyValue NULL
         $ExportData.Name = $storage.StorageAccountName
         $ExportData.Type = "Queue Service"
         $ExportData.URI = $storage.PrimaryEndpoints.queue
         $Export += $ExportData
         #Write-Host "Table Service =" $storage.PrimaryEndpoints.Table
         $ExportData = @()
         $ExportData = New-Object System.Object
         $ExportData  | Add-Member -NotePropertyName Name -NotePropertyValue NULL
         $ExportData  | Add-Member -NotePropertyName Type -NotePropertyValue NULL
         $ExportData  | Add-Member -NotePropertyName URI -NotePropertyValue NULL
         $ExportData.Name = $storage.StorageAccountName
         $ExportData.Type = "Table Service"
         $ExportData.URI = $storage.PrimaryEndpoints.table
         $Export += $ExportData
         #Write-Host "Data Lake =" $storage.PrimaryEndpoints.Dfs
         $ExportData = @()
         $ExportData = New-Object System.Object
         $ExportData  | Add-Member -NotePropertyName Name -NotePropertyValue NULL
         $ExportData  | Add-Member -NotePropertyName Type -NotePropertyValue NULL
         $ExportData  | Add-Member -NotePropertyName URI -NotePropertyValue NULL
         $ExportData.Name = $storage.StorageAccountName
         $ExportData.Type = "Data Factory"
         $ExportData.URI = $storage.PrimaryEndpoints.dfs
         $Export += $ExportData
         #Write-Host "Static Website =" $storage.PrimaryEndpoints.Web
         $ExportData = @()
         $ExportData = New-Object System.Object
         $ExportData  | Add-Member -NotePropertyName Name -NotePropertyValue NULL
         $ExportData  | Add-Member -NotePropertyName Type -NotePropertyValue NULL
         $ExportData  | Add-Member -NotePropertyName URI -NotePropertyValue NULL
         $ExportData.Name = $storage.StorageAccountName
         $ExportData.Type = "Static Website"
         $ExportData.URI = $storage.PrimaryEndpoints.Blob
         $Export += $ExportData
         }

        # Catch any undefined resources
        Default {Write-host "Resource type not configured"}
    }

}


$Export | ft  