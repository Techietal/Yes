# keepawake.ps1
#
# Keeps the screen on and the session from going idle until you lock the PC
# (Win+L), close this window, or press Ctrl+C.
#
# Uses only Windows' built-in APIs. Nothing to install.
#
# Run:  double-click keepawake.bat
#   or: powershell -NoProfile -ExecutionPolicy Bypass -File keepawake.ps1

Add-Type -Namespace KeepAwake -Name Native -MemberDefinition @'
[DllImport("kernel32.dll", SetLastError = true)]
public static extern uint SetThreadExecutionState(uint esFlags);

[DllImport("user32.dll")]
public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, System.UIntPtr dwExtraInfo);
'@

# ES_CONTINUOUS | ES_SYSTEM_REQUIRED | ES_DISPLAY_REQUIRED
# Written as a decimal on purpose: PowerShell reads 0x80000000 as a negative
# Int32, and the uint parameter rejects that.
[uint32]$FLAGS = 2147483651

$VK_F15          = 126   # F15 - no physical key on a normal keyboard, ignored by apps
$KEYEVENTF_KEYUP = 2

Write-Host ""
Write-Host "  Keep-awake is running." -ForegroundColor Green
Write-Host "  Screen will not sleep, dim, or start the screensaver."
Write-Host "  Stops by itself when you lock the PC (Win+L)."
Write-Host "  Or close this window / press Ctrl+C."
Write-Host ""

try {
    while ($true) {
        # 1. Tell Windows this thread needs the system and the display kept awake.
        #    This is the same call video players use during playback.
        [void][KeepAwake.Native]::SetThreadExecutionState($FLAGS)

        # 2. A harmless synthetic keypress resets the user-input idle timer, which
        #    is what a Group Policy "machine inactivity limit" auto-lock measures.
        [KeepAwake.Native]::keybd_event($VK_F15, 0, 0, [UIntPtr]::Zero)
        [KeepAwake.Native]::keybd_event($VK_F15, 0, $KEYEVENTF_KEYUP, [UIntPtr]::Zero)

        Start-Sleep -Seconds 50

        # 3. LogonUI.exe only runs while the lock screen is up. If it appears,
        #    you locked the PC - stop and let the normal power plan take over.
        if (Get-Process -Name LogonUI -ErrorAction SilentlyContinue) {
            Write-Host ""
            Write-Host "  PC locked - keep-awake stopped." -ForegroundColor Yellow
            break
        }
    }
}
finally {
    # Hand control back to the normal power plan.
    [void][KeepAwake.Native]::SetThreadExecutionState([uint32]2147483648)
}
