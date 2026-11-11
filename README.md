# HDMI Input Switcher

Two Windows hotkeys, **Ctrl+Alt+1** and **Ctrl+Alt+2**, that flip a monitor between two inputs (for example a PC
and a laptop) by sending the standard DDC/CI "input select" command (VCP 0x60) to the monitor.

- No downloads, no admin rights: `Install.bat` compiles the small C# program `hdmiswitch.cs` with the C# compiler
  that ships with Windows, installs it to `%USERPROFILE%\HDMI-Input-Switcher` and puts two hotkey shortcuts on the Desktop.
- Works in Duplicate (mirror) mode: if Windows hides the monitor, it briefly switches to Extend, retries, and switches back.
- Requirements: Windows 10/11, a monitor with DDC/CI switched on, a direct cable (some docks block DDC/CI).

Install, troubleshooting and uninstall steps: see [README.txt](README.txt).
`switch-input.ps1` is an earlier PowerShell-only version kept for reference.
