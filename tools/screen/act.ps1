# act.ps1 -Title <window> -Steps "click:x,y;dbl:x,y;type:text;key:ENTER;wait:ms;esc"
param([string]$Title, [string]$Steps)
. "$PSScriptRoot\dpi.ps1"
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class W {
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int c);
  [DllImport("user32.dll")] public static extern void keybd_event(byte k, byte s, uint f, UIntPtr e);
  [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
  [DllImport("user32.dll")] public static extern void mouse_event(uint f, int x, int y, uint d, UIntPtr e);
  [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
  [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr h);
  [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern IntPtr FindWindow(string c, string t);
}
"@
Add-Type -AssemblyName System.Windows.Forms
function Focus($t) {
  $p = Get-Process | Where-Object { $_.MainWindowTitle -like "*$t*" } | Select-Object -First 1
  $h = if ($p) { $p.MainWindowHandle } else { [IntPtr]::Zero }
  if ($h -eq [IntPtr]::Zero) {
    # dialogs aren't main windows: enumerate top-level windows by title
    Add-Type @"
using System; using System.Text; using System.Runtime.InteropServices;
public class E { public delegate bool CB(IntPtr h, IntPtr l);
 [DllImport("user32.dll")] public static extern bool EnumWindows(CB cb, IntPtr l);
 [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
 [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
 public static IntPtr Find(string t){ IntPtr r=IntPtr.Zero; EnumWindows((h,l)=>{ if(!IsWindowVisible(h)) return true; var sb=new StringBuilder(512); GetWindowText(h,sb,512); if(sb.ToString().Contains(t)){ r=h; return false;} return true;}, IntPtr.Zero); return r; } }
"@ -ErrorAction SilentlyContinue
    $h = [E]::Find($t)
  }
  if ($h -eq [IntPtr]::Zero) { return $false }
  [W]::keybd_event(0x12, 0, 0, [UIntPtr]::Zero); [W]::keybd_event(0x12, 0, 2, [UIntPtr]::Zero)
  if ([W]::IsIconic($h)) { [W]::ShowWindow($h, 9) | Out-Null }
  [W]::SetForegroundWindow($h) | Out-Null
  Start-Sleep -Milliseconds 250
  return ([W]::GetForegroundWindow() -eq $h)
}
$ok = Focus $Title
"focus=$ok"
foreach ($s in $Steps.Split(';')) {
  if ($s -eq '') { continue }
  $kind, $arg = $s.Split(':', 2)
  switch ($kind) {
    'click' { $x, $y = $arg.Split(','); [W]::SetCursorPos([int]$x, [int]$y); Start-Sleep -Milliseconds 80; [W]::mouse_event(2,0,0,0,[UIntPtr]::Zero); [W]::mouse_event(4,0,0,0,[UIntPtr]::Zero); Start-Sleep -Milliseconds 200 }
    'dbl' { $x, $y = $arg.Split(','); [W]::SetCursorPos([int]$x, [int]$y); for($i=0;$i -lt 2;$i++){ [W]::mouse_event(2,0,0,0,[UIntPtr]::Zero); [W]::mouse_event(4,0,0,0,[UIntPtr]::Zero); Start-Sleep -Milliseconds 60 }; Start-Sleep -Milliseconds 200 }
    'type' { [System.Windows.Forms.SendKeys]::SendWait(($arg -replace '([+^%~(){}\[\]])','{$1}')); Start-Sleep -Milliseconds 150 }
    'key' { [System.Windows.Forms.SendKeys]::SendWait("{$arg}"); Start-Sleep -Milliseconds 150 }
    'selall' { [System.Windows.Forms.SendKeys]::SendWait("^a"); Start-Sleep -Milliseconds 100 }
    'wait' { Start-Sleep -Milliseconds ([int]$arg) }
    'focus' { $r = Focus $arg; "focus $arg=$r" }
  }
}
