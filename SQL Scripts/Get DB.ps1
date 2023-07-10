##############################################
#Group details
$SQLGroup = "SQL Servers"

#Export Details
$CSVLocation = "C:\Temp\SQLDetails.csv"
##############################################


#Get DB to find from user
$DBName = read-host -Prompt 'Database Name'

#Get servers to check
$Servers = Get-ADGroupMember -Identity $SQLGroup

#Get all instances per server
$instances = @()
foreach ($server in $servers){
    $instances += $server.name | % {Get-ChildItem -Path "SQLSERVER:\SQL\$_"}| Select-Object -Property @{label='ServerName';expression={$_.ComputerNamePhysicalNetBIOS}}, Name, DisplayName, InstanceName
}

#Get all SQL Agent jobs where last outcome equals "failed" from each instance 
$results = @()
foreach ($instance in $instances){
    $results += Get-SqlDatabase -ServerInstance $instance.name -Name $DBName -EA SilentlyContinue
}

#Ask user if they wish to view detailed or basic info
Write-host ''
Write-host ================= -ForegroundColor Green
Write-host Detailed Info? -ForegroundColor Green
Write-host ================= -ForegroundColor Green
$MoreDetails = read-host -Prompt 'Would you like detailed DB information? (No for just loacation)'

#Display requested info
if ($MoreDetails -eq 'Yes'){$results | select name,parent,status,recoverymodel,owner,collation | ft}
Else {$results | select name,parent}

#Ask user if they wish to export the results
Write-host ''
Write-host ================= -ForegroundColor Green
Write-host Export Results? -ForegroundColor Green
Write-host ================= -ForegroundColor Green
$Export = read-host -Prompt "Do you wish to export the results to $CSVLocation`?"

#Export if requested
if($Export = "Yes"){$results | Export-Csv -Path $CSVLocation}