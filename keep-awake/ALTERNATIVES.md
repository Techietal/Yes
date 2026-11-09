# Alternatives, in order of how little they touch the machine

If `keepawake.ps1` is blocked, flagged, or you simply do not want a script
running on a managed laptop, work down this list. Every option here uses
something already on the machine.

---

## 1. `presentationsettings.exe` — built in, zero files

The Windows presentation-mode tool. It suppresses the screensaver and display
sleep for as long as it runs.

```
Win+R  ->  presentationsettings.exe /start
```

To stop it:

```
Win+R  ->  presentationsettings.exe /stop
```

**Pros:** no files, no script, no execution policy, nothing to get flagged.
It is a signed Microsoft binary that IT departments expect to see.

**Cons:** it does not reset the *input* idle timer, so a Group Policy
"machine inactivity limit" auto-lock still fires. And some corporate images
disable presentation mode outright — if `/start` silently does nothing, that is
what happened.

---

## 2. Play a long video — the crude but unblockable option

Any video player that calls `SetThreadExecutionState` keeps the display awake
while it plays. That is the same API the script uses, just wrapped in a player
nobody flags.

- Open a long video in the built-in **Movies & TV** app, or a YouTube tab, and
  leave it playing at zero volume.
- A 10-hour "silent black screen" video works well for this.

**Pros:** works on locked-down machines. No files, no permissions, no script.

**Cons:** burns some CPU and battery, and it is inelegant. But it is genuinely
the most reliable thing on this list when everything else is blocked.

---

## 3. Turn the screen timeout off in Settings — if it is not greyed out

```
Settings -> System -> Power & sleep -> Screen: Never
```

Or the screensaver, if that is what is actually firing:

```
Settings -> Personalisation -> Lock screen -> Screen saver settings -> (None)
```

**Pros:** the correct fix, permanently, no process running.

**Cons:** on a company laptop these fields are usually greyed out and labelled
"Some settings are managed by your organisation". If they are editable, stop
here — this is the real answer and you need nothing else.

---

## 4. `powercfg` — the command-line version of option 3

```
powercfg /change monitor-timeout-ac 0
powercfg /change monitor-timeout-dc 0
powercfg /change standby-timeout-ac 0
```

**Pros:** sometimes works where the Settings UI is greyed out.

**Cons:** needs an elevated prompt on most managed machines, and a GPO will
re-apply its own values on the next policy refresh. Check what is actually
enforced with:

```
powercfg /query
```

---

## 5. A hardware mouse jiggler

A small USB dongle that presents itself as a mouse and moves the pointer a pixel
every few minutes. No software, nothing installed, nothing for EDR to scan.

**Pros:** completely invisible to endpoint security, because it is a physical
device.

**Cons:** it is a purchase, it occupies a USB port, and some IT policies forbid
unapproved USB devices outright. Also worth saying plainly: on a company laptop,
a device whose entire purpose is to simulate a human being present is the kind of
thing that gets a laptop taken away if someone notices.

---

## Why the script was warning

The first version called `keybd_event` every 50 seconds to synthesise an F15
keypress. That function is input injection — the same call used by malware to
fake clicks and keystrokes — so endpoint detection tools alert on it by design.
The rewritten `keepawake.ps1` uses only `SetThreadExecutionState`, which is a
documented power-management API and does not touch input at all.

If warnings persist with the rewritten script, the trigger is the `.ps1` file
itself or the PowerShell process, not the API. In that case use option 1 or 2.

---

## A note worth taking seriously

If your employer enforces an inactivity lock, that is usually a deliberate
control — often for compliance reasons rather than spite. Working around it on a
managed device can breach an acceptable-use policy, and the log will show it.
The options above are technically fine; whether they are fine for *you* depends
on your employer's rules, which I cannot see from here.
