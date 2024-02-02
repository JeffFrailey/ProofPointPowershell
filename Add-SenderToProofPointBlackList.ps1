<#
Creator: JFrailey
Creation Date: 01/31/2024
Last Updated: 02/02/2024
Scope: Add an email sender to proofpoint's blacklist via REST API with PowerShell. 
#> 

#Check for existing session with ProofPoint variables so you don't have to enter them if you want to loop in your ISE.
#Connect if null
if($Session -eq $null){
    #Get user admin info
    $AdminUser = Read-Host "Please enter your ProofPoint admin email"
    $AdminPass = Read-Host "Please enter your ProofPoint admin email pass"
    #Pre-defined variables
    #Note, you have to define your domain URL before the script will work.
    $URI = "https://us5.proofpointessentials.com/api/v1/orgs/<DOMAINHERE>/sender-lists"
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("content-type", "application/json")
    $headers.Add('X-User', $AdminUser)
    $headers.Add('X-Password', $AdminPass)
    #Set session variable check to true
    $Session = $true
}#End statement to declare credential and domain session variables


#Variables
#Get script user input
$SpamSender = Read-Host "Please enter the email to block at the ORG level in ProofPoint"

#Invoke GET the existing senders list
$ExistingSenders = Invoke-RestMethod -Uri $URI -Headers $headers -Method Get | select-object block_list
#Take the initial senders request and convert it to JSON format
$Body = ConvertTo-Json -InputObject @( $ExistingSenders )

#Inject the Spam Sender variable into the string JSON object 
#Get the first half of the string
$BodyLastEntry = $Body.LastIndexOf('"')
$BodyStart = $Body.Substring(0,$BodyLastEntry)
#Inject the spam sender into the body
$BodyMiddle = ($BodyStart + '",' + "`n" + "`t`t`t   " +  '"' + "$SpamSender")
#Get the end characters of the origonal string
$BodyEnd = $Body.Substring($BodyLastEntry)
#Compile
$NewBodyString = ($BodyMiddle + $BodyEnd)
#Trim the start
$IndexStart = $NewBodyString.IndexOf("{")
$NewBodyString = $NewBodyString.Substring($IndexStart)
#Trim the end
$IndexEnd = $NewBodyString.LastIndexOf("}")
$NewBodyString = $NewBodyString.Substring(0,$IndexEnd + 1)

#Invoke POST the existing senders list
#Note, after you finish this invoke the ProofPoint admin portal may not reflect the change for some time.
#Browsing to the URL that contains the safe-sender list above will display the change.
Invoke-RestMethod -Uri $URI -Headers $headers -Method PATCH -Body $NewBodyString 


