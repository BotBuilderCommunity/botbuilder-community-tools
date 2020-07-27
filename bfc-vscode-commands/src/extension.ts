// The module 'vscode' contains the VS Code extensibility API
// Import the module and reference it with the alias vscode in your code below
import * as vscode from 'vscode';
import * as path from 'path';
import {exec} from 'child_process'
import { runCommand } from './lib/runCommand';

// this method is called when your extension is activated
// your extension is activated the very first time the command is executed
export function activate(context: vscode.ExtensionContext) {

	// The command has been defined in the package.json file
	// Now provide the implementation of the command with registerCommand
	// The commandId parameter must match the command field in package.json
	let disposable = vscode.commands.registerCommand('bfc.luisImport', async (fileUri, folder) => {
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

	context.subscriptions.push(disposable);
}

// this method is called when your extension is deactivated
export function deactivate() {}
