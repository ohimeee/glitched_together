# bgshot.ps1 [-Title "Adventure"] [-Out path.png] [-Width 960] [-Viewport]
# Captures a window WITHOUT focusing it or touching the mouse (PrintWindow + PW_RENDERFULLCONTENT).
# Works for Studio in Edit and during Play while it sits behind other windows (not minimized).
# -Viewport crops to the 3D viewport of a maximized Studio with Explorer docked right (approx).
param([string]$Title = "Adventure", [string]$Out = "$env:TEMP\gt_bg.png", [int]$Width = 960, [switch]$Viewport)
Add-Type @"
using System; using System.Runtime.InteropServices;
public class BgShot {
  [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr h, IntPtr dc, uint f);
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
  [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr h);
  public struct RECT { public int L, T, R, B; }
}
"@ -ErrorAction SilentlyContinue
Add-Type -AssemblyName System.Drawing
[BgShot]::SetProcessDPIAware() | Out-Null
$p = Get-Process | Where-Object { $_.MainWindowTitle -like "*$Title*" } | Select-Object -First 1
if (-not $p) { "no window matching '$Title'"; exit 1 }
if ([BgShot]::IsIconic($p.MainWindowHandle)) { "window is minimized: can't capture without restoring it"; exit 1 }
$r = New-Object BgShot+RECT
[BgShot]::GetWindowRect($p.MainWindowHandle, [ref]$r) | Out-Null
$w = $r.R - $r.L; $h = $r.B - $r.T
$bmp = New-Object System.Drawing.Bitmap $w, $h
$g = [System.Drawing.Graphics]::FromImage($bmp)
$dc = $g.GetHdc()
[BgShot]::PrintWindow($p.MainWindowHandle, $dc, 2) | Out-Null
$g.ReleaseHdc($dc)
if ($Viewport) {
  # fractions measured on a maximized Studio (laptop panel): viewport between toolbar and output/command bar
  $rect = New-Object System.Drawing.Rectangle ([int]($w * 0.006)), ([int]($h * 0.19)), ([int]($w * 0.853)), ([int]($h * 0.73))
  $bmp = $bmp.Clone($rect, $bmp.PixelFormat)
  $w = $rect.Width; $h = $rect.Height
}
(New-Object System.Drawing.Bitmap $bmp, $Width, ([int]($Width * $h / $w))).Save($Out)
"saved $Out (${w}x${h})"
