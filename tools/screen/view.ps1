# view.ps1 [-Name out] [-Wait ms]: focus Studio (Adventure), wait, capture the 3D viewport at full res
param([string]$Name = "view", [int]$Wait = 900, [string]$Title = "Adventure.rbxl - Roblox Studio")
$sp = $PSScriptRoot
. "$sp\dpi.ps1"
& "$sp\act.ps1" -Title $Title -Steps "wait:$Wait" | Out-Null
Add-Type -AssemblyName System.Drawing
# viewport of a maximized Studio with Explorer docked right (real px)
$x = 6; $y = 212; $w = 1648; $h = 852
$bmp = New-Object System.Drawing.Bitmap $w, $h
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen($x, $y, 0, 0, $bmp.Size)
$small = New-Object System.Drawing.Bitmap $bmp, 1240, 642
$small.Save("$env:TEMP\gt_$Name.png")
"saved $env:TEMP\gt_$Name.png"
