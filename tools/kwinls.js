// Dump the KWin stacking order (bottom to top): index, ACTIVE/FS/MIN flags, window class,
// caption, output, geometry. Run with: kwinrun.sh kwinls.js KWLS
// Useful to check that the DLSS 5 Feed helper window is below the game and never ACTIVE.
const ws = workspace.stackingOrder;
let out = [];
for (let i = 0; i < ws.length; i++) { const w = ws[i];
  if (w.normalWindow || w.fullScreen) out.push(i + " [" + (w.active ? "ACTIVE" : "") + (w.fullScreen ? " FS" : "") + (w.minimized ? " MIN" : "") + "] " + w.resourceClass + " | " + String(w.caption).slice(0,50) + " | " + (w.output ? w.output.name : "?") + " " + Math.round(w.frameGeometry.x) + "," + Math.round(w.frameGeometry.y) + " " + Math.round(w.frameGeometry.width) + "x" + Math.round(w.frameGeometry.height)); }
print("KWLS " + out.join(" ;; "));
