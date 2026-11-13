# Game settings (SplinterCell3.ini)

The **live** file is inside the prefix, not the game folder:

```
$PREFIX/drive_c/ProgramData/Ubisoft/Tom Clancy's Splinter Cell Chaos Theory/SplinterCell3.ini
```

(`$GAME/System/SplinterCell3.ini` was edited the same way, but the game reads and rewrites the
ProgramData copy.) Keys that were changed:

| Section | Key | Value |
|---|---|---|
| `[WinDrv.WindowsClient]` | `FullscreenViewportX` | `3840` |
| `[WinDrv.WindowsClient]` | `FullscreenViewportY` | `2160` |
| `[GENERAL]` | `LogosVideo`, `SplashVideo`, `ESRBVideo` | *(empty)* |

Use your monitor's resolution for the viewport values. Back the file up first (the original was
kept as `SplinterCell3.ini.bak-dlss5` next to it).

## The Running.ini crash marker

If the game is killed instead of exited it leaves

```
$PREFIX/drive_c/users/steamuser/AppData/Local/Ubisoft/Tom Clancy's Splinter Cell Chaos Theory/Running.ini
```

and on the next start it resets its settings to 1024x768. Delete that file before launching
after any crash or kill.

## Renderer quality (see docs/realism-tuning.md)

| Key | Value |
|---|---|
| `ShaderModel` | `3` |
| `Anisotropy` | `16` |
| `ShadowQuality` | `2` |
| `HiResTextures` | `1` |
| `UseHWShadowMapping` | `True` |
