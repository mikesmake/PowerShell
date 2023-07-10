$Servers =  Get-ADGroupMember -Identity "Servers" 


Foreach ($server in $servers)

{

if (Test-Connection -Count 1 -Quiet -ComputerName $server.name) {

write-host $server.name -ForegroundColor Green

schtasks.exe /query /s $server.name /V /FO CSV | ConvertFrom-Csv | Where { $_.'Run As User' -like 'domain\*' -and $_.TaskName -notlike '\Optimize Start Menu Cache Files*' -and $_.TaskName -notlike '\User_Feed_Synchronization*' -and $_.TaskName -notlike '\WPD*' } | ft Hostname,Taskname,'Run As User'

}

#Write-Host $server.name


}



Clear-Variable -Name