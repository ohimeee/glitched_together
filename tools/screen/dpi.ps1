Add-Type @"
using System; using System.Runtime.InteropServices;
public class Dpi { [DllImport("user32.dll")] public static extern bool SetProcessDPIAware(); }
"@ -ErrorAction SilentlyContinue
[Dpi]::SetProcessDPIAware() | Out-Null
