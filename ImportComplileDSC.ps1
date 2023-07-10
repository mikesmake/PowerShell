############### Parameters ###########################

#$subscription = ''
#$RG = ''
#$AutoAccount = ''
#$ConfigName = ''
#$FullConfigName = ''
#$configPath = ''
#$VMNames = ''
#$VMRG = ''

######################################################

[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $configPath,
    [Parameter()]
    [string]
    $RG,    
    [Parameter()]
    [string]
    $AutoAccount,    
    [Parameter()]
    [string]
    $ConfigName
)


#Set-AzContext -Subscription $subscription

Write-host "1"

Import-AzAutomationDscConfiguration -SourcePath $configPath -ResourceGroupName $RG -AutomationAccountName $AutoAccount -Published -force

Write-host "2"


$comnpID = Start-AzAutomationDscCompilationJob -ConfigurationName $ConfigName -ResourceGroupName $RG -AutomationAccountName $AutoAccount

Write-host "3"

$status = "test"

Clear-Variable status

while($status.status -ne 'Completed') {
    $status = Get-AzAutomationDscCompilationJob -ResourceGroupName $RG -AutomationAccountName $AutoAccount -Id $comnpID.id | select status
    start-sleep -s 1
    $status
}

Write-host "4"




