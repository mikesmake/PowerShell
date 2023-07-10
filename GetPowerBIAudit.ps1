param($Timer)

# Enable the AzureRM Aliasing for older Functions
Enable-AzureRmAlias

# Get User Details 
$username = $env:user
$password = $env:password
$keypath = "D:\home\site\wwwroot\PBI-GetActivityEvents\bin\Keys\PassEncryptKey.key"
$secpassword = $password | ConvertTo-SecureString -Key (Get-Content $keypath)
$SecPasswd = ConvertTo-SecureString $secpassword -AsPlainText -Force
$myCred = New-Object System.Management.Automation.PSCredential($username, $secpassword)


# Login to PowerBI 
Connect-PowerBIServiceAccount -Credential $myCred

$CurrentDateTime = (Get-Date)

# Define temp export location
$FolderAndCsvFilesLocation = "D:\home\site\wwwroot\AuditFiles"

# Get date of last export and work out how many days to export
$GetLastModifiedFileDateTime = Get-ChildItem "$FolderAndCsvFilesLocation\*.csv" | `
    Where { $_.LastWriteTime -gt (Get-Date).AddDays(-1) } | `
    Select -First 1
$ConvertToDateTimeLastModified = [datetime]$GetLastModifiedFileDateTime.LastWriteTime
$DateDifference = New-timespan -Start $ConvertToDateTimeLastModified -End $CurrentDateTime
$DaysDifference = $DateDifference.Days
if ($DaysDifference -eq 0) { 1 } else { $DaysDifference }

# List of Dates to Iterate Through
$DaysDifference..1 |
foreach {
    $Date = (((Get-Date).Date).AddDays(-$_))
    $StartDate = (Get-Date -Date ($Date) -Format yyyy-MM-ddTHH:mm:ss)
    $EndDate = (Get-Date -Date ((($Date).AddDays(1)).AddMilliseconds(-1)) -Format yyyy-MM-ddTHH:mm:ss)
    $FileName = (Get-Date -Date ($Date) -Format yyyyMMdd)
 
    # Defien output location 
    $ActivityLogsPath = "$FolderAndCsvFilesLocation\$FileName.csv"

    # Get logs for current loop day and export
    $ActivityLogs = Get-PowerBIActivityEvent -StartDateTime $StartDate -EndDateTime $EndDate | ConvertFrom-Json
    $ActivityLogSchema = $ActivityLogs | Select-Object Id, CreationTime, CreationTimeUTC, RecordType, Operation, OrganizationId, UserType, UserKey, Workload, UserId, ClientIP, UserAgent, Activity, ItemName, WorkSpaceName, DashboardName, DatasetName, ReportName, WorkspaceId, ObjectId, DashboardId, DatasetId, ReportId, OrgAppPermission, CapacityId, CapacityName, AppName, IsSuccess, ReportType, RequestId, ActivityId, AppReportId, DistributionMethod, ConsumptionMethod, @{Name = "RetrieveDate"; Expression = { $RetrieveDate } }
    $ActivityLogSchema | Export-Csv $ActivityLogsPath 

    # Move the File to Azure Blob Storage
    $StorageAccountName = "" 
    $StorageAccountKey = ""
    $ctx = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey
    $SourceShareName = "powerbiauditapp9e19"
    $SourceFilePath = "site\wwwroot\AuditFiles\$FileName.csv"
    $DestinationContainerName = "pbitest"
    Start-AzureStorageBlobCopy -SrcShareName $SourceShareName -SrcFilePath $SourceFilePath -DestContainer $DestinationContainerName -DestBlob "$FileName.csv" -Context $ctx -Force
}