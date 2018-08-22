# Chatdown Glob

Chatdown Glob is a tool for processing multiple [Chatdown](https://github.com/Microsoft/botbuilder-tools/tree/master/packages/Chatdown) files in a single command.

## Installation

    npm install chatdown-glob -g

## Usage

    chatdown-glob **/*.chat ./transcripts

The above command will process all `*.chat` files in the current directory and all subdirectories, and put the output in the "transcripts" folder of the current directory. If an output directory is not present, it will default to `./`. If an input pattern is not present, it will default to `**/*.chat`.

## Examples

See the [examples](./examples/README.md) folder for a quick Chatdown example. More examples can be found in the [Chatdown GitHub repo](https://github.com/Microsoft/botbuilder-tools/tree/master/packages/Chatdown/Examples).
