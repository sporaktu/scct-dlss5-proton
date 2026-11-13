#!/usr/bin/env bash
# Build the patched DLSS5-Feeder 2.0.0 halves with clang-cl:
#   dlss5-feed.addon32        (i686 ReShade add-on, loaded by the 32-bit game)
#   dlss5-feed-host64.exe     (x86_64 helper that talks to NGX)
# Both must come from the same build; do not mix with stock release binaries.
#
# Usage: WORK=/path/to/workdir ./build-feeder.sh
# Run fetch-toolchain.sh first. Output goes to $WORK/feeder/build/.
# Optional: FEEDER_REF (default 9bd0af3, the v2.0.0 commit), PATCH (default: ../patches/...).
set -euo pipefail

: "${WORK:?set WORK to the directory used by fetch-toolchain.sh}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATCH="${PATCH:-$HERE/../patches/feeder-2.0.0-wine-cpu-sync.patch}"
FEEDER_REF="${FEEDER_REF:-9bd0af3}"
FEEDER_REPO="${FEEDER_REPO:-https://github.com/jlrouzies-fr/DLSS5-Feeder.git}"
SRC="$WORK/feeder"
L="$WORK/llvm/bin"; K="$WORK/sdk"

[ -x "$L/clang-cl" ] && [ -d "$K/crt" ] || { echo "toolchain missing: run fetch-toolchain.sh" >&2; exit 1; }
[ -f "$PATCH" ] || { echo "patch not found: $PATCH" >&2; exit 1; }

if [ ! -d "$SRC/.git" ]; then
  git clone "$FEEDER_REPO" "$SRC"
  git -C "$SRC" checkout --detach "$FEEDER_REF"
  git -C "$SRC" apply --check "$PATCH"
  git -C "$SRC" apply "$PATCH"
else
  echo "reusing existing checkout $SRC (delete it to start over)"
fi
cd "$SRC"

# Third-party pieces the Feeder expects under external/ (not vendored upstream).
mkdir -p external/ngx/libs external/vulkan/vulkan external/vulkan/vk_video build/x86 build/x64
cp -f "$WORK"/ngx/include/*.h external/ngx/
cp -f "$WORK/ngx/lib/Windows_x86_64/x64/nvsdk_ngx_d.lib" external/ngx/libs/
cp -f "$WORK"/vkh/include/vulkan/*.h external/vulkan/vulkan/
cp -f "$WORK"/vkh/include/vk_video/*.h external/vulkan/vk_video/

INC=(/imsvc "$K/crt/include" /imsvc "$K/sdk/include/ucrt" /imsvc "$K/sdk/include/um"
     /imsvc "$K/sdk/include/shared" /imsvc "$K/sdk/include/winrt")
ID="/DFEED_BUILD_ID=\"${FEEDER_REF}+cpusync\""

echo "== dlss5-feed.addon32 (i686)"
"$L/clang-cl" --target=i686-pc-windows-msvc -fuse-ld=lld /nologo /LD /EHsc /O2 /MD /W3 /std:c++20 "$ID" "${INC[@]}" \
  /Iexternal/reshade/include /Iexternal/imgui /Iexternal/vulkan /Iexternal/minhook/include /Fobuild/x86/ \
  src/dlss5-feed32.cpp external/minhook/src/buffer.c external/minhook/src/hook.c \
  external/minhook/src/trampoline.c external/minhook/src/hde/hde32.c \
  /link /OUT:build/dlss5-feed.addon32 /IMPLIB:build/x86/dlss5-feed32.lib \
  "/LIBPATH:$K/crt/lib/x86" "/LIBPATH:$K/sdk/lib/um/x86" "/LIBPATH:$K/sdk/lib/ucrt/x86" \
  d3d11.lib dwmapi.lib kernel32.lib user32.lib advapi32.lib

echo "== dlss5-feed-host64.exe (x86_64)"
( cd host
  "$L/clang-cl" --target=x86_64-pc-windows-msvc -fuse-ld=lld /nologo /O2 /EHsc /W3 /MD "$ID" "${INC[@]}" \
    /I../external/ngx /Fo../build/x64/ dlss5-feed-host64.cpp \
    /Fe:../build/dlss5-feed-host64.exe \
    /link ../external/ngx/libs/nvsdk_ngx_d.lib \
    "/LIBPATH:$K/crt/lib/x86_64" "/LIBPATH:$K/sdk/lib/um/x86_64" "/LIBPATH:$K/sdk/lib/ucrt/x86_64" \
    version.lib winmm.lib kernel32.lib user32.lib gdi32.lib advapi32.lib ole32.lib )

ls -l build/dlss5-feed.addon32 build/dlss5-feed-host64.exe
echo "built. Next: FEEDER_BUILD=$SRC/build FEEDER_SRC=$SRC ./install.sh"
