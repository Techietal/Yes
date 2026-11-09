# check-status.ps1
#
# Reports what is actually enforcing the screen saver / lock on this machine,
# and whether it is policy-driven or just a personal setting.
#
# Read-only. Changes nothing. Run with:
#   powershell -NoProfile -ExecutionPolicy Bypass -File check-status.ps1

function Get-RegValue {
    param($Path, $Name)
    try {
        $item = Get-ItemProperty -Path $Path -Name $Name -ErrorAction Stop
        return $item.$Name
    } catch {
        return $null
    }
}

function Show {
    param($Label, $Value, $Note)
    if ($null -eq $Value) {
        Write-Host ("  {0,-34} {1}" -f $Label, "not set") -ForegroundColor DarkGray
    } else {
        Write-Host ("  {0,-34} {1}" -f $Label, $Value) -ForegroundColor White
    }
    if ($Note) { Write-Host ("  {0,-34} {1}" -f "", $Note) -ForegroundColor DarkGray }
}

Write-Host ""
Write-Host "  SCREEN SAVER" -ForegroundColor Cyan
Write-Host "  " + ("-" * 60) -ForegroundColor DarkGray

$active = Get-RegValue 'HKCU:\Control Panel\Desktop' 'ScreenSaveActive'
$timeout = Get-RegValue 'HKCU:\Control Panel\Desktop' 'ScreenSaveTimeOut'
$scr = Get-RegValue 'HKCU:\Control Panel\Desktop' 'SCRNSAVE.EXE'
$secure = Get-RegValue 'HKCU:\Control Panel\Desktop' 'ScreenSaverIsSecure'

Show 'Enabled (ScreenSaveActive)' $active
Show 'Timeout (ScreenSaveTimeOut)' $(if ($timeout) { "$timeout sec (~$([math]::Round([int]$timeout / 60, 1)) min)" } else { $null })
Show 'Screensaver file (SCRNSAVE.EXE)' $scr
Show 'Require password on resume' $secure

Write-Host ""
Write-Host "  POLICY OVERRIDES  (if set, Settings is greyed out)" -ForegroundColor Cyan
Write-Host "  " + ("-" * 60) -ForegroundColor DarkGray

$polTimeout = Get-RegValue 'HKCU:\Software\Policies\Microsoft\Windows\Control Panel\Desktop' 'ScreenSaveTimeOut'
$polActive = Get-RegValue 'HKCU:\Software\Policies\Microsoft\Windows\Control Panel\Desktop' 'ScreenSaveActive'
$polSecure = Get-RegValue 'HKCU:\Software\Policies\Microsoft\Windows\Control Panel\Desktop' 'ScreenSaverIsSecure'
$noPage = Get-RegValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\System' 'NoDispScrSavPage'
$inactivity = Get-RegValue 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' 'InactivityTimeoutSecs'

Show 'Policy ScreenSaveTimeOut' $(if ($polTimeout) { "$polTimeout sec (~$([math]::Round([int]$polTimeout / 60, 1)) min)" } else { $null })
Show 'Policy ScreenSaveActive' $polActive
Show 'Policy ScreenSaverIsSecure' $polSecure
Show 'Screen saver tab hidden (NoDispScrSavPage)' $noPage
Show 'InactivityTimeoutSecs (auto-lock)' $(if ($inactivity) { "$inactivity sec (~$([math]::Round([int]$inactivity / 60, 1)) min)" } else { $null })

Write-Host ""
Write-Host "  POWER" -ForegroundColor Cyan
Write-Host "  " + ("-" * 60) -ForegroundColor DarkGray

$scheme = (& powercfg /getactivescheme) 2>$null
Write-Host ("  {0,-34} {1}" -f 'Active scheme', $scheme) -ForegroundColor White

Write-Host ""
Write-Host "  VERDICT" -ForegroundColor Cyan
Write-Host "  " + ("-" * 60) -ForegroundColor DarkGray

$policyDriven = $polTimeout -or $polActive -or $noPage
$gpoSaver = $false

if ($policyDriven) {
    Write-Host "  The screen saver is enforced by policy." -ForegroundColor Yellow
    Write-Host "  You cannot turn it off in Settings - the controls are greyed out"
    Write-Host "  and the policy re-applies on its own schedule."
    Write-Host ""
    Write-Host "  -> keepawake.ps1 is the correct tool. It calls ES_DISPLAY_REQUIRED,"
    Write-Host "     which Microsoft documents as the way to tell Windows the screen is"
    Write-Host "     in use so it does not start the screen saver."
    $gpoSaver = $true
} elseif ($active -eq '1' -and $scr) {
    Write-Host "  The screen saver is a normal personal setting, not policy." -ForegroundColor Green
    Write-Host "  You can just turn it off:"
    Write-Host "    Settings -> Personalisation -> Lock screen -> Screen saver settings"
    Write-Host "    Set to (None), untick 'On resume, display logon screen'."
    Write-Host ""
    Write-Host "  -> Do that first. It is permanent and needs nothing running."
} else {
    Write-Host "  No screen saver is configured in the usual places." -ForegroundColor Green
    Write-Host "  If the screen still blanks after 5 minutes, it is the display"
    Write-Host "  timeout, not a screen saver:"
    Write-Host "    Settings -> System -> Power & sleep -> Screen: Never"
}

if ($inactivity) {
    Write-Host ""
    Write-Host "  NOTE: an inactivity auto-lock policy is also set ($inactivity sec)." -ForegroundColor Yellow
    Write-Host "  That lock is measured against real keyboard/mouse input, so"
    Write-Host "  keepawake.ps1 will NOT prevent it. Only physical input will."
}

Write-Host ""
