import request = require('request-promise');
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
export const sendGetRequest = async (url: string): Promise<string> => {
    let response: any = {};
    // Here we go!
    await request.get(url)
        .then((body: string) => { response = JSON.parse(body); })
        .catch ((err: { toString: () => any; }) => { response = { "origin": err.toString() }; });
    // Now that we have our response, pull out the origin and return it
    // to the caller.
    return response.origin;
}