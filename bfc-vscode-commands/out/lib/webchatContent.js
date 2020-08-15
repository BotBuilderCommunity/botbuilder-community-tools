'use strict';
Object.defineProperty(exports, "__esModule", { value: true });
exports.WebchatContent = void 0;
const vscode = require("vscode");
const path = require("path");
class WebchatContent {
    constructor(_context) {
        this._context = _context;
        this._onDidChange = new vscode.EventEmitter();
    }
    provideTextDocumentContent(uri) {
        return this.createWebchatContent();
    }
    get onDidChange() {
        return this._onDidChange.event;
    }
    update(uri) {
        this._onDidChange.fire(uri);
    }
    createWebchatContent() {
        return this.extractSnippet();
    }
    extractSnippet() {
        let editor = vscode.window.activeTextEditor;
        let text = editor ? editor.document.getText() : '';
        //let fileName = editor ? editor.document.fileName : '';
        //let webchatSnippet = this.webchatSnippet(fileName, text);
        return text;
    }
    errorSnippet(error) {
        return `
                <body>
                    ${error}
                </body>`;
    }
    getPath(p) {
        return path.join(this._context.extensionPath, p);
    }
}
exports.WebchatContent = WebchatContent;
//# sourceMappingURL=webchatContent.js.map