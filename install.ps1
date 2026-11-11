# One-time setup: compiles the tiny switcher, installs it, creates hotkey shortcuts.
param(
    [string]$InstallDir = "$env:USERPROFILE\HDMI-Input-Switcher",   # not under AppData: packaged apps can redirect that
    [string]$ShortcutDir,            # test override; default = Desktop
    [string]$Input1, [string]$Input2,
    [switch]$Silent
)
$ErrorActionPreference = 'Stop'
function Ask($q, $def) { if ($Silent) { return $def }; $a = Read-Host "$q [$def]"; if ($a) { $a.Trim() } else { $def } }

Write-Host "`n== HDMI Input Switcher setup ==`n"
New-Item -ItemType Directory -Force $InstallDir | Out-Null
foreach ($f in 'hdmiswitch.cs', 'uninstall.ps1') { Copy-Item "$PSScriptRoot\$f" "$InstallDir\$f" -Force }

# csc.exe ships with every Windows 10/11 (.NET Framework 4) - nothing to download.
$csc = @("$env:windir\Microsoft.NET\Framework64\v4.0.30319\csc.exe", "$env:windir\Microsoft.NET\Framework\v4.0.30319\csc.exe") | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $csc) { throw 'Could not find csc.exe (.NET Framework 4). Enable it in Windows Features and re-run.' }
$exe = "$InstallDir\hdmiswitch.exe"
$out = & $csc /nologo /target:winexe /optimize "/out:$exe" "$InstallDir\hdmiswitch.cs" 2>&1 | Out-String
if (-not (Test-Path $exe)) { throw "Compile failed:`n$out" }
Write-Host 'Built hdmiswitch.exe'

Write-Host "`nWhich inputs should the hotkeys select? Options: HDMI1 HDMI2 DP1 DP2 DVI1 DVI2 VGA1 VGA2, or a hex code like 0x11."
if (-not $Input1) { $Input1 = Ask 'Ctrl+Alt+1 switches the monitor to' 'HDMI1' }
if (-not $Input2) { $Input2 = Ask 'Ctrl+Alt+2 switches the monitor to' 'HDMI2' }

if ($ShortcutDir) { $dirs = @($ShortcutDir) }
else { $dirs = @([Environment]::GetFolderPath('Desktop')) }
# one owner per hotkey: remove shortcuts left by older versions in the Start Menu
$old = "$([Environment]::GetFolderPath('Programs'))"
Remove-Item "$old\HDMI Input Switcher" -Recurse -Force -ErrorAction SilentlyContinue
$sh = New-Object -ComObject WScript.Shell
foreach ($d in $dirs) {
    New-Item -ItemType Directory -Force $d | Out-Null
    $n = 0
    foreach ($inp in $Input1, $Input2) {
        $n++
        $l = $sh.CreateShortcut("$d\Switch to $inp.lnk")
        $l.TargetPath = $exe
        $l.Arguments = $inp
        $l.WorkingDirectory = $InstallDir
        $l.Hotkey = "Ctrl+Alt+$n"
        $l.Save()
    }
}
Write-Host "`nDone. Hotkeys: Ctrl+Alt+1 -> $Input1, Ctrl+Alt+2 -> $Input2"
Write-Host "Shortcuts created in: $($dirs -join ', ')"
Write-Host "Installed to: $InstallDir"
Write-Host "If a hotkey does nothing, read $InstallDir\last-run.log after pressing it."
