using System.Threading;
using System.Threading.Tasks;
using Microsoft.Bot.Builder;

namespace BotComposerMiddlewareComponent.Middleware
{
    public class MiddlewareNameMiddleware : IMiddleware
    {
        public async Task OnTurnAsync(ITurnContext turnContext, NextDelegate next,
            CancellationToken cancellationToken = new CancellationToken())
        {
            
            await next(cancellationToken);

        }
    }
}
