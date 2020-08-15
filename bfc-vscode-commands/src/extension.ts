// The module 'vscode' contains the VS Code extensibility API
// Import the module and reference it with the alias vscode in your code below
import * as vscode from 'vscode';
import * as path from 'path';
import { runCommand } from './lib/runCommand';
import * as Utils from './lib/utils';

let currentPanel: vscode.WebviewPanel | undefined = undefined;

// this method is called when your extension is activated
// your extension is activated the very first time the command is executed
export function activate(context: vscode.ExtensionContext) {
	// The command has been defined in the package.json file
	// Now provide the implementation of the command with registerCommand
	// The commandId parameter must match the command field in package.json
	const luisImport = vscode.commands.registerCommand('bfc.luisImport', async (fileUri, folder) => {
		const folderPath = path.dirname(fileUri.fsPath);
		const fileName = path.basename(fileUri.fsPath);
		const jsonFileName = fileName.replace(".lu", ".json");
		const newFileUri = folderPath + "\\" + jsonFileName;
		let luisHostName = await vscode.window.showInputBox({
            ignoreFocusOut: true,
            prompt: 'Please insert your LUIS endpoint hostname',
            placeHolder: 'e.g.: https://<region>.api.cognitive.microsoft.com'
		});
		let luisSubscriptionKey = await vscode.window.showInputBox({
			ignoreFocusOut: true,
			prompt: 'Please insert your LUIS subscription key',
			placeHolder: 'LUIS subscription key'
		});
		let luisAppName = await vscode.window.showInputBox({
			ignoreFocusOut: true,
			prompt: 'Please insert your LUIS app name',
			placeHolder: 'LUIS app name'
		});
		let luisCulture = await vscode.window.showInputBox({
			ignoreFocusOut: true,
			prompt: 'Please insert your LUIS app culture code',
			placeHolder: 'e.g.: en-us)'
		});
		let commandConvert = "bf luis:convert --in " + fileUri.fsPath + " --culture " + luisCulture + " --out " + newFileUri;
		let commandImport = "bf luis:application:import --endpoint \"" + luisHostName + "\" --subscriptionKey \"" + luisSubscriptionKey + "\" --name \"" + luisAppName + "\" --in \"" + newFileUri + "\"";

		console.log(commandConvert);

		runCommand(commandConvert)
			.then(
				() => runCommand(commandImport)
				.then(
					() => vscode.window.showInformationMessage('LUIS App successfully imported: ' + luisAppName),
					(reason) => vscode.window.showErrorMessage(`An error occurred - [${reason}] `)
				),
				(reason) => vscode.window.showErrorMessage(`An error occurred - [${reason}] `)
			);	
	});
	const luisTrainRun = vscode.commands.registerCommand('bfc.luisTrainRun', async () => {
		let luisAppId = await vscode.window.showInputBox({
            ignoreFocusOut: true,
            prompt: 'Please insert your LUIS app ID',
            placeHolder: 'LUIS app ID'
		});
		let luisSubscriptionKey = await vscode.window.showInputBox({
			ignoreFocusOut: true,
			prompt: 'Please insert your LUIS subscription key',
			placeHolder: 'LUIS subscription key'
		});
		let joke = await Utils.sendGetRequest("http://httpbin.org/ip");
		vscode.window.showInformationMessage("App ID: " + joke);
	});

	vscode.workspace.onDidSaveTextDocument((document: vscode.TextDocument) => {
		if (currentPanel) {
			vscode.window.setStatusBarMessage("Updating webchat...", 10);
			currentPanel.dispose();
			setPanelContent(document);
			/*currentPanel = vscode.window.createWebviewPanel(
				'Bot Framework Web Chat Preview',
				'Bot Framework Web Chat Preview',
				vscode.ViewColumn.Two,
				{
					// Enable scripts in the webview
					enableScripts: true
				}
			);
			currentPanel.webview.html = document.getText();*/
		}
	});


	const previewWebchat = vscode.commands.registerTextEditorCommand('bfc.previewWebchat', (te, t) => {
        if (checkIfBFWebchat(te.document))
			return;
		setPanelContent(te.document);
		/*currentPanel = vscode.window.createWebviewPanel(
			'Bot Framework Web Chat Preview',
			'Bot Framework Web Chat Preview',
			vscode.ViewColumn.Two,
			{
				// Enable scripts in the webview
				enableScripts: true
			}
		);
		currentPanel.webview.html = te.document.getText();*/
    });

	context.subscriptions.push(luisImport, luisTrainRun, previewWebchat);
}

function checkIfBFWebchat(document: vscode.TextDocument, displayMessage: boolean = true) {
    let isBFWC = !(document.languageId === 'html') || document.getText().indexOf('https://cdn.botframework.com') < 0;
    if (isBFWC && displayMessage) {
        vscode.window.showErrorMessage("This is not a Bot Framework Webchat, sorry! Try another file or visit http://aka.ms/bfwebchat for more info...");
    }
    return isBFWC;
}

function setPanelContent(document: vscode.TextDocument) {
	currentPanel = vscode.window.createWebviewPanel(
		'Bot Framework Web Chat Preview',
		'Bot Framework Web Chat Preview',
		vscode.ViewColumn.Two,
		{
			// Enable scripts in the webview
			enableScripts: true
		}
	);
	currentPanel.webview.html = document.getText();
}

// this method is called when your extension is deactivated
export function deactivate() {}
