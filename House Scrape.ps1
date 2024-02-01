# create empty vars
$plotnumber = @()
$cost = @()
$output = @()
$out = @()

# get all available house types
$links = (Invoke-WebRequest "https://www.persimmonhomes.com/new-homes/yorkshire/germany-beck").links | Where-Object { $_.innerText -eq "View more information" }

# for each house type get plots 
foreach ($link in $links) {
    $href = ($link.href | Out-String) # pulls house link
    $house = $href.split('/')[4]                # 
    $TextInfo = (Get-Culture).TextInfo          # gets house name from url & cleans
    $houseclean = $house -replace '-', ' '      #
    $name = $TextInfo.ToTitleCase($houseclean)  #
    $request = (Invoke-WebRequest "https://www.persimmonhomes.com$href").content # gets house info
    $lines = $request.Split([Environment]::NewLine) # makes content searchable 
    $plots = $lines | Select-String -Pattern "<div class=`"table-mobile-layout__cell-body`">" -Context 1 -AllMatches # pull back all plot number and prices
    $i = 1 # used to create object only after each plot and price have been looped

    # get plot numbers and prices for each plot
    foreach ($plot in $plots) {
        $i++ # every other loop creates output with both plot and price
        # get plot number and tidy
        if ($plot -like "*</div>*") {
            $plotnumber = ($plot.line.Split('>')[1]).trimend("</div") 
        }
        # get price and tidy
        else {
            $cost = ($plot.line.Split('>')[1].trim()) -replace '&#163;', ''  # .trimstart("&#163;")
            if ($cost -eq "Reserved") { $cost = 0 }
        }
        # every other loop creates output with both plot and price
        if ([int]($i) % 2 -eq 1) {
            $out = New-Object psobject -Property @{
                "Name" = $name
                "Plot" = $plotnumber
                "Cost" = $cost
                "Date" = Get-Date
            }
            $output += $out
        }
    }
}

$output

