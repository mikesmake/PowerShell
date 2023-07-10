#############################################################
#Group details
$SQLGroup = "SQL Servers"

#SMTP details
$SMTPServer = ''
$smtpFrom = "" 
$smtpTo = @('') 
$messageSubject = "SQL server Details"

#Export Details
$CSVLocation = "C:\Temp\SQLDetails.csv"
#############################################################

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
    $results += Get-SqlInstance -ServerInstance $instance.name -EA SilentlyContinue
}

#Ask user if they wish display the results on screen
Write-host ''
Write-host ================= -ForegroundColor Green
Write-host Display Results? -ForegroundColor Green
Write-host ================= -ForegroundColor Green
$OnScreen = Read-Host -Prompt 'Do you wish to display the results here?'

#Display results if users requested 
if($OnScreen -eq "yes"){$results | select name,Edition,Collation,PhysicalMemory,PhysicalMemoryUsageInKB,Processors,ProcessorUsage,Productlevel,ServerType,ServiceAccount,ServerVersion,State,Status,Version}

#Ask user if they wish to be emailed the results 
Write-host ''
Write-host ================= -ForegroundColor Green
Write-host Email Results? -ForegroundColor Green
Write-host ================= -ForegroundColor Green
$Email = Read-Host -Prompt "Do you wish to email the results to $smtpTo`?"

#Send email if requested 
if($Email -eq "yes"){

#Used to format email
$style = “<Style>BODY{font-family: Arial; font-size: 10pt;}</Style>”                              
$style = $style + “<Style>TABLE{border: 1px solid black; border-collapse: collapse;}</Style>”     
$style = $style + “<Style>TH{border: 1px solid black; background: #dddddd; padding: 5px;}</Style>” 
$style = $style + “<Style>TD{border: 1px solid black; padding: 5px;}</Style>”      
#Clears the body variable
$body = ''
#Creates the table for the eamil
$body += $results | select name,Edition,Collation,PhysicalMemory,PhysicalMemoryUsageInKB,Processors,ProcessorUsage,Productlevel,ServerType,ServiceAccount,ServerVersion,State,Status,Version | convertto-html -Head $style 
#Sends mail
Send-MailMessage -From $smtpFrom -To $smtpTo -Subject $messageSubject -Body $body -BodyAsHtml -SmtpServer $SMTPServer
}

#Ask user if they wish to export the results
Write-host ''
Write-host ================= -ForegroundColor Green
Write-host Export Results? -ForegroundColor Green
Write-host ================= -ForegroundColor Green
$Export = Read-Host -Prompt "Do you wish to export the results to $CSVLocation`?"

#Export if requested
if($Export = "Yes"){$results | Export-Csv -Path $CSVLocation}