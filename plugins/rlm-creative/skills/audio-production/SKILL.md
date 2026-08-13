---
name: audio-production
description: "Shared audio production protocol for the Helios sub-crew — foley, score, and dialogue. Spectral allocation, sync, stems, loudness, and mix manifests. Owned by Helios."
user-invocable: false
argument-hint: "<foley-plan|music-plan|dialogue-plan|mix-integration>"
allowed-tools:
  - Read
  - Write
---

# Audio Production

The common working document for Helios's three audio sub-agents — `audio-foley`, `music-score`, and `dialogue-mix`. Each agent owns a discipline, but all three share one timeline, one spectral budget, and one delivery contract. This skill keeps their outputs from colliding and gives every cue an unambiguous home in the mix.

## Purpose

Produce discipline-specific audio plans (`AssetJob` envelopes, cue sheets, stem plans, mix manifests) that occupy the timeline and the frequency spectrum without conflict, stay locked to picture, and meet platform loudness specs. Dialogue intelligibility is the first priority; everything else yields to it.

## When to use

- Helios receives a timecoded `ShotList` and fans render work out to the audio sub-crew.
- `/creative-campaign` or `/photo-direction` reaches the production phase and a sequence needs sound.
- A delivered audio asset fails QC (loudness, sync, intelligibility, or stem completeness) and needs a refreshed plan.

## Discipline split

| Agent | Owns | `model_type` | Primary source | Never does |
|---|---|---|---|---|
| `audio-foley` | SFX, Foley, ambience beds, diegetic sound | `sfx`, `tts` (utility VO only) | timecoded `ShotList` | compose score |
| `music-score` | composition, stems, BPM map, narrative function | `music` | story beats (Calliope) + pacing (Helios) | Foley / dialogue cleanup |
| `dialogue-mix` | VO/ADR/TTS cleanup, intelligibility, channel routing | n/a (processes existing) | prior `AssetJob` audio sources | invent translations / rewrite lines |

## Inputs

- Active `CreativeBrief` (objective, channels, language set, brand_constraints)
- Timecoded `ShotList` (shot boundaries, action beats, transitions) — foley & music
- Story-beat list from Calliope — music only
- Prior `AssetJob` audio sources (raw VO, ADR, TTS) — dialogue only
- Optional cue/motif references from `eights.memory.recall(tags=["audio-library"])`

## Outputs

- `AssetJob` envelopes (`parent_crew: helios`) written via `rlm.output.write` to `RLM/output/{phase}/{topic}-{date}.md`
- Cue sheets (foley), stem plans (music), and mix manifests (dialogue) covering the full timeline
- `DecisionRecord`-compatible notes: why each cue exists, governance flags separated from technical issues

## Spectral allocation rules

The mix is a shared budget. Claim only the space your discipline needs and leave room for the rest.

| Layer | Position | Level intent | Rule |
|---|---|---|---|
| Dialogue | centre (anchored) | reference, protected | Highest priority; nothing may mask it. Off-screen/phone/PA voices get explicit routing intent. |
| Score | L/R + LCR for 5.1 | ~2–3 dB under dialogue | Supports edit rhythm; ducks under dialogue; leaves harmonic space, never fights the voice. |
| SFX / Foley | positioned per pan | sync-locked transients | Tied to visible/implied motion; leaves gaps for dialogue peaks; no constant filler. |
| Ambience | bed, underneath all | continuous or intentional silence | Foundation only; silence is valid when it is deliberate. |

- Reserve spectral space in priority order: dialogue first, then score, then SFX/ambience.
- `music-score` MUST keep cues off dialogue-heavy passages (no overscoring exposition).
- `audio-foley` MUST NOT produce score-like emotional swells; `music-score` MUST NOT fake score with SFX beds.

## Sync & timing integration

- Every cue carries `start_tc`, `end_tc`, and `duration_seconds`; foley cues add a `sync_anchor`.
- The music `bpm_map` MUST align to the `ShotList` cut cadence and transition density; prefer tempo stability within a sequence unless a beat shift demands modulation.
- If Helios issues revised cut timing, `music-score` reflows the BPM map before re-emitting.
- Detected sync offsets are corrected deterministically when possible; otherwise escalate to Helios with the offset noted.
- `dialogue-mix` tracks alternate language versions independently — never assume timing parity across languages.

## Loudness & delivery standards

Conform to **ITU-R BS.1770-4** integrated loudness measurement. Targets unless the `CreativeBrief` overrides per platform:

| Target | Integrated LUFS | True-peak ceiling |
|---|---|---|
| Streaming video (SDR) / YouTube | −14 LUFS | −1 dBTP |
| Streaming / podcast | −16 LUFS | −1 dBTP |
| Broadcast (EBU R128) | −23 LUFS | −1 dBTP |

- Deliver both **stereo** and **5.1** routing plans: dialogue centre; score L/R (LCR + LFE for 5.1); SFX positioned per pan.
- Music stems (minimum where applicable): rhythm, harmony, melody, pads, percussion — each with role, spectral range, dynamic priority, loop/one-shot behavior, and tail handling.
- A clean delivery manifest (file paths, language, channel layout, loudness intent, scene mapping) is part of the deliverable, not an afterthought.

## Procedure

1. Ingest the source envelope; identify timeline boundaries, action beats, transitions, and (dialogue) the required language set.
2. Plan per discipline:
   - **Foley** — build a cue sheet covering the full timeline (no unexplained dead zones); separate Foley / hard FX / texture / ambience; mark perspective per cue.
   - **Music** — build a cue map (entry → development → transition → release); define each cue's dramatic function before tempo/texture; construct the BPM map.
   - **Dialogue** — assess noise floor/clipping/sibilance/drift; score intelligibility before and after planned cleanup; normalize naming to scene/language/speaker/version.
3. Reconcile spectrally against the allocation table; resolve overlaps in dialogue's favor.
4. Emit `AssetJob` envelopes with the correct `model_type`, timecodes, and discipline metadata.
5. Persist cue sheets / stem plans / mix manifests via `rlm.output.write`.
6. On returned renders, QC: coverage, sync, stem completeness, intelligibility, loudness conformance.
7. Return a concise readiness report to Helios with governance flags separated from technical issues.

## Validation checklist

- [ ] Full-timeline coverage; any gap > 3s is intentional silence, not an omission
- [ ] Dialogue intelligibility ≥ 0.85 after cleanup
- [ ] No layer masks dialogue (spectral allocation respected)
- [ ] Music BPM map aligns to cut cadence; hit points land on picture
- [ ] All required stems present or explicitly marked omitted
- [ ] Integrated loudness meets the target for the destination channel
- [ ] Stereo and 5.1 routing plans both present
- [ ] All required language versions present or explicitly waived
- [ ] Governance flags listed separately from technical issues

## Failure modes / escalation

- **Unresolvable sync offset, BPM-vs-cut conflict, or ambiguous shot timing** — escalate to Helios; do not paper over it with added complexity.
- **Dialogue intelligibility below threshold after reasonable cleanup, or a required language version missing** — escalate to Helios; never invent a substitute take or translation.
- **Stem render incomplete or cue/tail boundaries broken** — escalate to Helios.
- **Licensed or externally sourced samples (foley/music), or brand-safety risk words in dialogue** — defer to `governance-c2pa`. Sub-agents MUST NOT trigger human review directly.

## References

- Envelope types: `CreativeBrief`, `ShotList`, `AssetJob`, `DecisionRecord` (`hydra_core/schemas.py` in the [Hydra repository](https://github.com/lebobo88/Hydra))
- Loudness: ITU-R BS.1770-4; EBU R128; AES stem-delivery recommended practices
- Timing & mood: sibling skills `shot-list-protocol`, `color-science`
- Governance: `brand-safety` (IP clearance, brand-guardrail enforcement)
