# Bot Framework Community VS Code Commands

This extension for [Visual Studio Code](https://code.visualstudio.com/) adds commands for Bot Framework development. Currently it contains commands for the following areas:
- LUIS

## Usage

Within your file in VS Code, right-click a file to bring up the context menu and select one of the following commands:

### LUIS commands

#### Import LUIS application

This command uses the [Bot Framework CLI](https://github.com/microsoft/botframework-cli) to import a .lu file into your LUIS account. All you need to do is to create a .lu file (see [this instruction](https://docs.microsoft.com/en-us/azure/bot-service/file-format/bot-builder-lu-file-format?view=azure-bot-service-4.0) how to do that) and then right-click that file in VS Code, select `Import LUIS application` and enter the necessary information as prompted (LUIS endpoint, subscription key, app name & culture code). After entering all details a new LUIS app will be created for you and all information you entered in your .lu file will be added to your new LUIS app (e.g. intents, utterances, entities,...)

![Import LUIS application usage](https://raw.githubusercontent.com/BotBuilderCommunity/botbuilder-community-tools/master/bfc-vscode-commands/assets/importLuisApp.gif)

## Feedback, Ideas & Contributions

Feedback and/or snippet ideas as well as contributions always welcome. Please submit them via creating an issue in the extension repository: [issue list](https://github.com/BotBuilderCommunity/botbuilder-community-tools/issues).
