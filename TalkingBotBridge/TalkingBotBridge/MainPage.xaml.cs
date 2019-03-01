namespace TalkingBotBridge
{
    using Microsoft.Bot.Connector.DirectLine;
    using System;
    using System.Diagnostics;
    using System.IO;
    using System.Linq;
    using System.Threading.Tasks;
    using Windows.Media.Core;
    using Windows.Media.Playback;
    using Windows.UI.Core;
    using Windows.UI.Xaml;
    using Windows.UI.Xaml.Controls;
    using Windows.UI.Xaml.Media;

    public sealed partial class MainPage : Page
    {
        private readonly CoreDispatcher cd;
        private JamieD.CognitiveSpeech.SpeechToText cognitiveSpeech;
        private JamieD.CognitiveSpeech.TextToSpeech cognitiveTTS;
        private DirectLineClient directLineClient;
        private Conversation botConversation;
        private bool botIsTalking = false;
        private bool isRecording = false;
        private DispatcherTimer mouthTimer;

        // LUIS model and api key
        private const string STTLanguage = "en-US";
        private const string LuisSubscriptionKey = "<YOUR_LUIS_API_KEY>";
        private const string LuisRegion = "westeurope";
        private const string LuisAppID = "<YOUR_LUIS_APPID>";

        // Text to Speech config
        // List of token endpoints here: https://docs.microsoft.com/en-us/azure/cognitive-services/speech-service/rest-apis
        // List of text to speech endpoints here: https://docs.microsoft.com/en-us/azure/cognitive-services/speech-service/regions#text-to-speech
        private readonly Uri TTSAPITokenUri = new Uri("https://westeurope.api.cognitive.microsoft.com/sts/v1.0/issueToken");
        private const string TTSSubscriptionKey = "<YOUR_SPEECH_API_KEY>";
        private readonly Uri TTSAPIUri = new Uri("https://<YOUR_REGION>.tts.speech.microsoft.com/cognitiveservices/v1");

        // List of formats here: https://docs.microsoft.com/en-us/azure/cognitive-services/speech-service/rest-apis
        private const string TTSOutputFormat = "riff-16khz-16bit-mono-pcm";
        private const int TTSTokenRefreshDurationMin = 10;

        // Bot config - overridable in UI
        private string BotDirectLineSecret = "<YOUR_DIRECTLINE_SECRET>";
        private string BotId = "<YOUR_BOT_HANDLE>";
        private string BotUser;

        // List of voice fonts here: https://docs.microsoft.com/en-us/azure/cognitive-services/speech-service/language-support#text-to-speech
        public string[] voiceFonts = {"(en-US, JessaNeural)", "(en-US, GuyNeural)", "(en-US, JessaRUS)","(en-US, Jessa24kRUS)","(en-US, ZiraRUS)",
            "(en-US, BenjaminRUS)","(en-US, Guy24kRUS)","(en-GB, Susan, Apollo)","(en-GB, HazelRUS)","(en-GB, George, Apollo)",
            "(en-IE, Sean)","(en-IN, Heera, Apollo)","(en-IN, Ravi, Apollo)","(en-CA, Linda)"};

        // SAML https://www.w3.org/TR/2009/REC-speech-synthesis-20090303/#edef_prosody
        public string[] voiceRate = { "default", "x-slow", "slow", "medium", "fast", "x-fast" };
        public string[] voiceVolume = { "default", "silent", "x-soft", "soft", "medium", "loud", "x-loud" };

        // SAML https://www.w3.org/TR/2009/REC-speech-synthesis-20090303/#pitch_contour
        public string[] voicePitch = { "default", "x-low", "medium", "high", "x-high" };

        private string watermark = null;

        private readonly Brush TalkingBrushIndicator = new SolidColorBrush(Windows.UI.Colors.Gold);
        private readonly Brush ListeningBrushIndicator = new SolidColorBrush(Windows.UI.Colors.DarkGray);

        public MainPage()
        {
            this.InitializeComponent();
            cd = Dispatcher;

            foreach (var font in voiceFonts)
            {
                cmbVoiceFont.Items.Add(font);
            }
            cmbVoiceFont.SelectedItem = voiceFonts[0];

            foreach (var rate in voiceRate)
            {
                cmbVoiceRate.Items.Add(rate);
            }
            cmbVoiceRate.SelectedItem = voiceRate[0];

            foreach (var vol in voiceVolume)
            {
                cmbVoiceVolume.Items.Add(vol);
            }
            cmbVoiceVolume.SelectedItem = voiceVolume[0];

            foreach (var pitch in voicePitch)
            {
                cmbVoicePitch.Items.Add(pitch);
            }
            cmbVoicePitch.SelectedItem = voicePitch[0];

            txtBotName.Text = BotId;
            txtDirectLineSecret.Text = BotDirectLineSecret;

            prTalkingStatus.IsActive = false;

            CheckMicSettings();
            ConfigureServices();

            mouthTimer = new DispatcherTimer();
            mouthTimer.Interval = TimeSpan.FromMilliseconds(200);
            mouthTimer.Tick += MouthTimer_Tick;
            mouthTimer.Start();
        }

        private async Task CheckMicSettings()
        {
            try
            {
                var mediaCapture = new Windows.Media.Capture.MediaCapture();
                var settings = new Windows.Media.Capture.MediaCaptureInitializationSettings();
                settings.StreamingCaptureMode = Windows.Media.Capture.StreamingCaptureMode.Audio;
                await mediaCapture.InitializeAsync(settings);
            }
            catch (Exception exp)
            {
                LogOutput($"Error initialing mic: {exp}");
            }
        }

        private void MouthTimer_Tick(object sender, object e)
        {
            if (botIsTalking)
            {
                LeftEye.Fill = TalkingBrushIndicator;
                RightEye.Fill = TalkingBrushIndicator;
                prTalkingStatus.Foreground = TalkingBrushIndicator;
            }
            else
            {
                LeftEye.Fill = ListeningBrushIndicator;
                RightEye.Fill = ListeningBrushIndicator;
                prTalkingStatus.Foreground = ListeningBrushIndicator;
            }
        }

        private void ConfigureServices()
        {
            cognitiveSpeech = new JamieD.CognitiveSpeech.SpeechToText(STTLanguage, LuisSubscriptionKey, LuisRegion, LuisAppID);
            cognitiveTTS = new JamieD.CognitiveSpeech.TextToSpeech(TTSAPITokenUri, TTSAPIUri, TTSSubscriptionKey, TTSOutputFormat, TTSTokenRefreshDurationMin);
            directLineClient = new DirectLineClient(BotDirectLineSecret);
        }

        private async Task BeginConversation()
        {
            BotId = txtBotName.Text;
            BotDirectLineSecret = txtDirectLineSecret.Text;
            watermark = null;
            BotUser = Guid.NewGuid().ToString();
            botConversation = await directLineClient.Conversations.StartConversationAsync();
        }

        private async void Talk_Click(object sender, RoutedEventArgs e)
        {
            btnTalk.IsEnabled = false;
            isRecording = true;
            prTalkingStatus.IsActive = true;
            try
            {
                await Speak("Talk to me!");
                txtLog.PlaceholderText = "Say something..";
                await BeginConversation().ConfigureAwait(false);
                while (isRecording)
                {
                    (string luisIntent, string stt, object luisJson) = await cognitiveSpeech.RecognitionWithMicrophoneAsync().ConfigureAwait(false);
                    stt = stt.RemoveLastChar(".");

                    if (!string.IsNullOrWhiteSpace(luisIntent))
                    {
                        LogOutput($"(You): {stt}");
                        await SendMessageToBot(stt, luisIntent, luisJson, ActivityTypes.Message).ConfigureAwait(false);
                        watermark = await ReadBotReplyAsync(watermark).ConfigureAwait(false);
                    }
                }
            }
            catch (Exception exp)
            {
                LogOutput($"Error listening: {exp}");
            }
        }

        private async void BtnReset_Click(object sender, RoutedEventArgs e)
        {
            btnReset.IsEnabled = false;
            isRecording = false;
            txtLog.Text = "";
            await Task.Delay(2000);
            prTalkingStatus.IsActive = false;
            btnTalk.IsEnabled = true;
            btnReset.IsEnabled = true;
        }

        private async Task SendMessageToBot(string messageText, string luisIntent, object luisJson, string activityType)
        {
            Activity message = new Activity
            {
                Text = messageText,
                Value = luisJson,
                Type = activityType.ToString(),
                From = new ChannelAccount(BotUser)
            };

            await directLineClient.Conversations.PostActivityAsync(botConversation.ConversationId, message);
        }

        private async Task<string> ReadBotReplyAsync(string watermark)
        {
            bool messageReceived = false;

            while (!messageReceived)
            {
                try
                {
                    var messages = await directLineClient.Conversations.GetActivitiesAsync(botConversation.ConversationId, watermark);
                    watermark = messages?.Watermark;
                    var botResponse = messages?.Activities.Where(x => x.From.Name == BotId).ToList();
                    string textToSay = "";
                    foreach (var message in botResponse)
                    {
                        if (!string.IsNullOrWhiteSpace(message.Speak))
                        {
                            textToSay += message.Speak;
                        }
                        else if (!string.IsNullOrWhiteSpace(message.Text))
                        {
                            textToSay += message.Text;
                        }
                        else if (message?.Attachments?.Count > 0)
                        {
                            // TODO: HANDLE CARDS
                        }
                    }

                    if (!string.IsNullOrWhiteSpace(textToSay))
                    {
                        LogOutput($"(Bot): {textToSay}");
                        await Speak(textToSay);
                    }
                    messageReceived = true;
                }
                catch (Exception exp)
                {
                    LogOutput($"Error contacting bot: {exp}");
                }

            }
            return watermark;
        }

        private async Task Speak(string text)
        {
            try
            {
                string fontName = "";
                string rate = "";
                string volume = "";
                string pitch = "";

                await cd.RunAsync(CoreDispatcherPriority.Normal, () =>
                {
                    fontName = $"Microsoft Server Speech Text to Speech Voice {cmbVoiceFont.SelectedItem}";
                    rate = cmbVoiceRate.SelectedItem.ToString();
                    volume = cmbVoiceVolume.SelectedItem.ToString();
                    pitch = cmbVoicePitch.SelectedItem.ToString();
                });

                using (var speechOutput = await cognitiveTTS.GetAudioStream(
                        text: text,
                        voiceFont: fontName,
                        rate: rate,
                        volume: volume,
                        pitch: pitch))
                {
                    await PlaySpeechOutput(speechOutput);
                }
            }
            catch (Exception exp)
            {
                LogOutput($"Error speaking {exp}");
            }
        }

        private async Task PlaySpeechOutput(MemoryStream speechOutput)
        {
            if (speechOutput != null && speechOutput.Length > 0)
            {
                var taskSource = new TaskCompletionSource<object>();
                using (MediaPlayer mp = new MediaPlayer())
                {
                    mp.MediaEnded += (s, e) =>
                    {
                        botIsTalking = false;
                        taskSource.SetResult(null);
                    };
                    mp.Source = MediaSource.CreateFromStream(speechOutput.AsRandomAccessStream(), "audio/mpeg");
                    mp.Play();
                    botIsTalking = true;
                    await taskSource.Task;
                }
            }
        }

        private async void LogOutput(string text)
        {
            await cd.RunAsync(CoreDispatcherPriority.Normal, () =>
            {
                txtLog.Text = txtLog.Text + Environment.NewLine + text;
                txtLog.ScrollToBottom();
            });
            Debug.WriteLine(text);
        }
    }
}