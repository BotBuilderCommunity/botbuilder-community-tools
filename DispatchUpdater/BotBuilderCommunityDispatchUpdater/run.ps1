# Input bindings are passed in via param block.
param($Timer)

# Get the current universal time in the default string format
$currentUTCtime = (Get-Date).ToUniversalTime()

# The 'IsPastDue' porperty is 'true' when the current function invocation is later than scheduled.
if ($Timer.IsPastDue) {
    Write-Host "PowerShell timer is running late!"
}

# Get the KBId from the application settings & publish the QnAMaker knowledgebase
$kbID = $env:QNAMAKER_KBID
& "D:\home\site\wwwroot\TimerTrigger1\node_modules\.bin\qnamaker.cmd" publish kb --kbId $kbID

# Update the dispatch model to get the latest changes from the QnAMaker KBs
"D:\home\site\wwwroot\TimerTrigger1\node_modules\.bin\dispatch.cmd" refresh

# Write an information log with the current time.
Write-Host "PowerShell timer trigger function ran! TIME: $currentUTCtime"