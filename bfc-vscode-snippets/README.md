# Bot Framework Community VS Code Snippets

This extension for [Visual Studio Code](https://code.visualstudio.com/) adds snippets for Bot Framework development. Currently it contains snippets for the following areas:
- Bot Framework Web Chat
- LUIS (.lu) files

## Usage

Within your file in VS Code, type the snippet name according to the ones listed below and press `enter`. This will add the code snippet into your file. You can also press `Ctrl`+`Space` (Windows, Linux) or `Cmd`+`Space` (macOS) to insert a snippet within the editor.

### Bot Framework Web Chat Snippets

Currently there are the following HTML snippets available to quickly create a new Bot Framework in HTML files:

#### bf-wc-create-basic-hml

The snippet **bf-wc-create-basic-hml** creates a basic plain html/js web chat within an HTML file:

![bf-wc-create-basic-hml usage](https://raw.githubusercontent.com/BotBuilderCommunity/botbuilder-community-tools/master/bfc-vscode-snippets/assets/bfc-webchat-basic-snippet-demo.gif)

#### bf-wc-create-style-html

The snippet **bf-wc-create-style-html** creates a plain html/js web chat within an HTML file including some styling options already added to the web chat:

![bf-wc-create-style-html usage](https://raw.githubusercontent.com/BotBuilderCommunity/botbuilder-community-tools/master/bfc-vscode-snippets/assets/bfc-webchat-styling-snippet-demo.gif)

### Language Understanding Snippets

The following snippet should boost your LUIS model setup:

#### bfc-lu-create

The snippet **bfc-lu-create** creates a the required structure within .lu files used for managing [LUIS](https://www.luis.ai/) applications:

![bfc-lu-create usage](https://raw.githubusercontent.com/BotBuilderCommunity/botbuilder-community-tools/master/bfc-vscode-snippets/assets/bfc-lu-snippet-demo.gif)

## Feedback, Ideas & Contributions

Feedback and/or snippet ideas as well as contributions always welcome. Please submit them via creating an issue in the extension repository: [issue list](https://github.com/BotBuilderCommunity/botbuilder-community-tools/issues).

### Adaptive Cards Snippets

If you're building bots, you might need to include Adaptive Cards of some sort. Especially during the development phase it can make sense to just use sample cards to focus on the development side of things. Therefore, you can use the following commands to easily create new Adaptive Cards and redesign them later on:

#### bf-ac-activityUpdate

Adds a [activity update sample card](https://adaptivecards.io/samples/ActivityUpdate.html) to your project.

#### bf-ac-inputForm

Initializes a new [input form sample card](https://adaptivecards.io/samples/InputForm.html) to be used to gather input from users.

#### bf-ac-weatherCompact

Creates the [weather compact sample card](https://adaptivecards.io/samples/WeatherCompact.html) to demo a weather card.

#### bf-ac-expenseReport

Provides you with the [expense report sample card](https://adaptivecards.io/samples/ExpenseReport.html) to include in your bot's project.
