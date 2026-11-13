# Wine registry changes in the game's Proton prefix

`$PREFIX` = `.../steamapps/compatdata/13570/pfx`. Run these against that prefix with a Wine that
matches Proton-GE (for example `WINEPREFIX="$PREFIX" "$PROTON_DIR/files/bin/wine" reg add ...`,
or `STEAM_COMPAT_DATA_PATH=<compatdata/13570> STEAM_COMPAT_CLIENT_INSTALL_PATH=<steam root>
"$PROTON_DIR/proton" run reg add ...`). The resulting values were checked in the prefix's
`user.reg`; which exact launcher was used to enter them was not recorded.

Close the game and Steam's Proton session first so the registry is not rewritten on exit.

## DLL overrides, game (ReShade as dxgi.dll, dgVoodoo as d3d9.dll)

```
reg add "HKCU\Software\Wine\AppDefaults\splintercell3.exe\DllOverrides" /v d3d9 /d native,builtin /f
reg add "HKCU\Software\Wine\AppDefaults\splintercell3.exe\DllOverrides" /v dxgi /d native,builtin /f
```

## DLL overrides, 64-bit helper (OptiScaler as winmm.dll, ReShade as dxgi.dll)

```
reg add "HKCU\Software\Wine\AppDefaults\dlss5-feed-host64.exe\DllOverrides" /v winmm /d native,builtin /f
reg add "HKCU\Software\Wine\AppDefaults\dlss5-feed-host64.exe\DllOverrides" /v dxgi /d native,builtin /f
reg add "HKCU\Software\Wine\AppDefaults\dlss5-feed-host64.exe\DllOverrides" /v d3dcompiler_47 /d builtin /f
```

The last line forces the helper back to Wine's builtin d3dcompiler_47, see below.

## X11 driver (fixes smeared menu textures in exclusive fullscreen)

```
reg add "HKCU\Software\Wine\X11 Driver" /v UseTakeFocus /d N /f
reg add "HKCU\Software\Wine\X11 Driver" /v GrabFullscreen /d Y /f
```

`UseTakeFocus=N` is the one that fixed the smear. `GrabFullscreen=Y` was set at the same time;
it was not tested separately.

## d3dcompiler_47 (winetricks)

Wine's builtin `d3dcompiler_47` cannot compile `DLSS5_Feed.fx`; ReShade then reports the
technique as missing (`technique MISSING` in `dlss5-feed.log`). Install Microsoft's copy into
the prefix:

```
WINEPREFIX="$PREFIX" winetricks d3dcompiler_47      # or: protontricks 13570 d3dcompiler_47
```

Winetricks sets a **global** native override (`HKCU\Software\Wine\DllOverrides`,
`*d3dcompiler_47 = native`). The per-application `builtin` override above makes
`dlss5-feed-host64.exe` ignore it and keep using Wine's builtin one, which is what that process
needs. The game process (where ReShade compiles the effect) uses the native one.

If a Proton-GE update resets the prefix, re-run winetricks and re-check these keys.
