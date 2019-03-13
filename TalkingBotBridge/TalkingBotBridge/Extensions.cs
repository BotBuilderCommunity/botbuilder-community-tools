namespace TalkingBotBridge
{
    using Windows.UI.Xaml.Controls;
    using Windows.UI.Xaml.Media;

    public static class Extensions
    {
        public static string RemoveLastChar(this string text, string character)
        {
            if (text.Length < 1) return text;

            int lastPos = text.LastIndexOf(character);
            if (lastPos > 0)
            {
                return text.Remove(lastPos, character.Length);
            }
            else
            {
                return text;
            }
        }

        public static void ScrollToBottom(this TextBox textBox)
        {
            var grid = (Grid)VisualTreeHelper.GetChild(textBox, 0);
            for (var i = 0; i <= VisualTreeHelper.GetChildrenCount(grid) - 1; i++)
            {
                object obj = VisualTreeHelper.GetChild(grid, i);
                if (!(obj is ScrollViewer)) continue;
                ((ScrollViewer)obj).ChangeView(0.0f, ((ScrollViewer)obj).ExtentHeight, 1.0f, true);
                break;
            }
        }
    }
}
