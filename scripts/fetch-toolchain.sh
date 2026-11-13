#!/usr/bin/env bash
# Download the Linux-hosted cross toolchain used to build the DLSS5-Feeder halves with clang-cl:
#   - LLVM (clang-cl, lld-link)
#   - xwin: downloads the Windows SDK + MSVC CRT headers/libs from Microsoft and "splats" them
#   - NVIDIA NGX SDK headers + nvsdk_ngx_d.lib  (github.com/NVIDIA/DLSS)
#   - Khronos Vulkan-Headers
#
# Usage: WORK=/path/to/workdir ./fetch-toolchain.sh
#
# NOTE ON LICENCES: `xwin --accept-license` below accepts Microsoft's licence terms for the
# Windows SDK / Visual C++ redistributable files on your behalf. Read them first
# (https://go.microsoft.com/fwlink/?LinkId=2086102 and the Visual Studio licence) and remove the
# flag if you do not agree. The NGX SDK is NVIDIA's and is under NVIDIA's licence (see
# $WORK/ngx/LICENSE.txt after the download).
#
# The download URLs follow each project's usual release naming and were not re-run when this
# script was written; if one 404s, check the project's releases page and override the variable.
set -euo pipefail

: "${WORK:?set WORK to the directory the toolchain should live in}"
LLVM_VER="${LLVM_VER:-23.1.4}"
XWIN_VER="${XWIN_VER:-0.10.0}"
LLVM_URL="${LLVM_URL:-https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_VER}/LLVM-${LLVM_VER}-Linux-X64.tar.xz}"
XWIN_URL="${XWIN_URL:-https://github.com/Jake-Shadle/xwin/releases/download/${XWIN_VER}/xwin-${XWIN_VER}-x86_64-unknown-linux-musl.tar.gz}"
NGX_REPO="${NGX_REPO:-https://github.com/NVIDIA/DLSS.git}"
VKH_REPO="${VKH_REPO:-https://github.com/KhronosGroup/Vulkan-Headers.git}"

for t in curl tar git; do command -v "$t" >/dev/null || { echo "missing tool: $t" >&2; exit 1; }; done
mkdir -p "$WORK"
cd "$WORK"

if [ ! -x "$WORK/llvm/bin/clang-cl" ]; then
  echo "== LLVM $LLVM_VER"
  mkdir -p llvm
  curl -fL --retry 3 -o llvm.tar.xz "$LLVM_URL"
  tar -xf llvm.tar.xz -C llvm --strip-components=1
  rm -f llvm.tar.xz
fi
# clang-cl is normally installed as a symlink to clang; lld-link likewise to lld.
[ -e "$WORK/llvm/bin/clang-cl" ] || ln -s clang "$WORK/llvm/bin/clang-cl"
[ -e "$WORK/llvm/bin/lld-link" ] || ln -s lld "$WORK/llvm/bin/lld-link"

if [ ! -x "$WORK/xwin/xwin" ]; then
  echo "== xwin $XWIN_VER"
  mkdir -p xwin
  curl -fL --retry 3 -o xwin.tar.gz "$XWIN_URL"
  tar -xzf xwin.tar.gz -C xwin --strip-components=1
  rm -f xwin.tar.gz
fi

if [ ! -d "$WORK/sdk/crt" ]; then
  echo "== Windows SDK + CRT via xwin (accepting Microsoft's licence, see header)"
  "$WORK/xwin/xwin" --accept-license --cache-dir "$WORK/xwin-cache" --arch x86,x86_64 \
      splat --output "$WORK/sdk"
fi

if [ ! -f "$WORK/ngx/lib/Windows_x86_64/x64/nvsdk_ngx_d.lib" ]; then
  echo "== NVIDIA NGX SDK (github.com/NVIDIA/DLSS)"
  git clone --depth 1 "$NGX_REPO" "$WORK/ngx"
fi

if [ ! -d "$WORK/vkh/include/vulkan" ]; then
  echo "== Vulkan-Headers"
  git clone --depth 1 "$VKH_REPO" "$WORK/vkh"
fi

echo "toolchain ready in $WORK"
