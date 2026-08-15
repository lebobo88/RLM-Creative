# Phase 07 — QC AND CLEARANCE

## Purpose
Run every produced asset and copy variant through the formal review pipeline: brand-safety, IP-clearance, accessibility, technical-spec, and C2PA signing. Produce a disposition for each item using a controlled vocabulary. This is the last gate before launch.

## Owners
- **Lead**: governance-c2pa (Helios sub-agent with HITL trigger authority)
- **Brand reviewer**: Calliope (final brand-consistency call)
- **Copy reviewer**: Erato (voice + claims)
- **Accessibility**: Polyhymnia (captions, alt text, contrast on owned surfaces)
- **Mode**: AUTOMATED pipeline with HITL interrupts on FAIL or RISK

## Inputs
- All assets under `RLM/output/photo/assets/`
- All copy under `RLM/output/launch/`
- `CreativeBrief` (for `risk_tolerance`, `brand_constraints`, `accessibility`)
- Skills: `brand-safety`, `creative-brief-protocol`

## The four checks (run for every item, in order, fail-fast)

### Check 1 — Brand-safety (governance-c2pa primary, Calliope confirms on borderline)
Apply the `brand-safety` skill rubric. Categories:
- Logo and lockup discipline (clear space, color, no distortion)
- Color discipline against the approved palette
- Hard-dont check against `brand_constraints.hard_donts`
- Voice grade against the 4 voice pillars (copy only)
- Tonal alignment with `brief.tone` adjectives

Scoring: each category PASS / WARN / FAIL. Any FAIL or two WARNs ⇒ item FAILS Check 1.

### Check 2 — IP / Clearance (governance-c2pa)
- **Likeness**: any human face? cleared release on file? AI-generated likeness flagged.
- **Trademark**: any third-party marks visible? cleared usage?
- **Style mimicry**: render style mimics a living artist or copyrighted IP? score.
- **Music / SFX**: licensed? royalty-free with attribution captured?
- **Talent**: voice clones, performance captures — release on file?
- **Claims**: regulated language (medical, financial, environmental) sourced and substantiated?

If `risk_tolerance == "low"`, ANY non-PASS in this check triggers HITL.
If `risk_tolerance == "medium"`, only FAILs trigger HITL.
If `risk_tolerance == "high"`, FAILs auto-reject without HITL.

### Check 3 — Accessibility (Polyhymnia, on owned + earned surfaces)
- Captions present + accurate for all video
- Audio description track for video with critical visual-only info
- Alt text for every still placed on owned web surfaces
- Contrast ratios meet `brief.accessibility.wcag_level` (default AA)
- No flashing > 3Hz, no auto-play audio

### Check 4 — Technical spec (governance-c2pa)
- Resolution, aspect ratio, codec, color space match the `assets_required` row
- Loudness targets met (-14 LUFS social, -23 LUFS broadcast, -16 LUFS podcast)
- File-size limits per channel
- Embedded metadata: campaign tag, brief_id, version

## Disposition vocabulary (controlled — use exactly these)
- `APPROVED` — all four checks PASS, C2PA signed, eligible for launch
- `APPROVED-WITH-NOTE` — passes but carries a non-blocking annotation (logged, not gated)
- `REVISE` — minor fix in scope, returns to the producing head with a punch list
- `RE-RENDER` — Helios sub-crew rework required; budget hit logged
- `LEGAL-HOLD` — IP/clearance issue; goes to HITL queue, NOT auto-resumable
- `BRAND-HOLD` — brand-safety FAIL; Calliope must adjudicate
- `REJECTED` — kill the asset, do not ship; reason logged for memory
- `DEFERRED` — out of scope for this campaign, archived for future reuse

## HITL triggers (these MUST surface to a human approver)
1. Any `LEGAL-HOLD`
2. Any `BRAND-HOLD` after one round of Calliope revision
3. `REJECTED` count > 15% of total assets (signals upstream-direction problem)
4. Budget breach for cumulative `RE-RENDER` requests
5. `risk_tolerance == "low"` + any non-PASS in Check 2

When a HITL is triggered, the run pauses at `approval_gate` and surfaces in `/hydra:approve`.

## C2PA signing (governance-c2pa, final action)
For every `APPROVED` or `APPROVED-WITH-NOTE` item:
1. Compose the C2PA manifest: `{producer, brief_id, shot_id, engine, prompts (hashed), reviewers, timestamp}`
2. Sign with the production key (frozen procedural resource — never auto-rotated)
3. Embed signature into the asset and write a sidecar `.c2pa.json`
4. Move asset to `RLM/output/governance/approved-assets/` (write gated by `pre-asset-write.ps1`)

## Output
- `RLM/output/governance/{brief_id}-dispositions-{date}.md` — disposition record with full detail
- `RLM/output/governance/{brief_id}-summary-{date}.md` — human-readable summary (counts per disposition, HITL queue, budget delta)
- `eights.memory.remember` for every `LEGAL-HOLD`, `BRAND-HOLD`, `REJECTED` with rationale (tagged `governance`)
- `DecisionRecord` envelope populated with reviewers, dispositions, dissent if any

## Handoff
- Phase 08 (Launch + Learn) consumes only `APPROVED` and `APPROVED-WITH-NOTE` items.
- Emit: `{"phase":"07-qc","status":"complete","approved":<n>,"hitl_open":<n>}`.
