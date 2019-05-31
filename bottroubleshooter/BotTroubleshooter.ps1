param(
    [parameter(Mandatory = $true)]
    [string]
    $subscriptionId
) #Pass SubscriptionId and BotService Name (Web App Bot or Bot Channel Registration Name)

Function DisplayMessage2 {
    Param(
        [String]
        $Message,

        [parameter(Mandatory = $true)]
        [ValidateSet("Error", "Warning", "Info", "Input")]
        $Level
    )
    Process {
        if ($Level -eq "Info") {
            Write-Host -BackgroundColor White -ForegroundColor Black $Message `n
        }
        if ($Level -eq "Warning") {
            Write-Host -BackgroundColor Yellow -ForegroundColor Black $Message `n
        }
        if ($Level -eq "Error") {
            Write-Host -BackgroundColor Red -ForegroundColor White $Message `n
        }
        if ($Level -eq "Input") {
            Write-Host -BackgroundColor White -ForegroundColor Black $Message `n
        }
    }
}

Function DisplayMessage {
    Param(
        [String]
        $Message,

        [parameter(Mandatory = $true)]
        [ValidateSet("Error", "Warning", "Info", "Input")]
        $Level
    )
    Process {
        if ($Level -eq "Info") {
            Write-Host  -ForegroundColor Green $Message `n
        }
        if ($Level -eq "Warning") {
            Write-Host  -ForegroundColor Yellow $Message `n
        }
        if ($Level -eq "Error") {
            Write-Host  -ForegroundColor Red $Message `n
        }
        if ($Level -eq "Input") {
            Write-Host  -ForegroundColor Green $Message `n
        }
    }
}

#Function to make get/post REST Calls
Function ARMCall {
    Param(
        [String]
        $URI,
        [String]
        $bearerToken,
        [String]
        $Verb
    )

    $headers1 = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers1.Add("authorization", "Bearer $bearerToken")
    $headers1.Add("Accept", 'application/json')
    $headers = @{
        'authorization' = "Bearer $($bearerToken)"
	}

    $json = Invoke-RestMethod -Uri $URI  -Method $Verb -Headers $headers1

    return $json | ConvertTo-Json -Depth 10
}

function Get-UriSchemeAndAuthority {
    param(
        [string]$InputString
    )

    $Uri = $InputString -as [uri]
    if ($Uri) {
        return  $Uri.Authority
    }
    else {
        throw "Malformed URI"
    }
}

function DumpClaims {
    param(
        [string]$bearerToken
    )

    #Convert to right base 64 format
    $base64 = $bearerToken.Split('.')[1]
    $mod4 = $base64.Length % 4
    if ($mod4 -gt 0) {
        $tempstr = "=" * (4 - $mod4)
    }

    $frombase64 = [System.Convert]::FromBase64String($base64 + $tempstr)
    return [System.Text.Encoding]::UTF8.GetString($frombase64)
}

function AuthenticationResult {
    param(
        [string]$authorityUri,
        [String]$promptType
    )

    try {

        $app = New-Object Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext($authorityUri, $true, [Microsoft.IdentityModel.Clients.ActiveDirectory.TokenCache]::DefaultShared)
        $app = New-Object Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext($authorityUri, $true, [Microsoft.IdentityModel.Clients.ActiveDirectory.TokenCache]::DefaultShared)
        $uri = New-Object System.Uri($redirectUri)
        $prompt = [Microsoft.IdentityModel.Clients.ActiveDirectory.PromptBehavior]::$promptType
        $promptParam = New-Object Microsoft.IdentityModel.Clients.ActiveDirectory.PlatformParameters($prompt)
        $authenticationResult = $app.AcquireTokenAsync($resourceUri, $clientId, $uri , $promptParam).GetAwaiter().GetResult()
        $username = $authenticationResult.UserInfo.DisplayableId
        $bearerToken = $authenticationResult.AccessToken

        #test call to validate if the token is valid for that tenant.
        $test = ARMCall -URI "https://management.azure.com/subscriptions/$subscriptionId/?api-version=2014-04-01" -bearerToken $bearerToken -Verb "get"

        return $authenticationResult
    }
    catch {

        if ($_.ErrorDetails.Message.Contains("The access token is from the wrong issuer")) {

            $uri = [Regex]::Matches($_.ErrorDetails.Message, '(?<='')(.*?)(?='')') | Select -ExpandProperty Value
            AuthenticationResult $uri[$uri.Count - 1] "Auto"
        }
    }
}

#Load ADAL Library to Authenticate and get bearer token https://docs.microsoft.com/en-us/dotnet/api/overview/azure/activedirectory?view=azure-dotnet
Add-Type -Path "ADAL\Microsoft.IdentityModel.Clients.ActiveDirectory.dll"

#constants
$clientId = "1950a258-227b-4e31-a9cf-717495945fc2"
$resourceUri = "https://management.core.windows.net/"
$authorityUri = "https://login.microsoftonline.com/common"
$redirectUri = "urn:ietf:wg:oauth:2.0:oob"

# Get an Access Token with MSAL
$authenticationResult = AuthenticationResult $authorityUri "Always"
$username = $authenticationResult.UserInfo.DisplayableId
$bearerToken = $authenticationResult.AccessToken

if ($bearerToken -eq $null) {
    DisplayMessage -Message ("Login failed or you do not have access to the subscription : " + $subscriptionId) -Level Error
    return
   }
else {
    DisplayMessage -Message ("User $username Logged in") -Level Info
}

Function TroubleshootBotCreationPermissionIssues {

    DisplayMessage -Message ("Fetching the logged in token") -Level Info
    $claims = DumpClaims $bearerToken
    $tokenjson = $claims | ConvertFrom-Json
    $upn = $tokenjson.upn
    $principalid = $tokenjson.oid

    DisplayMessage -Message ("Getting all the role assignments for principalid " + $principalid) -Level Info

    $roleAssignmentsJSON = ARMCall -URI https://management.azure.com/subscriptions/$subscriptionId/providers/Microsoft.Authorization/roleAssignments?'$filter=principalId%20eq%20'+"'"+$principalid+"'"+'&api-version=2017-10-01-preview' -bearerToken $bearerToken -Verb "get"
    $roleAssignments = $roleAssignmentsJSON | ConvertFrom-Json
    $roledefinitonsarr = @()
    $actions = @()
    $notactions = @()

    if ($roleAssignments.value.Count -eq 0) {
        DisplayMessage -Message ("No role assignments found for the account, the user may be an OWNER of the account and you have full access") -Level Info
        return
    }

    if ($roleAssignments -ne $null) {

        DisplayMessage -Message ("Getting Role Definition ID's") -Level Info
        $roleAssignments.value.GetEnumerator() | foreach {
            $temp = $_.properties.roleDefinitionId + '?api-version=2015-07-01'
            $roledefinitionjson = ARMCall -URI "https://management.azure.com/$temp" -bearerToken $bearerToken -Verb "get"
            $roledefinition = $roledefinitionjson | ConvertFrom-Json
            $actions += $roledefinition.properties.permissions.actions
            $notactions += $roledefinition.properties.permissions.notactions
        }
    }

    $actioncontributor = "*";
    $actionbotserviceread = "Microsoft.BotService/botServices/read"
    $actionbotservicerwrite = "Microsoft.BotService/botServices/write"
    $actionbotservicerdelete = "Microsoft.BotService/botServices/delete"
    $actionbotserviceconnectionsread = "Microsoft.BotService/botServices/connections/read"
    $actionbotserviceconnectionswrite = "Microsoft.BotService/botServices/connections/write"
    $actionbotserviceconnectionsdelete = "Microsoft.BotService/botServices/connections/delete"
    $actionbotservicechannelsread = "Microsoft.BotService/botServices/channels/read"
    $actionbotservicechannelswrite = "Microsoft.BotService/botServices/channels/write"
    $actionbotservicechannelsdelete = "Microsoft.BotService/botServices/channels/delete"
    $actionbotserviceoperationsread = "Microsoft.BotService/Operations/read"
    $actionbotservicelocationsread = "Microsoft.BotService/locations/operationresults/read"

    $boolactioncontributor = "false"
    $boolactionbotserviceread = "false"
    $boolactionbotservicerwrite = "false"
    $boolactionbotservicerdelete = "false"
    $boolactionbotserviceconnectionsread = "false"
    $boolactionbotserviceconnectionswrite = "false"
    $boolactionbotserviceconnectionsdelete = "false"
    $boolactionbotservicechannelsread = "false"
    $boolactionbotservicechannelswrite = "false"
    $boolactionbotservicechannelsdelete = "false"
    $boolactionbotserviceoperationsread = "false"
    $boolactionbotservicelocationsread = "false"

    foreach ($act in $actions) {

        If ($act -eq $actioncontributor) {
            $boolactioncontributor = "true"
            DisplayMessage -Message ("You are an Admin or Contributor and have all access, please refer this article for all claims that you need to have https://github.com/MicrosoftDocs/azure-docs/blob/master/articles/role-based-access-control/resource-provider-operations.md ") -Level Warning
            DisplayMessage -Message("Here are the ""Actions"" that we found for your account `n `n" + $actions) -Level Warning
            DisplayMessage -Message("Here are the ""Not Actions"" that we found for your account `n `n" + $notactions) -Level Warning
            return
        }
        elseif ($act -eq $actionbotserviceread ) {
            $boolactionbotserviceread = "true"
        }
        elseif ($act -eq $actionbotservicerwrite ) {
            $boolactionbotservicerwrite = "true"
        }
        elseif ($act -eq $actionbotservicerdelete ) {
            $boolactionbotservicerdelete = "true"
        }
        elseif ($act -eq $actionbotserviceconnectionsread ) {
            $boolactionbotserviceconnectionsread = "true"
        }
        elseif ($act -eq $actionbotserviceconnectionswrite ) {
            $boolactionbotserviceconnectionswrited = "true"
        }
        elseif ($act -eq $actionbotserviceconnectionsdelete ) {
            $boolactionbotserviceconnectionsdelete = "true"
        }
        elseif ($act -eq $actionbotservicechannelsread ) {
            $boolactionbotservicechannelsread = "true"
        }
        elseif ($act -eq $actionbotservicechannelswrite ) {
            $boolactionbotservicechannelswrite = "true"
        }
        elseif ($act -eq $actionbotservicechannelsdelete ) {
            $boolactionbotservicechannelsdelete = "true"
        }
        elseif ($act -eq $actionbotserviceoperationsread ) {
            $boolactionbotserviceoperationsread = "true"
        }
        elseif ($act -eq $actionbotservicelocationsread ) {
            $boolactionbotservicelocationsread = "true"
        }
    }

    if ($boolactioncontributor -eq "false" -and ($boolactionbotserviceread -eq "false" -or $boolactionbotservicerwrite -eq "false" -or $boolactionbotservicerdelete -eq "false" -or $boolactionbotserviceconnectionsread -eq "false" -or $boolactionbotserviceconnectionswrite -eq "false" -or $boolactionbotserviceconnectionsdelete -eq "false" -or $boolactionbotservicechannelsread -eq "false" -or $boolactionbotservicechannelswrite -eq "false" -or $boolactionbotservicechannelsdelete -eq "false" -or $boolactionbotserviceoperationsread -eq "false" -or $boolactionbotservicelocationsread -eq "false" )) {

        DisplayMessage -Message ("You are not an admin or contributor, please refer this article for all claims that you need to have https://github.com/MicrosoftDocs/azure-docs/blob/master/articles/role-based-access-control/resource-provider-operations.md ") -Level Error
        DisplayMessage -Message("Here are the ""Actions"" that we found for your account `n `n" + $actions) -Level Warning
        DisplayMessage -Message("Here are the ""Not Actions"" that we found for your account `n `n" + $notactions) -Level Warning
        DisplayMessage -Message("Here are the claims that may be missing") -Level Error

        if ( $boolactionbotserviceread -eq "false" ) {
            DisplayMessage -Message($actionbotserviceread) -Level Error
        }
        if ( $boolactionbotservicerwrite -eq "false" ) {
            DisplayMessage -Message($actionbotservicerwrite) -Level Error
        }
        if ( $boolactionbotservicerdelete -eq "false" ) {
            DisplayMessage -Message($actionbotservicerdelete) -Level Error
        }
        if ( $boolactionbotserviceconnectionsread -eq "false" ) {
            DisplayMessage -Message($actionbotserviceconnectionsread) -Level Error
        }
        if ( $boolactionbotserviceconnectionswrite -eq "false" ) {
            DisplayMessage -Message($actionbotserviceconnectionswrite) -Level Error
        }
        if ( $boolactionbotserviceconnectionsdelete -eq "false" ) {
            DisplayMessage -Message($actionbotserviceconnectionsdelete) -Level Error
        }
        if ( $boolactionbotservicechannelsread -eq "false" ) {
            DisplayMessage -Message($actionbotservicechannelsread) -Level Error
        }
        if ( $boolactionbotservicechannelswrite -eq "false" ) {
            DisplayMessage -Message($actionbotservicechannelswrite) -Level Error
        }
        if ( $boolactionbotservicechannelsdelete -eq "false" ) {
            DisplayMessage -Message($actionbotservicechannelsdelete) -Level Error
        }
        if ( $boolactionbotserviceoperationsread -eq "false" ) {
            DisplayMessage -Message($actionbotserviceoperationsread) -Level Error
        }
        if ( $boolactionbotservicelocationsread -eq "false" ) {
            DisplayMessage -Message($actionbotservicelocationsread) -Level Error
        }
    }
    else {
        DisplayMessage -Message ("You might not have all the privileges needed to create Bot Service, please refer https://github.com/MicrosoftDocs/azure-docs/blob/master/articles/role-based-access-control/resource-provider-operations.md ") -Level Error
        DisplayMessage -Message("Here are the ""Actions"" that we found for your account `n `n" + $actions) -Level Error
        DisplayMessage -Message("Here are the ""Not Actions"" that we found for your account `n `n" + $notactions) -Level Error
    }

}

Function TroubleshootBotWebChatConnectivity {
    Param(
        [String]
        $botServiceName
    )

    #region Fetch Bot Service and backend endpoint Info
    DisplayMessage -Message "Fetching BotService and Endpoint information" -Level Info

    #Fetch botService ResourceGroup and build the botserviceURI and get the AppID of botService
    $botservicesundersubidJSON = ARMCall -URI "https://management.azure.com/subscriptions/$subscriptionId/providers/Microsoft.BotService/botServices/?api-version=2017-12-01" -bearerToken $bearerToken -Verb "get"

    #Convert Json String to PSObject
    $botservicesundersubid = $botservicesundersubidJSON | ConvertFrom-Json
    $botservicesundersubid.value.GetEnumerator() | foreach {
        If ($_.id.endswith("/Microsoft.BotService/botServices/$botServiceName")) {

            $botserviceUri = $_.id + "/?api-version=2017-12-01"
            $botserviceAppId = $_.properties.msaAppId
        }
    }

    if ($botserviceUri -eq $null) {
        DisplayMessage -Message "No Bot Service found with the name provided under this subscription or Microsoft.BotService namespace is not registered" -Level Error
        return
    }

    #Fetch the Bot Service Info and retrieve the endpoint info
    $botserviceinfoJSON = ARMCall -URI "https://management.azure.com$botserviceUri" -bearerToken $bearerToken -Verb "get"

    #Convert the string representation of JSON into PowerShell objects for easy manipulation
    $botserviceinfo = $botserviceinfoJSON | ConvertFrom-Json

    #Get the endpoint and retrive the web app name (without hostname)
    $botserviceendpoint = $botserviceinfo.properties.endpoint
    $hostedonazure = "false"
    $hostname = Get-UriSchemeAndAuthority $botserviceendpoint
    $webappname = ""

    DisplayMessage -Message "Validating if the endpoint is hosted on Azure Web App" -Level Info

    #validating if the URL of the endpoint is hosted on Azure web app
    if ($hostname.contains("azurewebsites.net")) {
        $hostedonazure = "true"
        $webappname = $hostname.split('.')[0]
    }
    else {
        try {
            #we are doing nslookup since the URL can be custom host name
            $nslookupname = resolve-dnsname $hostname -Type NS | Where-Object { $_.Namehost -like '*azurewebsites.net*' } | Select NameHost -ExpandProperty NameHost
        }
        catch { }

        if ($nslookupname.contains("azurewebsites.net")) {
            $hostedonazure = "true"
            $webappname = $nslookupname.split('.')[0]
        }
    }


    #if the endpoint is hosted on azure web app then get all app settings to retrive the Appid and Password
    if ($hostedonazure -eq "true") {

        #fetch the Endpoint Info (If only Hosted as Web App (*.Azurewebsites.net))
        $siteinfoJSON = ARMCall -URI "https://management.azure.com/subscriptions/$subscriptionId/providers/Microsoft.Web/sites/?api-version=2018-02-01" -bearerToken $bearerToken -Verb "get"
        #Convert the string representation of JSON into PowerShell objects for easy manipulation
        $sitesinfo = $siteinfoJSON | ConvertFrom-Json
        #Here all the sites are looped to get the right site name and its resoure group,
        $sitesinfo.value.GetEnumerator() | foreach {

            If ($_.id.endswith($webappname)) {
                $siteURL = $_.id + "/config/appsettings/list?api-version=2018-02-01"
            }
        }

        try {

            DisplayMessage -Message "Getting the Bot Endpoints AppID and Password" -Level Info

            #fetch the endpoint web apps App Settings
            $endpointinfoJSON = ARMCall -URI "https://management.azure.com$siteURL" -bearerToken $bearerToken -Verb "POST"

            #Convert the string representation of JSON into PowerShell objects for easy manipulation
            $endpoint = $endpointinfoJSON | ConvertFrom-Json

            $endpointAppid = $endpoint.properties.MicrosoftAppId
            $endpointPassword = $endpoint.properties.MicrosoftAppPassword

        }
        catch {
            DisplayMessage -Message "$_" -Level Error
        }
    }


    #endregion Fetch Bot Service and backend endpoint Info

    #region Now the actual checks for Different Error Codes while calling Messaging endpoint

    DisplayMessage -Message "Validating the endpoint" -Level Info

    $statuscode = 200
    $errorstatus = "false"
    $Message = "No Errors Found..."

    try {
        $response = Invoke-WebRequest -Uri  $botserviceendpoint
    }

    catch {

        $statuscode = $_.Exception.Response.StatusCode.value__
        if ($_.Exception.Status -eq "NameResolutionFailure") {
            $statuscode = 502
        }
    }

    switch ($statuscode) {

        502 {
            $errorstatus = "true"
            $Message = "Name resolution of the messaging endpoint ($botserviceendpoint) failed ( DNS resolution Failed). Please validate the messaging endpoint and reconfigure it."
        }

        405 {
            $errorstatus = "false"
            $Message = "The messaging endpoint ($botserviceendpoint) seems to be valid"
        }

        200 {
            $errorstatus = "true"
            $Message = "The hostname of the messaging endpoint ($botserviceendpoint) seems to be okay, but the endpoint you have configured may be incorrect. Validate if you are refering to right controller example /api/messages"
        }

        404 {
            $errorstatus = "true"
            $Message = "The hostname of the messaging endpoint ($botserviceendpoint) seems to be okay, but the endpoint you have configured may be incorrect. Validate if you are refering to right controller example /api/messages"
        }

        403 {
            $errorstatus = "true"
            $Message = "The messaging endpoint ($botserviceendpoint) seems to be not responding or in STOPPED state"
        }

        503 {
            $errorstatus = "true"
            $Message = "The messaging endpoint ($botserviceendpoint) seems to be not responding or in STOPPED state"
        }

        500 {
            $errorstatus = "true"
            $Message = "The messaging endpoint ($botserviceendpoint) seems to be failing with exception. Please review the exception call stack"
        }
    }

    #endregion Now the actual checks for Different Error Codes while calling Messaging endpoint

    #region Now validate the APPID and Password Between the endpoint and Bot Service

    if ($errorstatus -eq "true") {
        #since there is a failure just report it and stop
        DisplayMessage -Message $Message -Level Error
    }
    else {
        if ($hostedonazure -eq "true") {

            DisplayMessage -Message "Validating AppID and Password mismatch between Bot Service and the Bot Endpoint" -Level Info
            #if no Errors found then validate AppID and Password

            #validate passwords since AppIDs are same
            if ($botserviceAppId -eq $endpointAppid) {
                #Since the AppIds match, validate the password.
                try {

                    #fetch bearer token for given AppID refer https://docs.microsoft.com/en-us/azure/bot-service/rest-api/bot-framework-rest-connector-authentication?view=azure-bot-service-3.0
                    $password = [System.Web.HttpUtility]::UrlEncode($endpointPassword)
                    $postParams = "grant_type=client_credentials&client_id=$endpointAppid&client_secret=$password&scope=$botserviceAppId%2F.default"
                    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
                    $headers.Add('Host', 'login.microsoftonline.com')
                    $headers.Add('Content-Type', 'application/x-www-form-urlencoded')
                    $responsejson = Invoke-WebRequest -Uri https://login.microsoftonline.com/botframework.com/oauth2/v2.0/token -Method POST -Body $postParams -Headers $headers
                    $response = $responsejson | ConvertFrom-Json

                    #Now call the actual endpoint to validate if it returned 401 or 200
                    $postParams = "{'type': 'message'}"
                    $headers2 = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
                    $headers2.Add('Authorization', 'Bearer ' + $response.access_token)
                    $headers2.Add('Content-Type', 'application/json')
                    $responsejson = Invoke-WebRequest -Uri $botserviceendpoint -Method POST -Body $postParams -Headers $headers2
                    $response = $responsejson | ConvertFrom-Json
                    $response
                }

                catch {

                    $statuscode = $_.Exception.Response.StatusCode.value__

                    if ($statuscode -eq 401 ) {
                        DisplayMessage -Message ("The AppID's match, but your Bot might fail with 401 authentication error as the password between Bot Service and your Web end point do not match. Please refer https://docs.microsoft.com/en-us/azure/bot-service/bot-service-manage-overview?view=azure-bot-service-3.0") -Level Error
                    }

                    if ($statuscode -eq 400 ) {
                        if ($_.ErrorDetails.Message.Contains("Application with identifier '$botserviceAppId' was not found in the directory 'botframework.com'")) {
                            DisplayMessage -Message ("The AppID is invalid!.Please follow this step to create AppId and that should help fix the issue.Login to Portal -> Azure Active Directory-> App Registrations (preview)-> New Registration.Please makes sure to select the second option 'Accounts in any organizational directory'. The reason is appId must be available for botframework.com directory.") -Level Error
                        }
                    }

                }
            }
            else {
                #customer needs to sync App Id between the Messaging End Point and Bot Service
                DisplayMessage -Message "Your Bot might fail with 401 authentication error as the AppId between Bot Service and your Web end point do not match. Please refer https://docs.microsoft.com/en-us/azure/bot-service/bot-service-manage-overview?view=azure-bot-service-3.0" -Level Error

            }
        }
    }

    #endregion Now validate the APPID and Password Between the endpoint and Bot Service

    #region Generate Output Report

    if ($hostedonazure -ne "true") {
        DisplayMessage -Message("The Bot Endpoint may not be hosted on Azure, please review the article https://docs.microsoft.com/en-us/azure/bot-service/bot-service-resources-bot-framework-faq?view=azure-bot-service-3.0#which-specific-urls-do-i-need-to-whitelist-in-my-corporate-firewall-to-access-bot-framework-services") -Level Warning
    }
    DisplayMessage -Message ("The troubleshooter script completed.If there are any errors reported above, please fix them and re-run this script to validate other scenarios.") -Level Info
    #endregion Generate Output Report
}

DisplayMessage -Message ("Please select the scenario you are troubleshooting") -Level Input
DisplayMessage -Message ("1. Type 1 if you are having issues creating BotService") -Level Input
DisplayMessage -Message ("2. Type 2 if you are having issues with Webchat Connectivity") -Level Input
$scenario = Read-Host -Prompt 'Enter the Scenario ( 1 or 2)'

if ($scenario -eq "2") {

    $botServiceName =	Read-Host -Prompt 'Please provide the Bot Service Name'

    if ($botServiceName -eq "") {
        DisplayMessage -Message ("Bot Service name cannot be null, exiting") -Level Error
        return
    }
    Else {
        TroubleshootBotWebChatConnectivity -botServiceName $botServiceName
    }

}
ElseIf ($scenario -eq "1") {
    TroubleshootBotCreationPermissionIssues
}

return
