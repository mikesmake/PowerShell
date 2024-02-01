$links = (Invoke-WebRequest "https://www.persimmonhomes.com/new-homes/yorkshire/germany-beck").links | Where-Object { $_.innerText -eq "View more information" }


$plotnumber = @()
$cost = @()
$output = @()

foreach ($link in $links) {
    $href = ($link.href | Out-String)
    $name = $href.split('/')[4]
    $r = (Invoke-WebRequest "https://www.persimmonhomes.com$href").content  

    $lines = $r.Split([Environment]::NewLine)

    $plots = $lines | Select-String -Pattern "<div class=`"table-mobile-layout__cell-body`">" -Context 1 -AllMatches
       

    foreach ($plot in $plots) {
        $housename = $name

        if ($plot -like "*</div>*") {

            $plotnumber = ($plot.line.Split('>')[1]).trimend("</div") 
        }

        else {
            $cost = ($plot.line.Split('>')[1].trim()).trimstart("&#163;")
        }

        $out = New-Object psobject -Property @{
            "Name" = $name
            "Plot" = $plotnumber
            "Cost" = $cost
        }

        $output += $out

    }

}