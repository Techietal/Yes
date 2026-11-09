# keep-awake

Stops a Windows PC from going idle, dimming, or starting the screensaver while
long-running work is in progress (an AI agent, a build, a render, a download).

Nothing to install. `keepawake.ps1` and `keepawake.bat` use only APIs that ship
with Windows. `ALTERNATIVES.md` lists the no-script fallbacks if this one is
blocked or flagged on your machine.

## Use

1. Copy `keepawake.ps1` and `keepawake.bat` into the same folder.
2. Double-click `keepawake.bat`.
3. A console window opens and stays open. Leave it running.
4. Close the window, press `Ctrl+C`, or lock the PC (`Win+L`) to stop.

## How it works

One documented Windows API, called once:

```
SetThreadExecutionState(ES_CONTINUOUS | ES_SYSTEM_REQUIRED | ES_DISPLAY_REQUIRED)
```

That is the same call VLC, YouTube and PowerPoint make during playback. It tells
Windows this thread needs the system and the display kept awake, and
`ES_CONTINUOUS` makes it stick for the life of the thread, so there is no loop
re-asserting it.

The script then idles, checking once every 30 seconds whether `LogonUI.exe`
exists. That process only runs while the lock screen is up, so its appearance
means you locked the PC and the script stands down. On exit it calls
`SetThreadExecutionState(ES_CONTINUOUS)` alone, handing control back to the
normal power plan.

There is **no synthetic input** in this version. The first release called
`keybd_event` to fake an F15 keypress every 50 seconds; `keybd_event` is input
injection, the same call malware uses to fake clicks, and endpoint detection
tools alert on it by design. It has been removed.

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
  workstation on a timer enforced at a level the API cannot reach. If your
  employer enforces an inactivity lock, that is usually a deliberate control, and
  working around it on a managed device can breach an acceptable-use policy.
- If endpoint security flags the script, the trigger is the `.ps1` file or the
  PowerShell process, not the API. See `ALTERNATIVES.md` for options that involve
  no script at all.

## Tested

Written and reviewed on macOS, so the PowerShell was never executed against a
Windows host before publishing. Treat it as reviewed-but-unrun on first use.
