"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.sendGetRequest = void 0;
const request = require("request-promise-native");
exports.sendGetRequest = (url) => {
    const requestOptions = {
        url: `${siteUrl}/_api/contextinfo`,
        headers: {
            authorization: `Bearer ${accessToken}`,
            accept: 'application/json;odata=nometadata',
        },
        json: true
    };
    return request.post(requestOptions);
};
//# sourceMappingURL=httpRequest.js.map