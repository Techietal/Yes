# keep-awake

Stops a Windows PC from going idle, dimming, or starting the screensaver while
long-running work is in progress (an AI agent, a build, a render, a download).

Nothing to install. `keepawake.ps1` and `keepawake.bat` use only APIs that ship
with Windows. `ALTERNATIVES.md` lists the no-script fallbacks if this one is
blocked or flagged on your machine.

## Use

1. Copy the files into the same folder.
2. **First**, double-click `check-status.bat`. It is read-only and tells you
   whether the screen saver is a personal setting you can just switch off, or
   something enforced by policy.
3. If it says policy, double-click `keepawake.bat`. A console window opens and
   stays open. Leave it running.
4. Close the window, press `Ctrl+C`, or lock the PC (`Win+L`) to stop.

If `check-status` says the screen saver is *not* policy-driven, skip the script
entirely and just turn the screen saver off in Settings. That is permanent and
needs nothing running.

## How it works

One documented Windows API, called once:

```
SetThreadExecutionState(ES_CONTINUOUS | ES_SYSTEM_REQUIRED | ES_DISPLAY_REQUIRED)
```

That is the same call VLC, YouTube and PowerPoint make during playback. It tells
Windows this thread needs the system and the display kept awake, and
`ES_CONTINUOUS` makes it stick for the life of the thread. It is re-asserted
every 30 seconds anyway, because the execution state is per-thread and Windows
clears it on some session events (RDP reconnect, fast user switching, display
hotplug). Re-asserting is one API call and is not input injection.

`ES_DISPLAY_REQUIRED` is the flag Microsoft documents for this exact case:
"Even though there is no mouse or keyboard input, the screen is indeed in use,
so don't blank it or start the screen saver." The screen saver is the target
here, not display timeout - they are separate mechanisms with separate timers,
and setting the display timeout to Never does not stop a screen saver.

The script also checks once every 30 seconds whether `LogonUI.exe` exists. That process only runs while the lock screen is up, so its appearance
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
