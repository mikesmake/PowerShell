#Set Parameters (Scale should be set to Off, Low, Medium or High)
Param
(   
    [Parameter(Mandatory = $true)]
    [String]
    $Scale       
)

#Set consistant variables 
$ResourceGroup = ""
$SQLServer = ""
$AnalysisServer = ""
$SQLIaaS1 = ""
$SQLIaaS2 = ""
$SQLDB1 = ""
$SQLDB2 = ""
$SQLDB3 = ""
$servicePrincipalConnection = Get-AutomationConnection -Name "AzureRunAsConnection"

#Logging into Azure using Run As account
Add-AzureRmAccount -ServicePrincipal -TenantId $servicePrincipalConnection.TenantId -ApplicationId $servicePrincipalConnection.ApplicationId -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 

#Set variables for "Low" responce
If ($Scale -eq "Low") {
    $VMSize = "Standard_D1_v2"
    $AnalysisSize = "S0"
    $vCores = 2
}

#Set variables for "Medium" responce
If ($Scale -eq "Medium") {
    $VMSize = "Standard_D11_v2"
    $AnalysisSize = "S1"
    $vCores = 8
}

#Set variables for "High" responce
If ($Scale -eq "High") {
    $VMSize = "Standard_D12_v2"
    $AnalysisSize = "S4"
    $vCores = 24
}

#Set variables for "Off" responce plus deallocation of services
If ($Scale -eq "Off") {
    Stop-AzureRmVM -ResourceGroupName $ResourceGroup -Name dv-vm-ne-dwsql1 -Force;
    Stop-AzureRmVM -ResourceGroupName $ResourceGroup -Name dv-vm-ne-dwsql2 -Force;
    Suspend-AzureRmAnalysisServicesServer -Name $AnalysisServer -ResourceGroupName $ResourceGroup
    $Vcores = 1
    "Deallocating IaaS SQL servers"
    "Pausing Analysis Services Server"
    "Lowering DBs to 1 vCore"
}

#echo decisions made
If ($Scale -ne "Off") {
    "Scale set to $Scale"
    "Setting Analysis Services Server to $AnalysisSize"
    "Setting DBs to $Vcores vCores"
    "Setting VMs to $VMSize"

        
    #Scaling DBs
    Set-AzureRmSqlDatabase -ResourceGroupName $ResourceGroup -ServerName $SQLServer -DatabaseName $SQLDB1 -Edition "GeneralPurpose" -Vcore $vCores -ComputeGeneration "Gen4"
    Set-AzureRmSqlDatabase -ResourceGroupName $ResourceGroup -ServerName $SQLServer -DatabaseName $SQLDB2 -Edition "GeneralPurpose" -Vcore $vCores -ComputeGeneration "Gen4"
    Set-AzureRmSqlDatabase -ResourceGroupName $ResourceGroup -ServerName $SQLServer -DatabaseName $SQLDB3 -Edition "GeneralPurpose" -Vcore $vCores -ComputeGeneration "Gen4"

    #Scaling Analysis Services      
    Set-AzureRmAnalysisServicesServer -name $AnalysisServer -ResourceGroupName $ResourceGroup -sku $AnalysisSize

    #Scaling IaaS SQL1
    $vm = Get-AzureRmVM -ResourceGroupName $ResourceGroup -VMName $SQLIaaS1
    $vm.HardwareProfile.VmSize = $VMSize
    Update-AzureRmVM -VM $vm -ResourceGroupName $ResourceGroup

    #Scaling IaaS SQL2
    $vm = Get-AzureRmVM -ResourceGroupName $ResourceGroup -VMName $SQLIaaS2
    $vm.HardwareProfile.VmSize = $VMSize
    Update-AzureRmVM -VM $vm -ResourceGroupName $ResourceGroup

    #Ensuring all services are running if $scale isnt set to "off"
    If ($Scale -ne "Off") {
        Start-AzureRmVM -ResourceGroupName $ResourceGroup -Name $SQLIaaS1
        Start-AzureRmVM -ResourceGroupName $ResourceGroup -Name $SQLIaaS2
        #    Resume-AzureRmAnalysisServicesServer -Name $AnalysisServer -ResourceGroupName $ResourceGroup
    }

    #Get post scale resource information
    $PostAnalysisSize = Get-AzureRmAnalysisServicesServer -ResourceGroupName $ResourceGroup -Name $AnalysisServer
    $PostvCoresDB1 = get-AzureRmSqlDatabase -ResourceGroupName $ResourceGroup -ServerName $SQLServer -DatabaseName $SQLDB1
    $PostvCoresDB2 = get-AzureRmSqlDatabase -ResourceGroupName $ResourceGroup -ServerName $SQLServer -DatabaseName $SQLDB2
    $PostvCoresDB3 = get-AzureRmSqlDatabase -ResourceGroupName $ResourceGroup -ServerName $SQLServer -DatabaseName $SQLDB3
    $Postvm1 = Get-AzureRmVM -ResourceGroupName $ResourceGroup -VMName $SQLIaaS1
    $Postvm2 = Get-AzureRmVM -ResourceGroupName $ResourceGroup -VMName $SQLIaaS2
    $PostvCoresDB1name = $PostvCoresDB1.name
    $PostvCoresDB1cap = $PostvCoresDB1.Capacity

    #Echo Post script resource information
    If ($Scale -ne "Off") {
        "Analysis Services Server" 
        "Requested: $AnalysisSize" 
        "$PostAnalysisSize.Name: $PostAnalysisSize.sku"
        "Databases"
        "Number of vCores requested: $Vcores"
        "$PostvCoresDB1name"
        "$PostvCoresDB2.DatabaseName: $PostvCoresDB2.Capacity"
        "$PostvCoresDB3.DatabaseName: $PostvCoresDB3.Capacity"
        "Virtual Machines"
        "Requested: $VMSize"
        "$Postvm1.Name: $Postvm1.HardwareProfile"
    }
}
