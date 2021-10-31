using Microsoft.Bot.Builder;
using Microsoft.Bot.Builder.Dialogs.Declarative;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace BotCustomAction
{
    public class BotCustomActionBotComponent : BotComponent
    {
        public override void ConfigureServices(IServiceCollection services, IConfiguration configuration)
        {
            services.AddSingleton<DeclarativeType>(sp =>
                new DeclarativeType<BotCustomAction>(BotCustomAction.Kind));
        }
    }
}
