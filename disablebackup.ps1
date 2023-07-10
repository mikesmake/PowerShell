

Set-AzContext -Subscription  

$vault = Get-AzRecoveryServicesVault -ResourceGroupName "" -Name ""

$cont = Get-AzRecoveryServicesBackupContainer -ContainerType AzureVMAppContainer -VaultId $vault.id -FriendlyName "" 

$items = Get-AzRecoveryServicesBackupItem -Container $cont -WorkloadType MSSQL -VaultId $vault.id

$items | gm   

foreach ($item in $items) {
    Write-host  "Disabling" $item.FriendlyName
    Disable-AzRecoveryServicesBackupProtection -Item $item -RemoveRecoveryPoints -Force -VaultId $vault.ID
}