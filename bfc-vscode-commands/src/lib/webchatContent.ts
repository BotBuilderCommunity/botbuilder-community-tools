'use strict';

import * as vscode from 'vscode';
import * as path from 'path';

export class WebchatContent implements vscode.TextDocumentContentProvider {
    private _onDidChange = new vscode.EventEmitter<vscode.Uri>();

    public constructor(private _context: vscode.ExtensionContext) {}

    public provideTextDocumentContent(uri: vscode.Uri): string {
        return this.createWebchatContent();
    }

    get onDidChange(): vscode.Event<vscode.Uri> {
        return this._onDidChange.event;
    }

    public update(uri: vscode.Uri) {
        this._onDidChange.fire(uri);
    }

    private createWebchatContent() {
        return this.extractSnippet();
    }

    private extractSnippet(): string {
        let editor = vscode.window.activeTextEditor;
        let text = editor ? editor.document.getText() : '';
        //let fileName = editor ? editor.document.fileName : '';
        //let webchatSnippet = this.webchatSnippet(fileName, text);
        return text;
    }

    private errorSnippet(error: string): string {
        return `
                <body>
                    ${error}
                </body>`;
    }

    private getPath(p: string): string {
        return path.join(this._context.extensionPath, p);
    }

    /*private webchatSnippet(fileName: string, html: string): string {
        return html;
    }*/
}