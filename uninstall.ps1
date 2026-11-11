param([string]$InstallDir = "$env:USERPROFILE\HDMI-Input-Switcher", [string]$ShortcutDir)
$sh = New-Object -ComObject WScript.Shell
$dirs = if ($ShortcutDir) { @($ShortcutDir) } else { @([Environment]::GetFolderPath('Desktop')) }
foreach ($d in $dirs) {
    Get-ChildItem $d -Filter 'Switch to *.lnk' -ErrorAction SilentlyContinue |
        Where-Object { $sh.CreateShortcut($_.FullName).TargetPath -like '*hdmiswitch.exe' } |
        Remove-Item -Force
}
# the running copy lives in $InstallDir, so delete it after this process exits
Start-Process cmd.exe -ArgumentList "/c timeout /t 2 >nul & rmdir /s /q `"$InstallDir`"" -WindowStyle Hidden
Write-Host 'HDMI Input Switcher removed.'
