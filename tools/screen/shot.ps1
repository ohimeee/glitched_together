# full screen at physical res (1920x1200) -> screen.png at 1280x800 (click coords = png coords x 1.5)
. "$PSScriptRoot\dpi.ps1"
Add-Type -AssemblyName System.Drawing, System.Windows.Forms
$bmp = New-Object System.Drawing.Bitmap 1920, 1200
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen(0, 0, 0, 0, $bmp.Size)
$small = New-Object System.Drawing.Bitmap $bmp, 1280, 800
$small.Save("$PSScriptRoot\screen.png")
