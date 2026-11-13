#!/usr/bin/env python3
"""Compositor-level screenshot of one monitor through KWin's ScreenShot2 D-Bus interface.

Usage: kshot.py OUTPUT_NAME OUT.png
  OUTPUT_NAME  the KWin/KScreen output name of the monitor (list them with: kscreen-doctor -o)

Unlike a window grab this captures what the compositor actually shows, so it also catches an
exclusive-fullscreen game and anything stacked above/below it.

Requirements: python3 with `dbus-python` and `Pillow`, KDE Plasma (Wayland or X11).
KWin only lets *authorised* clients call ScreenShot2. Authorisation is by .desktop file:
create ~/.local/share/applications/kshot.desktop containing

    [Desktop Entry]
    Type=Application
    Name=kshot
    Exec=/full/path/to/your/python3 /full/path/to/kshot.py
    NoDisplay=true
    X-KDE-DBUS-Restricted-Interfaces=org.kde.KWin.ScreenShot2

The Exec line must name the python interpreter binary that runs the script (KWin matches on
the caller's executable). Without this file KWin answers with an AccessDenied error.
"""
import sys, os, threading, dbus
from PIL import Image

if len(sys.argv) != 3:
    sys.exit(__doc__)
output, dest = sys.argv[1], sys.argv[2]
bus = dbus.SessionBus()
obj = bus.get_object('org.kde.KWin', '/org/kde/KWin/ScreenShot2')
iface = dbus.Interface(obj, 'org.kde.KWin.ScreenShot2')
r, w = os.pipe(); buf = bytearray()
def reader():
    while True:
        b = os.read(r, 1 << 20)
        if not b: break
        buf.extend(b)
t = threading.Thread(target=reader); t.start()
res = iface.CaptureScreen(output, {'native-resolution': True, 'include-cursor': False}, dbus.types.UnixFd(w))
os.close(w); t.join()
W, H, stride = int(res['width']), int(res['height']), int(res['stride'])
Image.frombuffer('RGBA', (W, H), bytes(buf), 'raw', 'BGRA', stride, 1).convert('RGB').save(dest)
print('saved', dest, W, H)
