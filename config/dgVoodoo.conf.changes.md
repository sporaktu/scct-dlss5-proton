# dgVoodoo.conf: only the keys that were changed

dgVoodoo2 2.87.6 is not redistributed here; take its `dgVoodoo.conf` from the official archive
and change these keys (section in brackets). `scripts/patchini.py` can do it:

```
python3 scripts/patchini.py "$GAME/System/dgVoodoo.conf" \
  General.OutputAPI=d3d11_fl11_0 DirectX.VRAM=1GB DirectX.dgVoodooWatermark=false \
  "DirectXExt.ExtraEnumeratedResolutions=2560x1440, 3840x2160"
```

| Section | Key | Value |
|---|---|---|
| `[General]` | `OutputAPI` | `d3d11_fl11_0` |
| `[DirectX]` | `VRAM` | `1GB` |
| `[DirectX]` | `dgVoodooWatermark` | `false` |
| `[DirectXExt]` | `ExtraEnumeratedResolutions` | `2560x1440, 3840x2160` |

Tried and **not** useful (see the main README): `DeferredScreenModeSwitch=true` (the game fell
back to 640x480 and saved it), `FullscreenAttributes=fake`, `InheritColorProfileInFullScreenMode=false`,
`AppControlledScreenMode=false`, dgVoodoo's forced-windowed mode. Leave those at their defaults.
