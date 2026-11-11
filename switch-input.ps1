# Switches the monitor input via DDC/CI. Usage: switch-input.ps1 HDMI1|HDMI2|DP1|DP2|0x11 ...
# Duplicate (mirror) mode hides the external monitor's DDC/CI handle, so: extend -> switch -> restore Duplicate.
param([Parameter(Mandatory)][string]$Target)
Add-Type -Namespace W -Name D -MemberDefinition '
[DllImport("user32.dll")] public static extern int GetDisplayConfigBufferSizes(uint f, out uint p, out uint m);
[DllImport("user32.dll")] public static extern int QueryDisplayConfig(uint f, ref uint p, byte[] pi, ref uint m, byte[] mi, IntPtr t);'
function Test-Clone {
    $p = 0; $m = 0
    if ([W.D]::GetDisplayConfigBufferSizes(2, [ref]$p, [ref]$m) -ne 0 -or $p -lt 2) { return $false }
    $pi = New-Object byte[] (72 * $p); $mi = New-Object byte[] (64 * $m)
    if ([W.D]::QueryDisplayConfig(2, [ref]$p, $pi, [ref]$m, $mi, [IntPtr]::Zero) -ne 0) { return $false }
    # two active paths sharing one source id = Duplicate
    $ids = 0..($p - 1) | ForEach-Object { [BitConverter]::ToUInt32($pi, 72 * $_ + 8) }
    return (($ids | Select-Object -Unique).Count -lt $p)
}
$wasClone = Test-Clone
$ds = "$env:windir\System32\DisplaySwitch.exe"
if ($wasClone) { & $ds /extend; Start-Sleep -Seconds 2 }
$exe = Join-Path $PSScriptRoot 'ddcswitch.exe'
for ($i = 0; $i -lt 4; $i++) {
    # pick the monitor that answers DDC/CI (status OK) instead of assuming an index
    $row = & $exe list 2>&1 | Where-Object { $_ -match '\u2713 OK' } | Select-Object -First 1
    $idx = if ($row -match '\u2502\s*(\d+)\s') { $Matches[1] } else { '1' }
    $out = & $exe set $idx input $Target 2>&1 | Out-String
    if ($out -notmatch 'fail|error|unable|cannot') { break }
    Start-Sleep -Seconds 1
}
"$(Get-Date -Format s)  was duplicate: $wasClone`n$out" | Out-File (Join-Path $PSScriptRoot 'last-run.log')
if ($wasClone) { Start-Sleep -Seconds 1; & $ds /clone }