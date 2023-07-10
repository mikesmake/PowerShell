$Servers = Get-ADGroupMember -Identity "SQL Servers"


$results = @()


foreach ($server in $servers)
{
    $results += Get-SqlInstance -ServerInstance $server.name -EA SilentlyContinue
}


$results | select name,Edition,Collation,PhysicalMemory,PhysicalMemoryUsageInKB,Processors,ProcessorUsage,Productlevel,ServerType,ServiceAccount,ServerVersion,State,Status,Version