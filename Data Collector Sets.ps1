# Get list of servers to audit
$servers = import-csv -Path "C:\Temp\servers.csv"

# Get credentials for folder creation (if needed)
$creds = Get-Credential

# Path of the data collector set template xml file
$XMLPathOS = "C:\Test\OS.xml"
$XMLPathSQL = "C:\Test\SQL.xml"


$DataCollectorName = "SQL Audit"


Foreach ($server in $servers)
    {
    # Get server name
    $name = $server.server

    # Test if Temp directory exists for the XML transfer and create if not
    If(!(test-path "\\$name\c$\Temp"))
        {
        New-PSDrive -Name NewPSDrive -PSProvider FileSystem -Root "\\$name\c$" -Credential $creds
        New-Item -ItemType Directory NewPSDrive:\Temp -Force
        }

        # Copy XMLs to remote server
        Write-Host "Copying XMLs"-ForegroundColor Green
        Copy-Item $XMLPathOS "\\$name\c$\Temp"
        Copy-Item $XMLPathSQL "\\$name\c$\Temp"

        # Create Data Collector Set for the OS on remote machine using copied XML
        Write-Host "Creating OS DCS"-ForegroundColor Green
        Invoke-Command -ComputerName $Server.server -ArgumentList $DataCollectorName -ScriptBlock `
            {
            param($DataCollectorName)
            $datacollectorset = New-Object -COM Pla.DataCollectorSet
            $xml = Get-Content C:\temp\OS.xml
            $datacollectorset.SetCredentials($null,$null)
            $datacollectorset.SetXml($xml)
            $datacollectorset.Commit("$DataCollectorName-OS" , $null , 0x0003) | Out-Null
            $datacollectorset.start($false)
            }

            # Find all installed SQL Instances 
            Write-Host "Finding Instances"-ForegroundColor Green
            $instances = Invoke-Command -ComputerName $Server.server -ScriptBlock {
            (get-itemproperty 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server').InstalledInstances
            }

            # Loop through each instance to create Data Collection Set for each
            foreach ($Instance in $Instances) 
                {
                # Create variable that will contain instance name in a certain format for perfmon
                If ($Instance -eq "MSSQLSERVER") {$InstanceName = "SQLServer";}
                ELSE {$InstanceName = "MSSQL`$$Instance";}

                # Create Data Collection Set for each instance 
                Write-Host "Creating SQL DCS Per Instance"-ForegroundColor Green
                Invoke-Command -ComputerName $Server.server -ArgumentList $DataCollectorName -ScriptBlock `
                    {
                    param($DataCollectorName)
                    $datacollectorset = New-Object -COM Pla.DataCollectorSet
                    $xml = (Get-Content "C:\temp\SQL.xml") -replace "%instance%", $Using:InstanceName -replace "%name%", $Using:Instance
                    $datacollectorset.SetCredentials($null,$null)
                    $datacollectorset.SetXml($xml)
                    $datacollectorset.Commit("$DataCollectorName-$Using:Instance" , $null , 0x0003) | Out-Null
                    $datacollectorset.start($true)
                    #Start-SMPerformanceCollector -CollectorName "$DataCollectorName-$Using:InstanceName"
                    }
                }

    # Clean up copied files
    Remove-Item "\\$name\c$\Temp\SQL.xml"
    Remove-Item "\\$name\c$\Temp\OS.xml"
  }


