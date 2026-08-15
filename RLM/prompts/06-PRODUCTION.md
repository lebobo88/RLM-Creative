# Phase 06 — PRODUCTION

## Purpose
Execute the deliverables list. Generate copy variants, fan out `AssetJob` envelopes from the `ShotList`, dispatch the Helios sub-crew, and assemble first-pass deliverables ready for QC (Phase 07). This is the high-cost phase — every render here burns budget.

## Owners
- **Conductor**: Calliope (monitors budget and consistency, does not author)
- **Copy**: Erato (canonical), with Polyhymnia/Terpsichore/Euterpe/Clio/Urania producing channel variants from Erato's source
- **Asset production**: Helios (gatekeeper for the sub-crew)
- **Sub-crew (Helios dispatches only)**: video-synth, audio-foley, music-score, dialogue-mix, blender-model, blender-rig, governance-c2pa
- **Continuous gate**: governance-c2pa watches every render via `post-render-validate` hook

## Mode
PARALLEL with budget-cap interrupts. Each completed asset publishes to `RLM/output/photo/assets/` and increments a running cost ledger. Helios MUST pause if the ledger exceeds 90% of `brief.budget.production_usd` and either request HITL or trim.

## Track A — Copy production (Erato + channel heads)

### A1. Erato authors canonical copy
For each `key_messages` entry produce:
- **Hero line** (≤8 words)
- **Headline** (≤14 words)
- **Subhead** (≤30 words)
- **Body** (50, 150, 300 word variants)
- **CTA** (3 variants, each a verb phrase)

All grade against the 4 voice pillars. Erato writes via `hydra-creative.gemini-content.*` but is the editor of record — model output is draft, not ship.

### A2. Channel heads adapt
Each head pulls Erato's canonical copy and produces channel-specific variants per their deliverables list. Variant count from Phase 05:
- Terpsichore: caption per post archetype + hook variants
- Euterpe: hook × CTA × audience matrix
- Polyhymnia: site/email longform
- Clio: press release + media alert + pitch emails
- Urania: SEO body copy keyed to query intent

Adaptations MUST preserve the canonical key-message; deviations require Erato sign-off.

## Track B — Asset production (Helios + sub-crew)

### B1. ShotList → AssetJob fan-out
For each `ShotList` row, Helios emits one `AssetJob` envelope:
- `job_id` (`ASJ-{shot_id}`)
- `shot_ref`
- `engine` (one of: `comfyui`, `gemini-image`, `video-synth`, `live-action-placeholder`)
- `workflow_recipe` (from visual direction)
- `prompt` (composed from shot description + palette + lens metadata)
- `negative_prompt` (composed from `brand_constraints.hard_donts`)
- `quality_target` (draft / approval / final — controls passes and cost)
- `dispatch_to` (sub-agent slug)

Helios MUST batch jobs to amortize comfyui workflow loads. Identical workflow recipes run sequentially in one session.

### B2. Sub-crew execution rules
- **video-synth**: receives motion jobs. Selects model (Kling / Veo / Seedance / Wan) per the `comfyui-workflow-recipes` skill. Writes outputs to `RLM/output/photo/assets/video/`.
- **audio-foley**: receives shot list with sound posture from Phase 04. Produces ambience + SFX cue sheet → renders stems.
- **music-score**: composes against the narrative arc (not the shot list). Output: stems + final mix per cut duration.
- **dialogue-mix**: takes any dialogue track, runs QC (clarity, plosives, room tone), routes per channel loudness target (-14 LUFS social, -23 LUFS broadcast).

No sub-agent calls another sub-agent. All inter-track coordination goes through Helios.

### B3. Render quality gates (Helios enforces, before any asset is marked "ready-for-QC")
1. **Brief adherence**: does the render match the shot description's directorial intent? If no, re-prompt up to 2 times then escalate.
2. **Brand-safety preflight**: run `brand-safety` skill checklist against the render (logo treatment, color discipline, hard-dont check).
3. **Technical**: resolution, aspect, color space, codec match the brief's `assets_required` row.
4. **Cost ledger**: append `{shot_id, engine, cost_usd, ts}` to `RLM/output/photo/assets/_ledger.jsonl`.

## Track C — Continuous governance (governance-c2pa, hook-driven)
The `post-render-validate.ps1` hook fires after every asset write. governance-c2pa:
- Scores IP risk (likeness, trademark, style-mimicry)
- Applies the `brand-safety` rubric
- On PASS: pre-signs the asset (full C2PA signature waits for Phase 07 approval)
- On FAIL: writes a disposition record and blocks promotion to Phase 07

## Reasoning gates
- Cost ledger > 90% budget → Helios pauses, surfaces remaining deliverables and asks Calliope to cut.
- Any sub-agent failing twice on the same job → escalate to Helios for prompt rework or engine change.
- governance-c2pa FAIL count > 10% of jobs → STOP production, return to Phase 04 for direction revision.

## Output
- `RLM/output/photo/assets/{type}/{shot_id}.{ext}` — every render (gated by hook)
- `RLM/output/launch/{brief_id}-canonical-{date}.md` (Erato) + `RLM/output/launch/{brief_id}-{channel}-{date}.md` (each head)
- `RLM/output/photo/assets/_ledger.jsonl` — cost ledger
- `eights.memory.remember` per asset: `{type:"render", shot_id, cost_usd, model_type, outcome}`

## Handoff
- Phase 07 (QC + Clearance) consumes everything in `RLM/output/photo/assets/` and `RLM/output/launch/`.
- Emit: `{"phase":"06-production","status":"complete","assets":<n>,"total_cost_usd":<n>}`.


## Production Checklist
- [ ] 3D meshes adhere to polygon budgets (Hero < 50k tris, Background < 10k tris).
- [ ] PBR texture sets packaged as glTF 2.0 / USD.
- [ ] Rig hierarchy verified with no unweighted vertices.
