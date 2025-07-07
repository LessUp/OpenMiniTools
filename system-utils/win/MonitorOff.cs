using System;
using System.Runtime.InteropServices;

namespace MonitorOff
{
    class Program
    {
        // Import Windows API functions
        [DllImport("user32.dll")]
        private static extern int SendMessage(int hWnd, int hMsg, int wParam, int lParam);

        // Constants for SendMessage API
        private const int WM_SYSCOMMAND = 0x0112;
        private const int SC_MONITORPOWER = 0xF170;
        private const int HWND_BROADCAST = 0xFFFF;
        
        // Monitor power states
        private const int MONITOR_ON = -1;
        private const int MONITOR_OFF = 2;
        private const int MONITOR_STANDBY = 1;

        static void Main(string[] args)
        {
            try
            {
                // Send message to turn off monitor
                Console.WriteLine("Turning off monitor in 1 second...");
                System.Threading.Thread.Sleep(1000);
                SendMessage(HWND_BROADCAST, WM_SYSCOMMAND, SC_MONITORPOWER, MONITOR_OFF);
                // Exit immediately without waiting for key press to avoid
                // turning the monitor back on
            }
            catch (Exception ex)
            {
                Console.WriteLine("Error: " + ex.Message);
                Console.ReadKey();
            }
        }
    }
}
