param (
    [parameter(Mandatory = $true)]
    [ValidateNotNullorEmpty()]
    [string]$OrganizationName,
    [parameter(Mandatory = $true)]
    [ValidateNotNullorEmpty()]
    [string]$Pat,
    [parameter(Mandatory = $true)]
    [ValidateNotNullorEmpty()]
    [string]$agentaccount,
    [parameter(Mandatory = $true)]
    [ValidateNotNullorEmpty()]
    [string]$agentpass,
    [parameter(Mandatory = $true)]
    [ValidateNotNullorEmpty()]
    [string]$installaccount,
    [parameter(Mandatory = $true)]
    [ValidateNotNullorEmpty()]
    [string]$installpass,
    [parameter(Mandatory = $true)]
    [ValidateNotNullorEmpty()]
    [string]$pool,
    [parameter(Mandatory = $true)]
    [ValidateNotNullorEmpty()]
    [string]$agents
)

# take the string of vm names and create an array, splitting at the comma 
$agentarray = $agents.Split(',')

# create credential object to be used to invoke command
$userName = $installaccount
$userPassword = $installpass
$secStringPassword = ConvertTo-SecureString $userPassword -AsPlainText -force
$credObject = New-Object System.Management.Automation.PSCredential ($userName, $secStringPassword)

# run the script on each of the agents 
foreach ($agent in $agentarray) {

    # invoke the scriptblock on each agent passing through the needed params
    Invoke-Command -ComputerName "$agent.intra.mps-group.org" -ArgumentList $OrganizationName, $Pat, $agentaccount, $agentpass, $pool -ScriptBlock {  
        
        # create the params within the nested script
        param (
            [parameter(Mandatory = $true)]
            [ValidateNotNullorEmpty()]
            [string]$OrganizationName,
            [parameter(Mandatory = $true)]
            [ValidateNotNullorEmpty()]
            [string]$Pat,
            [parameter(Mandatory = $true)]
            [ValidateNotNullorEmpty()]
            [string]$agentaccount,
            [parameter(Mandatory = $true)]
            [ValidateNotNullorEmpty()]
            [string]$agentpass,
            [parameter(Mandatory = $true)]
            [ValidateNotNullorEmpty()]
            [string]$pool
        )
        
        # add service account to local admin group
        try {
            Add-LocalGroupMember -Group "Administrators" -Member "MPSNT\DevOpsAgent"
        }
        catch {
            Write-Host "DevOps Agent account already in local admin group"
        }
        # Check if agent is already downloaded and if not download
        if (-not(Test-Path -Path "c:\Windows\Temp\vsts-agent-win-x64-2.213.2.zip")) {
            try {
                Invoke-WebRequest -Uri https://vstsagentpackage.azureedge.net/agent/2.213.2/vsts-agent-win-x64-2.213.2.zip -OutFile c:\\Windows\\Temp\\vsts-agent-win-x64-2.213.2.zip
                Expand-Archive -LiteralPath 'C:\\Windows\\Temp\\vsts-agent-win-x64-2.213.2.zip' -DestinationPath 'C:\\DevOpsAgent\\Agent' -Force
            }
            catch {
                throw $_.Exception.Message
            }
        }

        # Check if agent is isntalled ad if not install 
        $service = get-service | Where-Object { $_.Name -like "vstsagent*" }
        if ($service.Status -eq $null) {
            Write-Host "Installing Agent"
            Set-Location "C:\DevOpsAgent\Agent"
            $agentname = $env:computername
            & .\config.cmd --unattended --url https://dev.azure.com/$OrganizationName --auth pat --token $Pat --pool $pool --agent $agentname --runAsService --windowsLogonAccount $agentaccount --windowsLogonPassword $agentpass --replace
        }
        else {
            Write-Host "Agent Already Installed"
        }  
    }  -Credential $credObject
}



