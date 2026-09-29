# Blender setup (so Claude can model for Glitched Together)

## 1. Install Blender
1. Open https://www.blender.org/download/
2. Click **Download Blender 5.2.2 LTS** for Windows. File: `blender-5.2.2-windows-x64.msi` (about 348 MB).
3. Run the `.msi` and keep all the defaults (Next → Next → Install).

## 2. Install the Claude add-on (already downloaded for you)
1. Open Blender and close the splash screen.
2. Go to **Edit → Preferences → Add-ons**.
3. Click the small **⌄ arrow** at the top-right of the Add-ons panel, then **Install from Disk…**
4. Select `C:\Users\User\tools\blender-mcp\addon.py` and click **Install from Disk**.
5. Tick the checkbox next to **Blender MCP** to enable it. Leave "Allow Telemetry" off.
6. Close Preferences.

## 3. Connect Blender to Claude
1. Hover the mouse over the 3D viewport and press **N** to open the sidebar.
2. Click the **MCP for Blender** tab.
3. Click **Connect to MCP server**. It should say **Connected on port 9876**.

## 4. Restart Claude Code
1. Reload VS Code (Ctrl+Shift+P → **Developer: Reload Window**) or close and reopen the Claude panel.
   New MCP servers (`blender` and `Roblox_Studio`) only load on restart.
2. Keep Blender open and connected while Claude models.
3. Tell Claude: **"Blender ready"**.

## Roblox Studio MCP (also needed)
1. Open Roblox Studio.
2. Open the **Assistant** panel → **⋯** menu → settings → turn on **"Enable Studio as MCP server"** (wording may vary by Studio version).
3. The `Roblox_Studio` server is already registered with Claude Code.
