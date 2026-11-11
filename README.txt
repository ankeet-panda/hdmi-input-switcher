HDMI INPUT SWITCHER
Press Ctrl+Alt+1 / Ctrl+Alt+2 to flip a monitor between two sources (e.g. PC and laptop).
Takes about a third of a second to send the command, and works in Duplicate (mirror) mode.

INSTALL
  1. Unzip this folder anywhere.
  2. Double-click Install.bat. No internet, no downloads, no admin rights needed.
  3. Press Enter to accept HDMI1 / HDMI2, or type DP1, DP2, 0x11 etc. to match your cabling.
  Hotkeys work from the shortcuts placed on your Desktop - keep them there.

REQUIREMENTS
  Windows 10/11. Monitor with DDC/CI switched ON in its on-screen menu.
  Cable straight from PC to monitor; some docks/adapters block DDC/CI.

HOW IT WORKS
  Install.bat compiles hdmiswitch.cs (a ~100-line program) with the C# compiler built into
  Windows, so you can read exactly what it does. The program sends the standard DDC/CI
  "input select" command (VCP 0x60) straight to the monitor through Windows' monitor API.
  The monitor itself then takes ~1-2 seconds to re-sync to the new source; that part is
  hardware and cannot be made faster from software.
  Fallback: if Windows hides the monitor in Duplicate mode, the program briefly switches to
  Extend, retries, and switches back to Duplicate.

TROUBLESHOOTING
  - Nothing happens: press the hotkey, then open %USERPROFILE%\HDMI-Input-Switcher\last-run.log
  - Wrong input: some monitors use other codes. Re-run Install.bat and type the hex code.
  - Hotkey ignored: another app owns Ctrl+Alt+1/2. Edit the shortcut's "Shortcut key".

UNINSTALL
  Double-click Uninstall.bat.

