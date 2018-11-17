# Direct Line Postman Package

This package contains a Postman collection and a [Postman](https://www.getpostman.com/) environment for debugging Microsoft Bot Framework chatbots through the [Direct Line API 3.0.](https://docs.microsoft.com/en-us/azure/bot-service/rest-api/bot-framework-rest-direct-line-3-0-concepts?view=azure-bot-service-4.0)

## Installation

After downloading this folder, you can [import the whole package in one step](https://www.getpostman.com/docs/v6/postman/collections/data_formats) into Postman by using it's *Import Folder* functionality.

## Setup

To make the authentication against the Direct Line work, you need to [get your Direct Line secret](https://docs.microsoft.com/en-us/azure/bot-service/bot-service-channel-connect-directline?view=azure-bot-service-4.0#manage-secret-keys) and set it as the value of the **directLineSecret** variable in the freshly imported **Direct Line 3.0** environment in Postman.

## Usage

The collection contains four requests that you can use for testing your chatbots through the Direct Line:

* Start conversation
* Send event
* Send message
* Receive activities

The names of the requests are pretty self-explanatory if you are familiar with the Direct Line API 3.0.

Using those four request types, the default testing workflow looks like this:

1. Create a new conversation by issuing a **Start conversation** request.
2. Using **Send event** and **Send message** to trigger the bot logic being tested.
3. Check the conversation history with **Receive activities** to see if everything is okay.

In the above list, sending an event and sending a message are pretty similar, since they are POST-ing the very same endpoint, but with a different body. Based on these and the [schema's documentation](https://docs.microsoft.com/en-us/azure/bot-service/rest-api/bot-framework-rest-connector-api-reference?view=azure-bot-service-4.0#activity-object), you can easily send your own Activity object.

## Notes

For implementation details please refer to [this blog post.](https://peterbozso.github.io/2018/11/02/direct-line-postman.html)
