# API call to get a list of all venues
$AllVenues = Invoke-RestMethod -Uri ""



# Pull the data from the API response into a variable
$VenuesData = $AllVenues.data

# Add two blank columns to populate later
$VenuesData  | Add-Member -NotePropertyName Visits -NotePropertyValue NULL
$VenuesData  | Add-Member -force -NotePropertyName Date -NotePropertyValue NULL


$HistDate = Import-Csv -path C:\Temp\test.csv | Get-Date -UFormat "%Y-%m-%d"

Foreach ($date in $HistDate)
{


# For each venue brought back from eariler API call do a seperate API call to differnt endpoint and pass data through to additional columns created earlier
Foreach ($Venue in $VenuesData) 
{$ID = $Venue.id
 $Overview = Invoke-RestMethod -Uri "$date&dateStop=$date&venueId=$ID&timeZone=UTC&api_version=v2.0&api_key=";
 $visits = $Overview.results
 $Venue.Visits = $visits.visits
 $Venue.Date = $date
 $New += $VenuesData
 Write-Host $new
}

Write-Host $date
}

# Output data 
$New | select-object id,name,@{L=’Alias’;E={$_.description}},Visits,Date | export-csv -NoTypeInformation -Path C:\temp\footfall.csv
