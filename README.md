# DLSS 5 neural rendering in Splinter Cell: Chaos Theory on Linux (Proton-GE, RTX 50)

How to get NVIDIA DLSS 5 neural rendering running in *Tom Clancy's Splinter Cell: Chaos Theory*
(Steam app 13570, a 32-bit Direct3D 9 game from 2005) on Linux under Proton-GE, using the
community [DLSS5-Feeder](https://github.com/jlrouzies-fr/DLSS5-Feeder) stack. This repository
holds the write-up, one patch, build/install scripts and config snippets. It contains **no
binaries** and nothing from NVIDIA, dgVoodoo, ReShade, OptiScaler or the game (see `NOTICE.md`).

Parts of this were worked out together with an AI coding assistant (Claude Code), including the
debugging, the Feeder patch merge and the scripts. Everything below describes what was observed
on one machine; treat the scripts as a starting point, not a tested installer.

## Status

Verified on one machine (RTX 5090, Proton-GE, 3840x2160 monitor):

* The whole chain starts, the game loads a save and plays in gameplay at **3840x2160, about
  100 fps** (see Performance). `dlss5-feed.log` shows frames being delivered to the neural
  pipeline and the effect technique found.
* Two fresh launches from Steam in a row came up clean (menu textures not smeared).

**Not verified / caveats:**

* The in-game **Alt+C** Feeder panel and the **Home** ReShade overlay were **never tested**.
* With default settings the visible effect was subtle. After the changes in
  [docs/realism-tuning.md](docs/realism-tuning.md) (correct depth orientation, full working
  resolution, Shader Model 3.0, stronger neural settings) it is clearly visible in static
  screenshots. Behaviour in motion (ghosting, flicker) was **not** assessed.
* Only tested on RTX 5090. Upstream states the neural model runs on RTX 50-series only.
* The install scripts here were assembled from the manual procedure afterwards and have **not**
  been run end to end. The registry values, ini edits and file placement match what was done by
  hand, but expect to fix a typo or two. `fetch-toolchain.sh` download URLs follow the projects'
  usual naming and were not re-run either.
* NVIDIA Linux driver 615.78.08 was in use. Upstream documents driver/NGX/neural-consumer
  combinations that fail; its helper has a self-test (`host64/dlss5-feed-host64.exe --test`,
  which reported `300/300 evaluates succeeded` here) worth running if the neural pass does nothing.
* The game only renders while it has focus and minimizes when another window is clicked (normal
  for this game in exclusive fullscreen); click it in the taskbar to bring it back.

## Requirements

* Linux, Steam, the game (app 13570), **Proton-GE** (Wine 11.0 was in use per the Feeder log).
* NVIDIA **RTX 50-series** GPU with a working Vulkan/D3D12 stack under Proton (`PROTON_ENABLE_NVAPI`
  was set when testing manually; the final Steam launch used no launch options).
* NVIDIA's `nvngx_dlss.dll` and `nvngx_dlssnr.dll` (the DLSS 5 neural-rendering model). **You must
  supply these yourself and are responsible for their licence terms.** This repository does not
  include, link to or script the download of them. The write-up used version 310.9.16 obtained
  from a community repository, not an official NVIDIA download.
* To build the Feeder: `git`, `curl`, `tar`, `xz`, a Linux x86-64 host (several GB of disk
  for LLVM and the Windows SDK that xwin fetches).
* For `install.sh`: `unzip`, `python3`, and `upx` (used by the dgVoodoo patcher).
* Optional, KDE Plasma only: the KWin window rules and screenshot helpers.

## Architecture

```
splintercell3.exe  (32-bit, D3D9)
   |  Direct3D 9
   v
dgVoodoo2 2.87.6  System/D3D9.dll   (D3D9 -> D3D11; Wine check patched out)
   |  D3D11
   v
ReShade 6.8.0 add-on build  System/dxgi.dll
   + dlss5-feed.addon32  (DLSS5-Feeder 2.0.0 + CPU-sync patch)   <- reads colour, depth, motion vectors
   |  frames handed to a separate 64-bit process, over IPC + CPU sync
   v
System/host64/dlss5-feed-host64.exe  (patched Feeder helper, x86-64, D3D12)
   + ReShade64 as host64/dxgi.dll   (compiles DLSS5_Feed.fx)
   + OptiScaler DLSS-NR fork v0.8.93 as host64/winmm.dll   (the neural consumer)
   + nvngx_dlss.dll / nvngx_dlssnr.dll   (supplied by you)
   |  DLSS Super Resolution (2574x1448 -> 3840x2160) + DLSS 5 neural pass
   v
result copied back into the game's frame -> present
```

Why two processes: NVIDIA ships no 32-bit NGX runtime, so a 32-bit game cannot call DLSS
in-process; the Feeder's 32-bit add-on builds the DLSS inputs and a 64-bit helper runs NGX.

## Install procedure

Variables used below:

```
GAME   = .../steamapps/common/Splintercell Chaos Theory       # game install dir
PREFIX = .../steamapps/compatdata/13570/pfx                   # Proton prefix
WORK   = any scratch dir with several GB free (toolchain + Feeder checkout)
DL     = dir holding the downloaded third-party files (step 3)
```

1. **Run the game once** from Steam and exit it normally, so the prefix and its
   `SplinterCell3.ini` exist. Close Steam's game session before editing the prefix.
2. **Fetch the toolchain and build the Feeder** (clang-cl cross build, no Windows needed):
   ```
   export WORK=...
   scripts/fetch-toolchain.sh      # LLVM 23.1.4, xwin 0.10.0 (+ Windows SDK/CRT), NGX SDK, Vulkan headers
   scripts/build-feeder.sh         # clones DLSS5-Feeder at 9bd0af3 (v2.0.0), applies patches/, builds both halves
   ```
   `fetch-toolchain.sh` runs `xwin --accept-license`, which **accepts Microsoft's licence** for the
   SDK/CRT files for you; read it first. Output: `$WORK/feeder/build/dlss5-feed.addon32` (i686) and
   `dlss5-feed-host64.exe` (x86-64). The two must come from the same build.
3. **Collect the third-party downloads into `$DL`:**
   * `dgVoodoo2_87_6.zip` (dgVoodoo2 2.87.6, github.com/dege-diosg/dgVoodoo2)
   * `patch_dgvoodoo.py` (github.com/cloakedkeys/dgvoodoo-wine-fix)
   * `ReShade_Setup_6.8.0_Addon.exe` (reshade.me, the add-on build)
   * `OptiScaler-NR-v0.8.93.zip` (github.com/jlrouzies-fr/OptiScaler-DLSSNR-PreSR-Multipass)
   * `ReShade.fxh`, `ReShadeUI.fxh`, `DrawText.fxh` (crosire/reshade-shaders, `slim` branch,
     `Shaders/`; these are the files the Feeder's own installer fetches)
   * `nvngx_dlss.dll`, `nvngx_dlssnr.dll` (yours to supply, see Requirements)
4. **Place files and edit configs:**
   ```
   export GAME=... PREFIX=... DL=... FEEDER_BUILD=$WORK/feeder/build FEEDER_SRC=$WORK/feeder
   scripts/install.sh
   ```
   This backs up `$GAME/System` (to `System.bak-pre-dlss5`) and the prefix's ini, then:
   dgVoodoo `D3D9.dll` (patched) + `dgVoodoo.conf` keys, ReShade32 as `System/dxgi.dll`,
   ReShade64 as `System/host64/dxgi.dll`, the Feeder add-on/helper/shader/`dlss5-feed.cfg`,
   `ReShade.ini`/`ReShadePreset.ini`, OptiScaler as `host64/winmm.dll` with its ini keys, the NVIDIA
   DLLs in `host64/`, and the game ini. Set `RES_X`/`RES_Y` for a monitor other than 3840x2160.
   Equivalent manual steps are documented in `config/`.
5. **Wine prefix changes** (`config/wine-registry.md`): per-app DLL overrides for the game and the
   helper, the X11 driver keys, and `winetricks d3dcompiler_47`. `install.sh` prints the `reg add`
   commands, or runs them if `PROTON_DIR` and `STEAM_ROOT` are set.
6. **KDE only:** add `config/kwinrulesrc.snippet` to `~/.config/kwinrulesrc` (see Problems, the
   helper window).
7. **Launch from Steam with no launch options.** Check `System/dlss5-feed.log`: you want
   `technique found`, `host connected`, `frames ... delivered`; and `System/host64/dlss5-feed-host.log`
   for errors. After any crash or kill, delete `Running.ini` (below) before relaunching.

## Problems hit and fixes

| Problem | Fix |
|---|---|
| **Stock Feeder 2.0.0 crashes the game under Wine.** Wine cannot import a D3D12 fence across processes. | `patches/feeder-2.0.0-wine-cpu-sync.patch` (by pilucdes, Feeder issue #121; two hunks hand-merged onto 2.0.0). Frames are handed over on the CPU instead of through a shared fence. Cfg key `wine_cpu_sync`, default 1 (on) under Wine. Both halves must be rebuilt together; a Feeder update overwrites them, so re-apply the patch. |
| **dgVoodoo2 crashes under Wine** (it has hidden Wine detection). | `patch_dgvoodoo.py` from cloakedkeys/dgvoodoo-wine-fix changes one byte so the check never fires. Unpatched original kept as a backup. |
| **`technique MISSING` in `dlss5-feed.log`**: Wine's builtin `d3dcompiler_47` cannot compile `DLSS5_Feed.fx`. | `winetricks d3dcompiler_47` (native, global), and a per-app `builtin` override for `dlss5-feed-host64.exe` so the helper keeps the builtin one. Re-run winetricks if a Proton-GE update resets the prefix. |
| **Resolution resets to 1024x768** on the next start. | If the game is killed rather than exited it leaves `Running.ini` (under the prefix's `AppData/Local/Ubisoft/...`) and resets its settings. Delete that file. |
| **Resolution edits in the game folder have no effect.** | The live ini is `ProgramData/Ubisoft/Tom Clancy's Splinter Cell Chaos Theory/SplinterCell3.ini` **inside the prefix**. `System/SplinterCell3.ini` was also edited but is not the one that matters. |
| **Game freezes after ~3 s at 4K** (`cpu sync: frame N did not finish within 2 s` in `host64/dlss5-feed-host.log`). | The helper needs a real window. Keep `host_window=3` in `dlss5-feed.cfg`; `host_window=2` (windowless) stalls, `0` auto-hides and stalls. |
| **The helper's full-screen window grabs focus / sits above the game**, the fullscreen game minimizes behind it. | KWin rule `[dlss5-feed-host]` (title contains "DLSS 5 Feed host", class `steam_app_13570`: never accept focus, keep below, skip taskbar/switcher/pager). A second rule `[scct-game]` makes the game window bypass focus-stealing prevention so it is focused at launch. Non-KDE desktops need an equivalent. |
| **Smeared menu background/frame textures** on a fresh launch in exclusive fullscreen, until minimize/restore. | Registry `HKCU\Software\Wine\X11 Driver` `UseTakeFocus=N` (`GrabFullscreen=Y` set at the same time). Verified with compositor screenshots; two fresh Steam launches came up clean. |

**Tried and did not work:** dgVoodoo `DeferredScreenModeSwitch=true` (game falls back to
640x480 and saves it), `FullscreenAttributes=fake`, `InheritColorProfileInFullScreenMode=false`,
`AppControlledScreenMode=false`, dgVoodoo forced-windowed (picture fine but mouse mapping is off
and a 22 px strip is left at the bottom), `host_window=2` (helper stalls).

## Performance

RTX 5090, 3840x2160:

* Tuned setup (Shader Model 3.0, full working resolution, 2 neural passes; see
  [docs/realism-tuning.md](docs/realism-tuning.md)): about **52-58 fps**.
* Full working resolution, 1 neural pass, Shader Model 1.1: about 76 fps.
* `work_resolution=67` + `work_upscale=2` (not recommended, see the tuning doc): about 98-100 fps
  launched via Steam on the real monitor, with a steady 10.0 ms frame interval (whether that is a
  refresh cap was not investigated).

## Tuning knobs

* See [docs/realism-tuning.md](docs/realism-tuning.md) for the depth fix, game renderer settings
  and neural model settings, with a before/after image.
* `System/dlss5-feed.cfg`: `work_resolution`, `work_upscale`, `work_sharpness`; keep `dpi_aware=1`
  and `host_window=3`.
* `System/host64/OptiScaler.ini` `[DlssNr]`: `Passes`, `Style`, `Intensity`, `LocalStructure`,
  `TransferStrength`, `WorkingScale`; `DebugView=3` shows what the model changes.
* Game resolution: `FullscreenViewportX/Y` in the prefix ini.
* In-game panels (Alt+C Feeder panel, Home ReShade overlay): exist upstream, untested here.

## Undo

* Game folder: delete `$GAME/System` and rename `$GAME/System.bak-pre-dlss5` back to `System`.
* Prefix (`d3dcompiler_47`, AppDefaults overrides, X11 keys, ProgramData ini): the simplest
  undo is deleting `compatdata/13570` so Proton recreates it. **That also deletes saves**
  (`ProgramData/Ubisoft/.../Profiles`): copy those out first. Alternatively restore
  `SplinterCell3.ini.bak-dlss5` and remove the registry keys by hand.
* KWin: delete the two rule groups from `~/.config/kwinrulesrc`.

## Repository layout

```
patches/   Feeder CPU-sync patch + credit
scripts/   fetch-toolchain.sh, build-feeder.sh, install.sh, patchini.py
config/    dlss5-feed.cfg, ReShade*.ini, key lists for dgVoodoo/OptiScaler/game ini,
           wine-registry.md, kwinrulesrc.snippet
tools/     KDE-only debug helpers (compositor screenshot, window stacking dump)
```

## Credits and licences

* [DLSS5-Feeder](https://github.com/jlrouzies-fr/DLSS5-Feeder) (MIT) by jlrouzies-fr; v2.0.0,
  commit 9bd0af3.
* CPU-sync patch: GitHub user **pilucdes**, Feeder issue #121.
* [OptiScaler DLSS-NR fork](https://github.com/jlrouzies-fr/OptiScaler-DLSSNR-PreSR-Multipass)
  v0.8.93; [dgVoodoo2](https://github.com/dege-diosg/dgVoodoo2) 2.87.6 by Dege;
  [dgvoodoo-wine-fix](https://github.com/cloakedkeys/dgvoodoo-wine-fix) by cloakedkeys;
  [ReShade](https://reshade.me) 6.8.0 by crosire.
* Toolchain: LLVM 23.1.4, [xwin](https://github.com/Jake-Shadle/xwin) 0.10.0, NVIDIA's
  [DLSS SDK headers/lib](https://github.com/NVIDIA/DLSS), KhronosGroup Vulkan-Headers.
* This repository's own scripts and docs: MIT, see `LICENSE`. The patch stays under the Feeder's
  MIT licence. All trademarks belong to their owners; this project is unaffiliated with NVIDIA,
  Ubisoft or any tool author above.
