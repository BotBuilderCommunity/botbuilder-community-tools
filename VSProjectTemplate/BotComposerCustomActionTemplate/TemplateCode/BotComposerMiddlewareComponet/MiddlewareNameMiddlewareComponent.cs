using System;
using BotComposerMiddlewareComponent.Middleware;
using Microsoft.Bot.Builder;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace BotComposerMiddlewareComponent
{
    public class MiddlewareNameMiddlewareComponent : BotComponent
    {
        public override void ConfigureServices(IServiceCollection services, IConfiguration configuration)
        {
            
            if(services == null)
                throw new ArgumentNullException(nameof(services));  

            if(configuration == null)
                throw new ArgumentNullException(nameof(configuration));

			services.AddSingleton<IMiddleware, MiddlewareNameMiddleware>();

        }
    }
}
