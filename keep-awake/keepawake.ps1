# keepawake.ps1
#
# Keeps the display on and the session from going idle until you lock the PC
# (Win+L), close this window, or press Ctrl+C.
#
# Uses ONE documented Windows API and nothing else. No synthetic input, no
# keystroke injection, no polling of anything security software cares about.
# This is the same call VLC, YouTube and PowerPoint make during playback.
#
# Run:  double-click keepawake.bat
#   or: powershell -NoProfile -ExecutionPolicy Bypass -File keepawake.ps1

Add-Type -Namespace KeepAwake -Name Native -MemberDefinition @'
[DllImport("kernel32.dll", SetLastError = true)]
public static extern uint SetThreadExecutionState(uint esFlags);
'@

# ES_CONTINUOUS | ES_SYSTEM_REQUIRED | ES_DISPLAY_REQUIRED
# Written as a decimal on purpose: PowerShell reads 0x80000000 as a negative
# Int32, and the uint parameter rejects that.
[uint32]$KEEP_AWAKE = 2147483651

# ES_CONTINUOUS alone - hands control back to the normal power plan.
[uint32]$RELEASE = 2147483648

Write-Host ""
Write-Host "  Keep-awake is running." -ForegroundColor Green
Write-Host "  Screen will not sleep, dim, or start the screensaver."
Write-Host "  Stops by itself when you lock the PC (Win+L)."
Write-Host "  Or close this window / press Ctrl+C."
Write-Host ""

try {
    # One call. ES_CONTINUOUS makes it stick for the life of this thread, so
    # there is nothing to re-assert and no loop churning in the background.
    $prev = [KeepAwake.Native]::SetThreadExecutionState($KEEP_AWAKE)
    if ($prev -eq 0) {
        Write-Host "  Windows refused the request (SetThreadExecutionState returned 0)." -ForegroundColor Red
        Write-Host "  A policy on this machine may be blocking it. See ALTERNATIVES.md."
        exit 1
    }

    # Idle here. LogonUI.exe only exists while the lock screen is up, so its
    # appearance means you locked the PC and this should stand down.
    while (-not (Get-Process -Name LogonUI -ErrorAction SilentlyContinue)) {
        Start-Sleep -Seconds 30
    }

    Write-Host ""
    Write-Host "  PC locked - keep-awake stopped." -ForegroundColor Yellow
}
finally {
    [void][KeepAwake.Native]::SetThreadExecutionState($RELEASE)
}
