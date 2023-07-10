#SMTP details
$SMTPServer = ''
$smtpFrom = "" 
$smtpTo = @('') 
$messageSubject = "ADFS Issue!" 
$body = 'ADFS Serivce isnt responding, please investigate'


$HTTP_Request = [System.Net.WebRequest]::Create('https://office.simassoc.co.uk/adfs/ls/IdpInitiatedSignon.aspx')

try{

$HTTP_Response = $HTTP_Request.GetResponse()
$HTTP_Status = [int]$HTTP_Response.StatusCode

If ($HTTP_Status -eq 200) {
    Write-Host "Site is OK!"
}
Else {
    Send-MailMessage -From $smtpFrom -To $smtpTo -Subject $messageSubject -Body $body -BodyAsHtml -SmtpServer $SMTPServer
    Write-Host "Failed"
}

$HTTP_Response.Close()
}

catch{
    Send-MailMessage -From $smtpFrom -To $smtpTo -Subject $messageSubject -Body $body -BodyAsHtml -SmtpServer $SMTPServer
    Write-Host "Double failed!"
}


