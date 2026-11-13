# Notice

This repository contains only documentation, scripts, configuration snippets and one source
patch. It deliberately includes **no binaries** and **none of the following**:

* **NVIDIA** files (`nvngx_dlss.dll`, `nvngx_dlssnr.dll`, NGX SDK headers/libraries): these are
  NVIDIA's proprietary, separately licensed software. You must obtain them yourself and comply
  with their terms. The scripts only fetch the public NVIDIA/DLSS SDK repository for headers and
  an import library at build time, on your machine, under that repository's licence.
* **dgVoodoo2**, **ReShade**, **OptiScaler** (DLSS-NR fork), the **dgvoodoo-wine-fix** patcher:
  third-party projects with their own licences; download them from their own pages. Only short
  lists of the setting names/values changed in their config files are given here.
* **Splinter Cell: Chaos Theory** files, or Microsoft's Windows SDK/CRT (xwin downloads those
  directly from Microsoft on your machine when you accept their licence).
* **DLSS5-Feeder** source: only a patch against it is included
  (`patches/feeder-2.0.0-wine-cpu-sync.patch`). DLSS5-Feeder is MIT licensed, the patch's original
  author is GitHub user pilucdes (Feeder issue #121). The patch is distributed under the same
  MIT terms; see `patches/README.md`.

The MIT `LICENSE` in the repository root covers only this repository's own scripts and
documentation. Nothing here is affiliated with or endorsed by NVIDIA, Microsoft, Ubisoft, or the
authors of the tools above. Use at your own risk; modifying a game's files can affect online
features and your support eligibility.
