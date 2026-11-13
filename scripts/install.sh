#!/usr/bin/env bash
# Place the DLSS 5 stack into a Splinter Cell: Chaos Theory install and its Proton prefix.
#
# Required environment:
#   GAME          game install dir        (.../steamapps/common/Splintercell Chaos Theory)
#   PREFIX        Proton prefix           (.../steamapps/compatdata/13570/pfx)
#   DL            directory with the downloaded third-party files (names below)
#   FEEDER_BUILD  dir with dlss5-feed.addon32 and dlss5-feed-host64.exe (from build-feeder.sh)
#   FEEDER_SRC    the Feeder checkout (for shaders/DLSS5_Feed.fx)
# Optional:
#   PROTON_DIR + STEAM_ROOT  if both set, the Wine registry values are written through
#                 "$PROTON_DIR/proton run reg add"; otherwise the commands are only printed.
#   WORK          scratch dir (default: a mktemp dir, removed on exit)
#
# Files expected in $DL (you download these yourself; nothing here fetches NVIDIA files):
#   dgVoodoo2_87_6.zip                    github.com/dege-diosg/dgVoodoo2
#   patch_dgvoodoo.py                     github.com/cloakedkeys/dgvoodoo-wine-fix  (needs `upx` on PATH or network)
#   ReShade_Setup_6.8.0_Addon.exe         reshade.me (add-on build)
#   OptiScaler-NR-v0.8.93.zip             github.com/jlrouzies-fr/OptiScaler-DLSSNR-PreSR-Multipass
#   ReShade.fxh ReShadeUI.fxh DrawText.fxh   raw files from github.com/crosire/reshade-shaders (branch "slim", Shaders/)
#   nvngx_dlss.dll  nvngx_dlssnr.dll      NVIDIA NGX runtimes -- YOU must supply these (see README)
#
# Run it with the game NOT running. It backs up $GAME/System once (System.bak-pre-dlss5) and the
# prefix's SplinterCell3.ini (SplinterCell3.ini.bak-dlss5).
set -euo pipefail

: "${GAME:?}"; : "${PREFIX:?}"; : "${DL:?}"; : "${FEEDER_BUILD:?}"; : "${FEEDER_SRC:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CFG="$HERE/../config"
SYS="$GAME/System"; H64="$SYS/host64"
GAME_NAME="Tom Clancy's Splinter Cell Chaos Theory"
PINI="$PREFIX/drive_c/ProgramData/Ubisoft/$GAME_NAME/SplinterCell3.ini"
RUNNING="$PREFIX/drive_c/users/steamuser/AppData/Local/Ubisoft/$GAME_NAME/Running.ini"

die() { echo "error: $*" >&2; exit 1; }
need() { [ -f "$1" ] || die "missing $1"; }

[ -f "$SYS/splintercell3.exe" ] || die "$SYS/splintercell3.exe not found (is GAME right?)"
[ -d "$PREFIX/drive_c" ] || die "$PREFIX is not a Wine prefix"
[ -f "$PINI" ] || die "$PINI not found: start the game once (to create its settings), exit normally, then re-run"
for f in dgVoodoo2_87_6.zip patch_dgvoodoo.py ReShade_Setup_6.8.0_Addon.exe OptiScaler-NR-v0.8.93.zip \
         ReShade.fxh ReShadeUI.fxh DrawText.fxh nvngx_dlss.dll nvngx_dlssnr.dll; do need "$DL/$f"; done
need "$FEEDER_BUILD/dlss5-feed.addon32"; need "$FEEDER_BUILD/dlss5-feed-host64.exe"
need "$FEEDER_SRC/shaders/DLSS5_Feed.fx"
command -v unzip >/dev/null || die "unzip is required"
command -v python3 >/dev/null || die "python3 is required"
pgrep -f splintercell3.exe >/dev/null && die "the game is running; exit it first"

CLEAN=0
if [ -z "${WORK:-}" ]; then WORK="$(mktemp -d)"; CLEAN=1; fi
mkdir -p "$WORK"
[ "$CLEAN" = 1 ] && trap 'rm -rf "$WORK"' EXIT

echo "[1/9] backups"
[ -d "$GAME/System.bak-pre-dlss5" ] || cp -a "$SYS" "$GAME/System.bak-pre-dlss5"
[ -f "$PINI.bak-dlss5" ] || cp -a "$PINI" "$PINI.bak-dlss5"
mkdir -p "$H64" "$SYS/reshade-shaders/Shaders" "$SYS/reshade-shaders/Textures"

echo "[2/9] dgVoodoo2 -> D3D9.dll (Wine detection patched out)"
rm -rf "$WORK/dgv" "$WORK/dgv-patch"; mkdir -p "$WORK/dgv" "$WORK/dgv-patch"
unzip -q -o "$DL/dgVoodoo2_87_6.zip" -d "$WORK/dgv"
cp "$WORK/dgv/MS/x86/D3D9.dll" "$WORK/dgv-patch/D3D9.dll"
python3 "$DL/patch_dgvoodoo.py" "$WORK/dgv-patch" --yes
cmp -s "$WORK/dgv/MS/x86/D3D9.dll" "$WORK/dgv-patch/D3D9.dll" && die "dgVoodoo patch did not change D3D9.dll"
cp "$WORK/dgv-patch/D3D9.dll" "$SYS/D3D9.dll"
[ -f "$SYS/dgVoodoo.conf" ] || cp "$WORK/dgv/dgVoodoo.conf" "$SYS/dgVoodoo.conf"
python3 "$HERE/patchini.py" "$SYS/dgVoodoo.conf" General.OutputAPI=d3d11_fl11_0 DirectX.VRAM=1GB \
  DirectX.dgVoodooWatermark=false "DirectXExt.ExtraEnumeratedResolutions=2560x1440, 3840x2160"

echo "[3/9] ReShade 6.8.0 add-on build -> dxgi.dll (32-bit in System, 64-bit in host64)"
rm -rf "$WORK/rs"; mkdir -p "$WORK/rs"
unzip -q -o "$DL/ReShade_Setup_6.8.0_Addon.exe" -d "$WORK/rs" || [ $? -le 1 ]   # exe with an appended zip: exit 1 = warning
need "$WORK/rs/ReShade32.dll"; need "$WORK/rs/ReShade64.dll"
cp "$WORK/rs/ReShade32.dll" "$SYS/dxgi.dll"
cp "$WORK/rs/ReShade64.dll" "$H64/dxgi.dll"

echo "[4/9] Feeder (patched build), shaders, configs"
cp "$FEEDER_BUILD/dlss5-feed.addon32" "$SYS/"
cp "$FEEDER_BUILD/dlss5-feed-host64.exe" "$H64/"
cp "$FEEDER_SRC/shaders/DLSS5_Feed.fx" "$SYS/reshade-shaders/Shaders/"
for h in ReShade.fxh ReShadeUI.fxh DrawText.fxh; do cp "$DL/$h" "$SYS/reshade-shaders/Shaders/"; done
cp "$CFG/dlss5-feed.cfg" "$SYS/dlss5-feed.cfg"
cp "$CFG/ReShade.ini" "$SYS/ReShade.ini"
cp "$CFG/ReShadePreset.ini" "$SYS/ReShadePreset.ini"
cp "$CFG/host64-ReShade.ini" "$H64/ReShade.ini"

echo "[5/9] OptiScaler DLSS-NR fork -> host64 (OptiScaler.dll installed as winmm.dll)"
rm -rf "$WORK/opti"; mkdir -p "$WORK/opti"
unzip -q -o "$DL/OptiScaler-NR-v0.8.93.zip" -d "$WORK/opti"
O="$WORK/opti"; [ -f "$O/OptiScaler.dll" ] || O="$(dirname "$(find "$WORK/opti" -name OptiScaler.dll | head -1)")"
need "$O/OptiScaler.dll"; need "$O/OptiScaler.ini"
cp "$O/OptiScaler.dll" "$H64/winmm.dll"
cp -r "$O/OptiScaler" "$H64/"
[ -d "$O/Licenses" ] && cp -r "$O/Licenses" "$H64/"
cp "$O/OptiScaler.ini" "$H64/OptiScaler.ini"
python3 "$HERE/patchini.py" "$H64/OptiScaler.ini" \
  Upscalers.Dx12Upscaler=dlss Inputs.EnableXeSSInputs=false Inputs.EnableFsr2Inputs=false \
  Inputs.EnableFsr3Inputs=false Inputs.EnableFfxInputs=false Spoofing.StreamlineSpoofing=false \
  Spoofing.Dxgi=false Log.LogToFile=true Log.LogLevel=2 Hotfix.CheckForUpdate=false DlssNr.Enabled=true

echo "[6/9] NVIDIA NGX runtimes (user supplied)"
cp "$DL/nvngx_dlss.dll" "$DL/nvngx_dlssnr.dll" "$H64/"

echo "[7/9] game ini (prefix copy is the live one) and crash marker"
RES_X="${RES_X:-3840}"; RES_Y="${RES_Y:-2160}"
# (patchini.py splits "Section.Key" on the first dot, which breaks on the dotted section
# name [WinDrv.WindowsClient], hence this small inline editor.)
python3 - "$PINI" "$RES_X" "$RES_Y" <<'PY'
import sys, re
path, x, y = sys.argv[1:4]
want = {('windrv.windowsclient', 'fullscreenviewportx'): x, ('windrv.windowsclient', 'fullscreenviewporty'): y,
        ('general', 'logosvideo'): '', ('general', 'splashvideo'): '', ('general', 'esrbvideo'): ''}
out, sec, done = [], '', set()
for line in open(path, encoding='utf-8', errors='surrogateescape', newline=''):
    m = re.match(r'\s*\[(.+?)\]', line)
    if m: sec = m.group(1).lower()
    m = re.match(r'([ \t]*)([A-Za-z0-9_]+)([ \t]*=[ \t]*)([^\r\n]*)(\r?\n?)$', line)
    if m and (sec, m.group(2).lower()) in want:
        k = (sec, m.group(2).lower()); line = m.group(1) + m.group(2) + m.group(3) + want[k] + m.group(5); done.add(k)
    out.append(line)
open(path, 'w', encoding='utf-8', errors='surrogateescape', newline='').write(''.join(out))
print('game ini: set', len(done), 'of', len(want))
PY
rm -f "$RUNNING"
# keep the install-dir copy in step if it exists
[ -f "$SYS/SplinterCell3.ini" ] && python3 - "$SYS/SplinterCell3.ini" "$RES_X" "$RES_Y" <<'PY' || true
import sys, re
path, x, y = sys.argv[1:4]
s = open(path, encoding='utf-8', errors='surrogateescape', newline='').read()
s = re.sub(r'(?m)^FullscreenViewportX=.*?(\r?)$', r'FullscreenViewportX=' + x + r'\1', s)
s = re.sub(r'(?m)^FullscreenViewportY=.*?(\r?)$', r'FullscreenViewportY=' + y + r'\1', s)
s = re.sub(r'(?m)^(LogosVideo|SplashVideo|ESRBVideo)=.*?(\r?)$', r'\1=\2', s)
open(path, 'w', encoding='utf-8', errors='surrogateescape', newline='').write(s)
PY

echo "[8/9] Wine registry"
reg() { # reg KEY NAME DATA
  if [ -n "${PROTON_DIR:-}" ] && [ -n "${STEAM_ROOT:-}" ]; then
    STEAM_COMPAT_DATA_PATH="$(dirname "$PREFIX")" STEAM_COMPAT_CLIENT_INSTALL_PATH="$STEAM_ROOT" \
      "$PROTON_DIR/proton" run reg add "$1" /v "$2" /d "$3" /f
  else
    printf 'reg add "%s" /v %s /d %s /f\n' "$1" "$2" "$3"
  fi
}
[ -n "${PROTON_DIR:-}" ] && [ -n "${STEAM_ROOT:-}" ] || echo "PROTON_DIR/STEAM_ROOT not set: run these against the prefix yourself (see config/wine-registry.md):"
A='HKCU\Software\Wine\AppDefaults'
reg "$A\\splintercell3.exe\\DllOverrides" d3d9 native,builtin
reg "$A\\splintercell3.exe\\DllOverrides" dxgi native,builtin
reg "$A\\dlss5-feed-host64.exe\\DllOverrides" winmm native,builtin
reg "$A\\dlss5-feed-host64.exe\\DllOverrides" dxgi native,builtin
reg "$A\\dlss5-feed-host64.exe\\DllOverrides" d3dcompiler_47 builtin
reg 'HKCU\Software\Wine\X11 Driver' UseTakeFocus N
reg 'HKCU\Software\Wine\X11 Driver' GrabFullscreen Y

echo "[9/9] manual steps left"
cat <<MSG
  * Install Microsoft's d3dcompiler_47 into the prefix:  WINEPREFIX="$PREFIX" winetricks d3dcompiler_47
    (or: protontricks 13570 d3dcompiler_47). It sets a global native override; the helper's per-app
    'builtin' override from the registry step takes precedence for that one process.
  * KDE only: add config/kwinrulesrc.snippet to ~/.config/kwinrulesrc (helper window must never take focus).
  * Launch the game from Steam with no launch options. Check System/dlss5-feed.log for
    "technique found" and "frame ... delivered".
Undo: delete $SYS and rename $GAME/System.bak-pre-dlss5 back to System.
MSG
