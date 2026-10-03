# Full screen at physical resolution -> %TEMP%\gt_screen.png scaled to 1280 wide.
# Click coords (physical) = png coords x (physical width / 1280). Laptop panel 1920x1200, Titan monitor 1920x1080.
. "$PSScriptRoot\dpi.ps1"
Add-Type -AssemblyName System.Drawing
Add-Type @"
using System; using System.Runtime.InteropServices;
public class Scr { [DllImport("user32.dll")] public static extern int GetSystemMetrics(int i); }
"@ -ErrorAction SilentlyContinue
$w = [Scr]::GetSystemMetrics(0); $h = [Scr]::GetSystemMetrics(1)
$bmp = New-Object System.Drawing.Bitmap $w, $h
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen(0, 0, 0, 0, $bmp.Size)
$small = New-Object System.Drawing.Bitmap $bmp, 1280, ([int](1280 * $h / $w))
$small.Save("$env:TEMP\gt_screen.png")
"screen ${w}x${h}, scale x$($w / 1280)"
