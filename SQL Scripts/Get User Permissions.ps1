########################
#Group details
$SQLGroup = "SQL Servers"

#Export Details
$path = 'C:\Temp\'
########################

#Get servers to check from user
$Hostname = read-Host -Prompt "Get Permissions from which SQL Server? (Use 'All' for all Servers in '$SQLGroup')"

#Process users input to array of server objects and get all instaces per server
if ($Hostname -eq 'All'){$servers = Get-ADGroupMember -Identity $SQLGroup
    $instances = @()
        foreach ($server in $servers){
        $instances += $server.name | % {Get-ChildItem -Path "SQLSERVER:\SQL\$_"}| Select-Object -Property @{label='ServerName';expression={$_.ComputerNamePhysicalNetBIOS}}, Name, DisplayName, InstanceName
        }
}
Else {
$instances = New-Object -TypeName psobject

$instances | Add-Member -MemberType NoteProperty -Name Name -Value $Hostname

}

#Get instance role permissions per instance
foreach ($instance in $instances){

        $DBs =  Get-SqlDatabase -ServerInstance $instance.name
        $foldername = $instance.Name
        $foldername = $foldername.replace('\','_') 
        New-Item -Path $path -Name $foldername -ItemType "directory"
        $DirPath = "$path$foldername"

        Invoke-Sqlcmd -Query "SELECT sys.server_role_members.role_principal_id, role.name AS RoleName,   
        sys.server_role_members.member_principal_id, member.name AS MemberName  
        FROM sys.server_role_members  
        JOIN sys.server_principals AS role  
        ON sys.server_role_members.role_principal_id = role.principal_id  
        JOIN sys.server_principals AS member  
        ON sys.server_role_members.member_principal_id = member.principal_id;" -ServerInstance $instance.Name   | Export-Csv -Path "$DirPath\Server Roles.csv"


#get permissions for each DB on each instance and output to csv in a folder called "instance name" 
foreach ($DB in $DBs){

        Write-Host $DB.name -ForegroundColor Green

        $filename = $DirPath +'\'+$DB.name+ '.csv'

        $Online =  Get-SqlDatabase -ServerInstance $instance.name -Name $DB.name -EA SilentlyContinue | select status

        Get-SqlDatabase -ServerInstance $instance.name -Name $DB.name -EA SilentlyContinue

        if($online.Status -ne "Normal"){Write-Host "$DB is offline" -ForegroundColor Red -BackgroundColor Black}
        else{Invoke-Sqlcmd -Query "
        SELECT DP1.name AS DatabaseRoleName,   
        isnull (DP2.name, 'No members') AS DatabaseUserName   
        FROM sys.database_role_members AS DRM  
        RIGHT OUTER JOIN sys.database_principals AS DP1  
        ON DRM.role_principal_id = DP1.principal_id  
        LEFT OUTER JOIN sys.database_principals AS DP2  
        ON DRM.member_principal_id = DP2.principal_id
        WHERE DP1.type = 'R'
        ORDER BY DP1.name;" -ServerInstance $instance.Name  -Database $DB.name | Export-Csv -Path $filename
        }
}

cd $DirPath;

#Get all csvs in instance name folder
$csvs = Get-ChildItem .\* -Include *.csv

#Create new excel doc 
$excelapp = new-object -comobject Excel.Application
$excelapp.sheetsInNewWorkbook = $csvs.Count
$xlsx = $excelapp.Workbooks.Add()
$sheet=1

#Create new sheet per csv and popluate with csv data
foreach ($csv in $csvs){
       
        $row=1
        $column=1
        $worksheet = $xlsx.Worksheets.Item($sheet)
        $worksheet.Name = $csv.Name
        $file = (Get-Content $csv)

            foreach($line in $file){
            $linecontents=$line -split ',(?!\s*\w+")'

                foreach($cell in $linecontents){
                $worksheet.Cells.Item($row,$column) = $cell
                $column++
                }
            $column=1
            $row++
            }
        $sheet++
}

#Save Excel document to "instance name" folder
$output = $DirPath + "\" + "All DBs.xlsx"
$xlsx.SaveAs($output)
$excelapp.quit()  
}