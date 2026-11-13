# Debug helpers (KDE Plasma only)

These were used to verify the setup with compositor-level screenshots and to see which window
had focus. None of them is needed to play.

* `kshot.py OUTPUT_NAME OUT.png` - screenshot of one monitor via KWin's `ScreenShot2` D-Bus
  interface. KWin only allows this for a program that is declared in a `.desktop` file with
  `X-KDE-DBUS-Restricted-Interfaces=org.kde.KWin.ScreenShot2`, and the file's `Exec=` line has to
  name the **python interpreter binary** that runs the script. The exact file is in the
  docstring at the top of `kshot.py`. List output names with `kscreen-doctor -o`.
  Needs `python3-dbus` and `Pillow`.
* `kwinrun.sh SCRIPT.js TAG` + `kwinls.js` - run a one-shot KWin script and print what it
  logged. `kwinrun.sh kwinls.js KWLS` prints the window stacking order with ACTIVE / FS / MIN
  flags, which is how the helper-window-on-top problem was diagnosed.
  Needs `qdbus6` and the user journal.
