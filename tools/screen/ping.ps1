# ping.ps1 -Msg "why I need the mouse": topmost popup asking the user for mouse/screen time.
# Prints OK (user clicked OK = go ahead) or NO (Cancel / closed). Blocks until answered,
# so run it with a long tool timeout. Beeps so the user notices it over a fullscreen app.
param([string]$Msg = "Claude needs the mouse for a moment.")
Add-Type -AssemblyName System.Windows.Forms
[System.Media.SystemSounds]::Exclamation.Play()
$owner = New-Object System.Windows.Forms.Form -Property @{ TopMost = $true; ShowInTaskbar = $false }
$r = [System.Windows.Forms.MessageBox]::Show($owner, "$Msg`n`nOK = take the mouse now (don't touch it until I'm done).`nCancel = not now.", "Claude (Glitched Together) needs the mouse", "OKCancel", "Information")
$owner.Dispose()
if ($r -eq "OK") { "OK" } else { "NO" }
