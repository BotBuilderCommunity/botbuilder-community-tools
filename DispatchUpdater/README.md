# Dispatch Updater

This package is used to let you implement a solution to update a Dispatch model and the associated LUIS models and QnAMaker KBs automatically. This should solve the problem, that currently you would need to run `dispatch refresh` from time to time to keep your Dispatch model up-to-date all the time.

[Dispatch](https://github.com/Microsoft/botbuilder-tools/tree/master/packages/Dispatch) is a command line tool to create and evaluate LUIS models used to dispatch intent across multiple bot modules such as LUIS models, QnA knowledge bases and others (added to dispatch as a file type).
The "problem" with that currently is that, every time you alter your language model or extend your QnAMaker KBs, you would need to manually run the dispatch command to update the dispatch model.

Therefore, this Azure Function can be used to automate that refresh/update process to avoid additional manual steps.

The solution basically consists of an Azure Function (PowerShell) which runs periodically and executes the following commands for you:
* qnamaker publish kb
* dispatch refresh

In order to make that work you need to run through the following steps to create a PowerShell based Azure Function:
https://docs.microsoft.com/en-us/azure/azure-functions/functions-create-first-azure-function

__ATTENTION__ Make sure to change the runtime stack to **PowerShell** and select to right region for your function. After the function app has been created, create your function and select the *Timer Trigger* as a template if you want your function to run based on a schedule.

Now that your function is all set up, we need to install the BotBuilder tools for managing dispatch models and QnAMaker KBs.

First of all we need to install the BotBuilder Command Line tools into the Azure Function's environment, to be able to use those.
To do that, you need to bring up the Kudu environment of your funtcion, whill can be accessed either via the *Platform Features* pane or via the URL https://{nameofyourfunction}.scm.azurewebsites.net and then go to the 'Debug Console > CMD' and navigate to the root of your function project, which will apparently be something like 'D:\home\site\wwwroot\TimerTrigger1'. Inside this folder run the following command to install Dispatch and QnAMaker command line tools:

`npm install botdispatch qnamaker`

Now if you look at the 'node_modules\.bin' folder within your project, you should see that you have a dispatch.cmd and a qnamaker.cmd file available. Now within that folder, you need to have your .dispatch file available (if you already created your dispatch model). If you need to create your dispatch model, follow the steps from [here](https://github.com/Microsoft/botbuilder-tools/tree/master/packages/Dispatch#usage) to initialize the dispatch model (dispatch init) within that folder location. Now what you will get then, is a .dispatch and a .json file which are used to store information about your dispatch model.

Before we can update the code, we need to add a couple of environment variables to make sure the qnamaker command line tool is able to run successfully. So simply those 4 key value pairs with your information to the function's application settings:

| Name  | Value |
| ------------- | ------------- |
| QNAMAKER_ENDPOINTKEY  | yourQnAMakerEndpointKey  |
| QNAMAKER_HOSTNAME  | yourQnAMakerHostname  |
| QNAMAKER_KBID   | yourKBId   |
| QNAMAKER_SUBSCRIPTION_KEY   | yourSubscriptionKey   |

Now that this is in place, we can update the PowerShell code to call the dispatch and qnamaker tool.

Now we simply need to add the following lines of code to the script to call dispatch and refresh the model as well as publish the qnamaker KB before that to make sure the have the latest KB QnA pairs available. __NOTE__: You do not need to publish the QnAMaker KB if you don't want to automate that process as well, because sometimes you only want to allow content creators to publish your KBs after they reviewed it. If so, just remove the qnamaker line:

```powershell
# Get the KBId from the application settings & publish the QnAMaker knowledgebase
$kbID = $env:QNAMAKER_KBID
& "D:\home\site\wwwroot\TimerTrigger1\node_modules\.bin\qnamaker.cmd" publish kb --kbId $kbID

# Update the dispatch model to get the latest changes from the QnAMaker KBs
& "D:\home\site\wwwroot\TimerTrigger1\node_modules\.bin\dispatch.cmd" refresh
```

So the overall code of your function could look like this:
```powershell
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
& "D:\home\site\wwwroot\TimerTrigger1\node_modules\.bin\dispatch.cmd" refresh

# Write an information log with the current time.
Write-Host "PowerShell timer trigger function ran! TIME: $currentUTCtime"
```

When you are done editing, you save your function and wait for the function to run. Don't forget to adapt your schedule according to [this definition](https://docs.microsoft.com/en-us/azure/azure-functions/functions-bindings-timer#cron-expressions).