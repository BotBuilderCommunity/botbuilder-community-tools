using System.Runtime.CompilerServices;
using System.Threading;
using System.Threading.Tasks;
using AdaptiveExpressions.Properties;
using Microsoft.Bot.Builder.Dialogs;
using Newtonsoft.Json;

namespace BotCustomAction
{
    //DescriptionContent
    public class BotCustomAction : Dialog
    {
        public BotCustomAction([CallerFilePath] string sourceFilePath = "",[CallerLineNumber] int sourceLineNumber=0) : base()
        {
            RegisterSourceLocation(sourceFilePath,sourceLineNumber);
        }
        
        [JsonProperty("$Kind")]
        public const string Kind = "BotCustomAction";

        [JsonProperty("resultProperty")]
        public StringExpression ResultProperty { get; set; }

        public override Task<DialogTurnResult> BeginDialogAsync(DialogContext dc, object options = null,
            CancellationToken cancellationToken = new CancellationToken())
        {
            var result = string.Empty;

            if (ResultProperty != null)
            {
                dc.State.SetValue(this.ResultProperty.GetValue(dc.State),result);
            }

            return dc.EndDialogAsync(result: result, cancellationToken:cancellationToken);
        }
    }
}
