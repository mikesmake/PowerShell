param (
    [parameter(Mandatory = $true)]
    [ValidateNotNullorEmpty()]
    [string]$pass,
	[parameter(Mandatory = $true)]
    [ValidateNotNullorEmpty()]
    [string]$environment
)


#set instance name to match MAPS
$instanceName = $environment

# check if script is running on node 01
if ($env:computerName.contains("01")) {

#install RSTA tools to add New-ADUser cmdlet 
Install-WindowsFeature RSAT

# list off accounts to create 
$accounts_main = "IDITADMIN","IDITMONITOR"
$accounts_system = "IDITSPNEGO","MAPSIDITSVC"

#$accounts = "IDITSPNEGO"

# Create accounts "IDITADMIN" needs shorter pass so doesnt get serivce name in the pass
foreach ($account in $accounts_main)
        {
        Write-host -ForegroundColor Cyan "Creating $account account"
        if($account -eq "IDITADMIN"){write-host "IDITADMIN = $pass" 
        $servicepass = $pass}
        else{write-host "Pass = $pass$account" 
        $servicepass = $pass+$account}
        $name = $instanceName+$account
        $samname = $instanceName+$account
        $upn = $instanceName+$account+"@intra.mps-group.org"
        $path = "OU=Users,OU=Main,DC=intra,DC=mps-group,DC=org"
        $Description = $instanceName+$account+" Service account"
        $secpass = ConvertTo-SecureString -String $servicepass -AsPlainText -Force
        Try {
            New-ADUser -Name $name -SamAccountName $samname -UserPrincipalName $upn -Path $path -Description $Description -AccountPassword $secpass -Enabled $true
            }
        catch{
            Write-Warning -Message "$account already exsists"
            }
        }

foreach ($account in $accounts_system)
        {
        Write-host -ForegroundColor Cyan "Creating $account account"
        if($account -eq "IDITADMIN"){write-host "IDITADMIN = $pass" 
        $servicepass = $pass}
        else{write-host "Pass = $pass+$account" 
        $servicepass = $pass+$account}
        $name = $instanceName+$account
        $samname = $instanceName+$account
        $upn = $instanceName+$account+"@intra.mps-group.org"
        $path = "OU=MAPS,OU=System Accounts,OU=Main,DC=intra,DC=mps-group,DC=org"
        $Description = $instanceName+$account+" Service account"
        $secpass = ConvertTo-SecureString -String $servicepass -AsPlainText -Force
        Try {
            New-ADUser -Name $name -SamAccountName $samname -UserPrincipalName $upn -Path $path -Description $Description -AccountPassword $secpass -Enabled $true
            }
        catch{
            Write-Warning -Message "$account already exsists"
            }
        }


# create SPN commands 
$SPN = "setspn -A HTTP`/maps-"+$instanceName+" mpsnt`\"+$instanceName+"IDITSPNEGO"
$FQDNSPN = "setspn -A HTTP`/maps-"+$instanceName+".mps-dev.org mpsnt`\"+$instanceName+"IDITSPNEGO"

# execute SPN commands
Invoke-Expression -Command $SPN
Invoke-Expression -Command $FQDNSPN


# create ktpass command 
$ktpass = "ktpass -out c:\Service\mps-app2.keytab -princ HTTP`/maps-"+$instanceName+".mps-dev.org@intra.mps-group.org -mapuser mpsnt`\"+$instanceName+"IDITSPNEGO -pass $pass`IDITSPNEGO` -ptype KRB5_NT_PRINCIPAL -crypto AES128-SHA1"

# execute ktpass commands
Invoke-Expression -Command $ktpass

# Copy keytab to websphere
Write-Host "Copying mps-app2.keytab to F:\IBM\WebSphere\AppServer"
Copy-Item -Path c:\Service\mps-app2.keytab -Destination F:\IBM\WebSphere\AppServer

# set IDITSPNEGO account to support AES128
Set-ADUser -Identity $instanceName"IDITSPNEGO" -KerberosEncryptionType AES128

$DCs = "LDSDC02.intra.mps-group.org","AZUKSDC01.intra.mps-group.org"
$identity = $instanceName+"IDITADMIN"

Foreach ($DC in $DCs){
    do{
        try{
        $user = $null
        $user = Get-ADUser -server $DC -identity $identity -ErrorAction Stop
        Write-host -ForegroundColor Cyan   "$DC - OK"
        } 
        catch{
        write-warning  "$DC - Not OK"
        Sleep 60
        }
    } 
    until($user)
    }
}


# if script is running on node 02
else{
    Write-Host "Copying mps-app2.keytab from $instanceName Node 01 to F:\IBM\WebSphere\AppServer"
    $path = "\\maps-d-app01-$instanceName\f$\IBM\WebSphere\AppServer\mps-app2.keytab"
     Copy-Item -Path \\maps-d-app01-$instanceName\f$\IBM\WebSphere\AppServer\mps-app2.keytab  -Destination F:\IBM\WebSphere\AppServer
    }