# Bot Framework Community VS Code Commands

This extension for [Visual Studio Code](https://code.visualstudio.com/) adds commands for Bot Framework development. Currently it contains commands for the following areas:
- LUIS
- Bot Framework Web Chat

## Prerequisites

> Before this extension can be used please `run npm i -g @microsoft/botframework-cli` to install the [Bot Framework CLI](https://github.com/microsoft/botframework-cli/) on your machine.

## Usage

Within your file in VS Code, right-click a file to bring up the context menu and select one of the following commands:

### LUIS commands

#### Import LUIS application

This command uses the [Bot Framework CLI](https://github.com/microsoft/botframework-cli) to import a .lu file into your LUIS account. All you need to do is to create a .lu file (see [this instruction](https://docs.microsoft.com/en-us/azure/bot-service/file-format/bot-builder-lu-file-format?view=azure-bot-service-4.0) how to do that) and then right-click that file in VS Code, select `Import LUIS application` and enter the necessary information as prompted (LUIS endpoint, subscription key, app name & culture code). After entering all details a new LUIS app will be created for you and all information you entered in your .lu file will be added to your new LUIS app (e.g. intents, utterances, entities,...)

![Import LUIS application usage](https://raw.githubusercontent.com/BotBuilderCommunity/botbuilder-community-tools/master/bfc-vscode-commands/assets/importLuisApp.gif)

### Bot Framework Web Chat commands

#### Preview Web Chat

This command lets you preview a Bot Framework Web Chat, which you have developed in a .html file right within VS Code. So you can develop and style your Web Chat component and preview it without the need to switch context. To use this command open up a .html file containing your Web Chat component in HTML and hit `Ctrl+Shift+P OR F1` on Windows or `⇧⌘P OR F1` on Mac and enter `Preview Web Chat`.

You can also right click an .html file which contains the Bot Framework Web Chat component in your VS Code explorer and select `Preview Web Chat` to open the preview.

## Feedback, Ideas & Contributions

Feedback and/or snippet ideas as well as contributions always welcome. Please submit them via creating an issue in the extension repository: [issue list](https://github.com/BotBuilderCommunity/botbuilder-community-tools/issues).
