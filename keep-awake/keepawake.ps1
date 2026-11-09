# keepawake.ps1
#
# Keeps the display on and stops the screensaver from starting, until you lock
# the PC (Win+L), close this window, or press Ctrl+C.
#
# Uses ONE documented Windows API. No synthetic input, no keystroke injection.
#
# ES_DISPLAY_REQUIRED is the flag Microsoft documents for exactly this case:
# "Even though there is no mouse or keyboard input, the screen is indeed in use,
# so don't blank it or start the screen saver." It is the same flag video
# players and PowerPoint use during playback.
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
Write-Host "  Screen will not blank and the screensaver will not start."
Write-Host "  Stops by itself when you lock the PC (Win+L)."
Write-Host "  Or close this window / press Ctrl+C."
Write-Host ""

$firstCall = $true

try {
    while ($true) {
        # Re-asserted every 30s rather than called once. The execution state is
        # per-thread and Windows clears it on some session events (RDP reconnect,
        # fast user switching, display hotplug). Re-asserting is one API call and
        # costs nothing; it is not input injection, so nothing flags it.
        $prev = [KeepAwake.Native]::SetThreadExecutionState($KEEP_AWAKE)

        if ($firstCall) {
            if ($prev -eq 0) {
                Write-Host "  Windows refused the request (returned 0)." -ForegroundColor Red
                Write-Host "  A policy may be blocking it. Run check-status.ps1."
                exit 1
            }
            $firstCall = $false
        }

        # LogonUI.exe only exists while the lock screen is up, so its appearance
        # means you locked the PC and this should stand down.
        if (Get-Process -Name LogonUI -ErrorAction SilentlyContinue) {
            Write-Host ""
            Write-Host "  PC locked - keep-awake stopped." -ForegroundColor Yellow
            break
        }

        Start-Sleep -Seconds 30
    }
}
finally {
    [void][KeepAwake.Native]::SetThreadExecutionState($RELEASE)
}
