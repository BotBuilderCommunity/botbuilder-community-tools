"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.deactivate = exports.activate = void 0;
// The module 'vscode' contains the VS Code extensibility API
// Import the module and reference it with the alias vscode in your code below
const vscode = require("vscode");
const path = require("path");
const runCommand_1 = require("./lib/runCommand");
// this method is called when your extension is activated
// your extension is activated the very first time the command is executed
function activate(context) {
    // The command has been defined in the package.json file
    // Now provide the implementation of the command with registerCommand
    // The commandId parameter must match the command field in package.json
    let disposable = vscode.commands.registerCommand('bfc.luisImport', (fileUri, folder) => __awaiter(this, void 0, void 0, function* () {
        const folderPath = path.dirname(fileUri.fsPath);
        const fileName = path.basename(fileUri.fsPath);
        const jsonFileName = fileName.replace(".lu", ".json");
        const newFileUri = folderPath + "\\" + jsonFileName;
        let luisHostName = yield vscode.window.showInputBox({
            ignoreFocusOut: true,
            prompt: 'Please insert your LUIS endpoint hostname',
            placeHolder: 'e.g.: https://<region>.api.cognitive.microsoft.com'
        });
        let luisSubscriptionKey = yield vscode.window.showInputBox({
            ignoreFocusOut: true,
            prompt: 'Please insert your LUIS subscription key',
            placeHolder: 'LUIS subscription key'
        });
        let luisAppName = yield vscode.window.showInputBox({
            ignoreFocusOut: true,
            prompt: 'Please insert your LUIS app name',
            placeHolder: 'LUIS app name'
        });
        let luisCulture = yield vscode.window.showInputBox({
            ignoreFocusOut: true,
            prompt: 'Please insert your LUIS app culture code',
            placeHolder: 'e.g.: en-us)'
        });
        let commandConvert = "bf luis:convert --in " + fileUri.fsPath + " --culture " + luisCulture + " --out " + newFileUri;
        let commandImport = "bf luis:application:import --endpoint \"" + luisHostName + "\" --subscriptionKey \"" + luisSubscriptionKey + "\" --name \"" + luisAppName + "\" --in \"" + newFileUri + "\"";
        console.log(commandConvert);
        runCommand_1.runCommand(commandConvert)
            .then(() => runCommand_1.runCommand(commandImport)
            .then(() => vscode.window.showInformationMessage('LUIS App successfully imported: ' + luisAppName), (reason) => vscode.window.showErrorMessage(`An error occurred - [${reason}] `)), (reason) => vscode.window.showErrorMessage(`An error occurred - [${reason}] `));
    }));
    context.subscriptions.push(disposable);
}
exports.activate = activate;
// this method is called when your extension is deactivated
function deactivate() { }
exports.deactivate = deactivate;
//# sourceMappingURL=extension.js.map