# TagEngine v4 → iOS port plan

Android ships **TagEngine v4** with:

- `PersonalSoundProfile` (stable fingerprint from natal + user id)
- Affinity tables + combo stacking via `ComboComposer`
- Score breakdowns on `RankedSound`

iOS currently remains on **v3** (`TagEngine.swift`) for chart/night scoring without the personalization fingerprint path.

## Port checklist

1. Port `PersonalSoundProfile` hashing (match Android bit layout for cross-device parity tests).
2. Port affinity / vector tables (`TagAffinityTables`, `TagVectorTables`).
3. Introduce `ComboComposer` equivalent; keep free tier 2-layer cap.
4. Golden tests: same userId + natal fixtures → same fingerprint + top-N sound ids.
5. Wire `AppState.autoGenerateCombo` through composer; keep offline cache path.

## UX note

Fingerprint may appear as truncated hex in Tonight “layers · fp …” (Android). iOS can show the same once ported — quiet, mono, not gamified.
