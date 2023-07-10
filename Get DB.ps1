$Servers = Get-ADGroupMember -Identity "SQL Servers"
$DBName = read-host -Prompt 'Database Name'

$results = @()

foreach ($server in $servers)
{
    $results += Get-SqlDatabase -ServerInstance $server.name -Name $DBName -EA SilentlyContinue
}


$MoreDetails = read-host -Prompt 'Would you like detailed DB information? (No for just loacation)'


if ($MoreDetails -eq 'Yes'){$results | select name,parent,status,recoverymodel,owner,collation | ft}
Else {$results | select name,parent}


