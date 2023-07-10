$credential = Get-Credential

Connect-PowerBIServiceAccount -Credential $credential

$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $credential -Authentication Basic -AllowRedirection

Import-PSSession $Session

$Groups = Get-PowerBIWorkspace

$Members = $Groups | ForEach-Object {
    $group = $_
    Get-UnifiedGroupLinks -Identity $group.Name -LinkType Members -ResultSize Unlimited | ForEach-Object {
        $member = $_
        New-Object -TypeName PSObject -Property @{
            User = $member.Name
            Group = $group.Name
            Access = "Member"
        }
    }
}  


$Owners = $Groups | ForEach-Object {
    $group = $_
    Get-UnifiedGroupLinks -Identity $group.Name -LinkType Owners -ResultSize Unlimited | ForEach-Object {
        $member = $_
        New-Object -TypeName PSObject -Property @{
            User = $member.Name
            Group = $group.Name
            Access = "Owner"
        }
    }
}  


$AllUser = ($Owners + $Members) 

$AllUser | Export-Csv -Path "C:\PowerShell\Berry\PowerBIGroups.csv" -NoTypeInformation