# host64/OptiScaler.ini: only the keys that were changed

Start from the `OptiScaler.ini` shipped in the OptiScaler DLSS-NR fork v0.8.93 archive and
change these keys (section in brackets). The list below is the complete diff against that file's defaults as shipped; the write-up does not say which of them are strictly required.

| Section | Key | Value |
|---|---|---|
| `[Upscalers]` | `Dx12Upscaler` | `dlss` |
| `[Inputs]` | `EnableXeSSInputs` | `false` |
| `[Inputs]` | `EnableFsr2Inputs` | `false` |
| `[Inputs]` | `EnableFsr3Inputs` | `false` |
| `[Inputs]` | `EnableFfxInputs` | `false` |
| `[Spoofing]` | `StreamlineSpoofing` | `false` |
| `[Spoofing]` | `Dxgi` | `false` |
| `[Log]` | `LogToFile` | `true` |
| `[Log]` | `LogLevel` | `2` |
| `[Hotfix]` | `CheckForUpdate` | `false` |
| `[DlssNr]` | `Enabled` | `true` |

Optional, to see what the neural model changes: set `[DlssNr] DebugView=3` and restart the game
(`auto` is the default). Not described further here because that value's meaning was taken from
the write-up, not re-derived.

```
python3 scripts/patchini.py "$GAME/System/host64/OptiScaler.ini" \
  Upscalers.Dx12Upscaler=dlss Inputs.EnableXeSSInputs=false Inputs.EnableFsr2Inputs=false \
  Inputs.EnableFsr3Inputs=false Inputs.EnableFfxInputs=false Spoofing.StreamlineSpoofing=false \
  Spoofing.Dxgi=false Log.LogToFile=true Log.LogLevel=2 Hotfix.CheckForUpdate=false DlssNr.Enabled=true
```

## Realism tuning (optional, see docs/realism-tuning.md)

| Section | Key | Value |
|---|---|---|
| `[DlssNr]` | `Passes` | `2` |
| `[DlssNr]` | `Style` | `1` |
| `[DlssNr]` | `Intensity` | `1.75` |
| `[DlssNr]` | `LocalStructure` | `1.75` |
| `[DlssNr]` | `LocalTone` | `1.0` |
| `[DlssNr]` | `Pass2LocalTone` | `1.0` |
| `[DlssNr]` | `TransferStrength` | `1.5` |
| `[DlssNr]` | `MaxRatio` | `3.0` |
