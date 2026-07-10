# Cosmic Systems (shared WebView bundle)

Offline Three.js systems sky for **iOS + Android** Cosmic Systems tabs.

## Copy targets

| Platform | Path |
|----------|------|
| Source of truth | `shared/cosmic-systems/` |
| iOS | `AstroSleep-iOS/AstroSleep/Resources/cosmic-systems/` (**add to Xcode target → Copy Bundle Resources**) |
| Android | `AstroSleep-Android/app/src/main/assets/cosmic-systems/` |

## After editing `index.html`

```bash
python tools/sync_shared.py        # push shared/ into both platform copies
python tools/check_parity.py       # verify lockstep (CI runs this on every push)
```

Do not hand-copy; the sync script also prunes stale files and the parity guard
fails CI on any byte of drift. This `README.md` is documentation only and is
intentionally excluded from the copies.

## Vendored dependency

| File | Version | Integrity (sha256) |
|------|---------|--------------------|
| `vendor/three.min.js` | Three.js **r160** | `170c6789f43217c96b3170f4b42fafe135de7f7cd48497a4218f9757ee1d49fa` |

When upgrading Three.js: replace the file here only, update this table, run
the sync + parity pair above, and smoke-test the WebView on both platforms.

## Spec

`documentation/COSMIC_SYSTEMS_3D_TAB.md`
