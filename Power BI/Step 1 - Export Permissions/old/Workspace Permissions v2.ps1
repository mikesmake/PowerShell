$creds = Login-PowerBIServiceAccount

$Workspaces = Get-PowerBIWorkspace -all -Scope Organization

Clear-Variable -Name results

$Workspaces | ForEach-Object {

    $WorkspaceName = $_.name
    $WorkspaceDescription = $_.description
    $WorkspaceType = $_.type
    $WorkspaceState = $_.state
    $WorkspaceId = $_.id
    #$Users = $_.users


    Foreach ($user in $_.users)
    {
        $results += ,@($WorkspaceName,$WorkspaceDescription, $WorkspaceType,$WorkspaceState,$WorkspaceId,$user.Identifier, $User.AccessRight)
    }

    }

    $Export = @()

       $Headings = @("WorkspaceName","WorkspaceDescription","WorkspaceType","WorkspaceState","WorkspaceId","UserName","Access")
       foreach ($row in $results)

       {
       $obj = New-Object PSObject
       for ($i=0;$i -lt $Headings.count; $i++)
       {
       $obj | Add-Member -MemberType NoteProperty -Name $Headings[$i] -Value $row[$i]
       }

       $Export += $obj
       $obj = $null
       
       }
    
    
    $Export | Export-Csv -Path C:\PowerShell\Berry\v2Permissions.csv




#    $results | measure
#    $Export | measure
#    $Workspaces | measure
#    $Users | measure 
#    
#
#
#
