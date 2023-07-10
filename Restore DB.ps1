[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $serverPath,
    [Parameter()]
    [string]
    $DBstorageAccount,    
    [Parameter()]
    [string]
    $DBstorageKey,    
    [Parameter()]
    [string]
    $backupfile
)


$serverPath = "SQLSERVER:\SQL\localhost\default"
$storageAccount = ""
$backupfile = "https://sa.blob.core.windows.net/dbbackups/MAPS_Masked.bak"
$secureString = convertto-securestring $DBstorageKey -asplaintext -force
$credentialName = "StorageAccountCreds"

# needed otherwise script unable to cd to SQLSERVER:\SQL\localhost\default
Invoke-Sqlcmd  | Out-Null

CD $serverPath


#Set-SqlAuthenticationMode -Credential $Credential -Mode Integrated -ForceServiceRestart -AcceptSelfSignedCertificate

try { New-sqlcredential -Name $credentialName -Identity $DBstorageAccount -Secret $secureString }
catch { "Credential already exists" }



$RelocateData = New-Object Microsoft.SqlServer.Management.Smo.RelocateFile("_Data", "F:\MSSQL\Data\MAPS.mdf")
$RelocateLog = New-Object Microsoft.SqlServer.Management.Smo.RelocateFile("_Log", "G:\MSSQL\logs\MAPS.ldf")


if(Get-SqlDatabase -Name "DB1" -erroraction 'silentlycontinue'){
   write-host "DB already exsists"
}else {
   write-host "Restoring DB"
   Restore-SqlDatabase -Database "DB1" -BackupFile $backupfile -SqlCredential StorageAccountCreds -RelocateFile @($RelocateData, $RelocateLog)
}

