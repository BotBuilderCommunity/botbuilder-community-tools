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
exports.sendGetRequest = void 0;
const request = require("request-promise");
/*
export class Utils {
    public static async sendGetRequest(url: string): Promise<string> {
        let response: any = {};
        await request.get(url)
            .then((body: string) => { response = JSON.parse(body); })
            .catch ((err: { toString: () => any; }) => { response = { "origin": err.toString() }; });
        return response.origin;
    }
    
}
*/
exports.sendGetRequest = (url) => __awaiter(void 0, void 0, void 0, function* () {
    let response = {};
    // Here we go!
    yield request.get(url)
        .then((body) => { response = JSON.parse(body); })
        .catch((err) => { response = { "origin": err.toString() }; });
    // Now that we have our response, pull out the origin and return it
    // to the caller.
    return response.origin;
});
//# sourceMappingURL=utils.js.map