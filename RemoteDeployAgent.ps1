param (
    [parameter(Mandatory = $true)]
    [ValidateNotNullorEmpty()]
    [string]$ResourceGroupName,
    [parameter(Mandatory = $true)]
    [ValidateNotNullorEmpty()]
    [string]$OrganizationName,
    [parameter(Mandatory = $true)]
    [ValidateNotNullorEmpty()]
    [string]$Pat,
    [parameter(Mandatory = $true)]
    [ValidateNotNullorEmpty()]
    [string]$deploymentGroup,
    [parameter(Mandatory = $true)]
    [ValidateNotNullorEmpty()]
    [string]$tags,
    [parameter(Mandatory = $true)]
    [ValidateNotNullorEmpty()]
    [string]$project
)

# Find the VMs in the resource group
$VMs = Get-AzResource -ResourceType Microsoft.Compute/virtualMachines -ResourceGroupName $ResourceGroupName
if ($null -eq $VMs) {
    Throw "No App VMs foud in the resourcegroup"
}
$Location = (Get-AzResourceGroup $ResourceGroupName).Location

foreach ($VM in $VMs) {
    $VmName = $VM.Name
    $protectedSettings = @{
        "commandToExecute" = "powershell -ExecutionPolicy Unrestricted -File c:\DevOpsAgent\Install-Agent.ps1 -OrganizationName $OrganizationName -project $project -deploymentGroup $deploymentGroup -tags $tags -pat $Pat"
    }

    # See if the WinRMextension is still active. If it is, uninstall it as only one Custom Script extension is permitted.
    $VMExtention = Get-AzVMExtension -ResourceGroupName $ResourceGroupName -VMName $VmName | Where-Object {$_.Name -eq "WinRMCustomScriptExtension" -or $_.Name -eq "Install-Agent" }
    if ($VMExtention) {
        $VMExtention | Remove-AzVMExtension -Force
    }

    # Create the parameters for the extension
    $parameters = @{
        ResourceGroupName  = $ResourceGroupName
        VmName             = $VmName
        Location           = $Location
        Name               = "install-agent"
        Publisher          = "Microsoft.Compute"
        ExtensionType      = "CustomScriptExtension"
        TypeHandlerVersion = "1.9"
        ProtectedSettings  = $protectedSettings
    }

    # Create the extension
    Set-AzVMExtension @Parameters -Verbose

}