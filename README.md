# TabRat

A very simple utility that changes the side buttons on a mouse to work as 
next / previous tab buttons in a web browser.
* Button 4 → Next tab (⌘⌥→)
* Button 5 → Previous tab (⌘⌥←)

Safari uses ⌘⇧] / ⌘⇧[ instead, since it doesn't support ⌘⌥←/→.


## Why I built this

This tool just does one thing and does it well. 

I've used other off the shelf tools, but they're over-complicated for what I need:
* BetterTouchTool costs money and then makes you jump through hoops when your license expires to keep it working.
* Karabiner has oddly complicated configuration for anything beyond a simple key rebinding. It also interferes with mouse acceleration settings (I use CursorSense to disable acceleration and Karabiner interferes with that).

## Install (run at login via LaunchAgent)

```bash
make install   # build + copy to ~/bin/TabRat
make perms     # opens System Settings + shows a popup to tell you what to do
make load      # loads it into LaunchAgent so it's always running
```

`make perms` opens **System Settings → Privacy & Security → Accessibility**
and pops up a dialog with the exact steps to add TabRat there.

## Re-install after changing the code

Every rebuild produces a new, unsigned binary, which macOS treats as a
different app — the old Accessibility entry won't cover it. Each time:

```bash
make reload    # rebuild + reinstall + restart the LaunchAgent
make perms     # walks you through removing the stale entry and re-adding it
```

## Run manually (from Terminal, for testing)

```bash
make build
./TabRat
```

Click the side buttons while a browser is frontmost to confirm they act as
next/previous tab; switch to another app and confirm the buttons behave
normally there. Needs the same Accessibility permission as above.

## Other commands

```bash
make unload    # stop the LaunchAgent
make clean     # remove the local binary
```

Logs: `~/Library/Logs/TabRat.log` and `TabRat.err.log`.
