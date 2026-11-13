# Patches

`feeder-2.0.0-wine-cpu-sync.patch` applies to
[DLSS5-Feeder](https://github.com/jlrouzies-fr/DLSS5-Feeder) v2.0.0 (commit `9bd0af3`) and
touches three files: `host/dlss5-feed-host64.cpp`, `src/dlss5-feed32.cpp` and `src/feed_ipc.h`.

* **What it does:** under Wine/Proton the 64-bit helper cannot import the 32-bit client's D3D12
  fence. The patch has the client open neither fence and hands each finished frame over on the CPU
  (a named file mapping + event keyed by the game PID; the client waits with an event query, the
  helper with its own fence). Config key `wine_cpu_sync` (default 1 = on under Wine).
* **Origin:** written by GitHub user **pilucdes**, posted in DLSS5-Feeder
  [issue #121](https://github.com/jlrouzies-fr/DLSS5-Feeder/issues/121). Two hunks did not apply
  cleanly to 2.0.0 and were merged by hand; the result built and ran, but it is not an upstream
  release.
* **Licence:** DLSS5-Feeder is MIT licensed; this patch is a modification of that code and is
  distributed under the same MIT terms (copyright of the original code stays with its authors).
  Please credit pilucdes if you reuse it, and prefer an upstream fix if one ships.
* **Apply:** `scripts/build-feeder.sh` does this for you (`git apply`). Both the add-on and the
  helper must be rebuilt together.
