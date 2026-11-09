# keep-awake

Stops a Windows PC from going idle, dimming, or starting the screensaver while
long-running work is in progress (an AI agent, a build, a render, a download).

Nothing to install. Two files, both using APIs that ship with Windows.

## Use

1. Copy `keepawake.ps1` and `keepawake.bat` into the same folder.
2. Double-click `keepawake.bat`.
3. A console window opens and stays open. Leave it running.
4. Close the window, press `Ctrl+C`, or lock the PC (`Win+L`) to stop.

## How it works

Three mechanisms, because they cover different things:

| # | Mechanism | What it prevents |
|---|-----------|------------------|
| 1 | `SetThreadExecutionState(ES_CONTINUOUS \| ES_SYSTEM_REQUIRED \| ES_DISPLAY_REQUIRED)` | Display sleep, dimming, screensaver. The same call video players use during playback. |
| 2 | Synthetic `F15` keypress every 50s | The user-input idle timer that a Group Policy "machine inactivity limit" auto-lock measures. `F15` has no physical key on a normal keyboard and is ignored by applications. |
| 3 | `LogonUI.exe` process check | Detects that the PC was locked, then exits and restores normal power behaviour. |

On exit the script calls `SetThreadExecutionState(ES_CONTINUOUS)` alone, which
hands control back to the normal power plan. It does not leave the machine in a
modified state.

## Requirements

- Windows 10 or 11.
- Windows PowerShell 5.1 (built in) or PowerShell 7+.

## Notes and limits

- `Win+L` is **lock**, not sleep. The script treats lock as its off switch.
- If the machine is managed and AppLocker or a PowerShell execution policy blocks
  `.ps1` files, `keepawake.bat` will fail too. The zero-footprint fallback is
  `presentationsettings.exe /start` from the Run dialog, which suppresses the
  screensaver and display sleep but does **not** reset the input idle timer, so a
  GPO auto-lock will still fire.
- A UAC secure-desktop prompt can briefly spawn `LogonUI.exe` and make the script
  believe the PC was locked. Restart it if that happens.
- This keeps the *session* awake. It does not defeat a policy that locks the
  workstation on a timer enforced at a level the synthetic keypress cannot reach.

## Tested

Written and reviewed on macOS, so the PowerShell was never executed against a
Windows host before publishing. Treat it as reviewed-but-unrun on first use.
