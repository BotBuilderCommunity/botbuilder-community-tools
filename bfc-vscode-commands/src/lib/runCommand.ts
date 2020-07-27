export const runCommand = async (command: string): Promise<any> => {
    const { exec } = require('child_process');

    return new Promise((resolve, reject) => {
        exec(command, (error: any, _: any, stderr: any) => {
            if (error) {
                reject(error);
            }
            if (stderr) {
                reject(stderr);
            }
            resolve();
        });
    });
}