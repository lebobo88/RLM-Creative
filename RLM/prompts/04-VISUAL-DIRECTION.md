# Phase 04 — VISUAL DIRECTION

## Purpose
Convert the narrative spine into a coherent visual world: mood, color, light, shot pacing, key-art briefs, and a concrete `ShotList` envelope plus the ComfyUI workflow recipes Helios will fire in production.

## Owners
- **Lead**: Helios (photo-cinema, sub-crew gatekeeper)
- **Advisory**: Calliope (gates brand-consistency), Erato (titling/typography intent only)
- **Mode**: AUTOMATED with one approval gate before ShotList emit

## Inputs
- `RLM/output/brief/{brief_id}-narrative-{date}.md`
- `CreativeBrief` (for `assets_required`, `brand_constraints`, `risk_tolerance`)
- Skills: `shot-list-protocol`, `color-science`, `comfyui-workflow-recipes`, `brand-safety`
- `eights.memory.recall(domain="creative", query="visual_world " + brief.industry + " " + tone_adjectives, scopes=["assetlib:approved","render:4k","render:hdr"], k=12)` — return prior frame thumbnails + lens metadata

## Step 1 — Mood Board (Helios)
Produce a written mood board with 6-10 references. Each reference entry:
- `source` (film title, photographer, gallery URL, prior approved asset ID)
- `why_it_fits` (tie to a specific story-spine beat or voice pillar)
- `what_to_steal` (lens choice, light direction, color cast, blocking — be specific, not "the vibe")
- `what_to_avoid` (cliché trap from this reference)

Reject references that violate `brand_constraints.hard_donts`. Reject any reference Helios cannot articulate the craft reason for in one sentence.

## Step 2 — Color Direction
Apply `color-science` skill. Output:
- **Primary palette**: 5 hex values mapped to `{role, when_used}`
- **Light direction**: key/fill/rim recipe, time-of-day target, color temperature (K)
- **LUT or grade reference**: name the LUT or describe the grade in 3 lines (lift/gamma/gain)
- **Contrast posture**: low/medium/high + the emotional reason

## Step 3 — Shot Pacing
For each `assets_required` entry that is motion (film, social cut, ad), specify:
- Target runtime
- Cut frequency target (e.g., 1.2s avg in first 5s for attention-honest opens)
- Hero shot count (how many "stop-scroll" frames must exist)
- Sound posture (dialogue-led / music-led / sound-design-led) — passes to `music-score` and `audio-foley`

## Step 4 — Key-Art Briefs
For each still asset in `assets_required`: produce a one-page brief with subject, composition, lens, light, palette pull, copy-safe region (top/bottom/center), aspect-ratio matrix.

## Step 5 — ShotList draft (the envelope)
Author a `ShotList` envelope per `hydra_core/schemas.py`. Each shot row:
- `shot_id` (`SHT-{brief_id}-{nn}`)
- `beat_ref` (which story-spine beat this serves)
- `description` (1-2 sentences, directorial not literal)
- `lens_mm`, `aperture`, `camera_move`, `duration_s`
- `light` (key, fill, rim, practicals)
- `palette_ref` (which palette role dominates)
- `talent_required` (yes/no + likeness clearance flag)
- `workflow_recipe` (name from `comfyui-workflow-recipes` skill, OR "live-action" / "gemini-image" / "hybrid")
- `estimated_cost_usd` (cap-check against constitution)
- `risk_flags` (IP, likeness, regulated claim depicted)

## Step 6 — ComfyUI workflow selection
For every shot with `workflow_recipe != "live-action"`, name the exact recipe file Helios will pass to `hydra-creative.comfyui.*`. If no recipe fits, Helios MUST either: (a) request a new recipe authored under `plugins/rlm-creative/skills/comfyui-workflow-recipes/`, or (b) downgrade to `gemini-image` with a written quality trade-off note. Inventing workflows ad-hoc is forbidden.

## Reasoning gates
- Sum of `estimated_cost_usd` ≤ `brief.budget.production_usd`. If not, Helios MUST cut shots OR mark `needs_hitl: true` with a proposed trim list.
- Every `risk_flag` triggers a downstream `governance-c2pa` review — note it explicitly.
- Calliope sign-off required on `Step 1` and `Step 5` (brand-consistency check). If Calliope rejects, iterate ONCE then escalate to HITL.

## Output
1. `RLM/output/brief/{brief_id}-direction-{date}.md` — mood, color, pacing, key-art briefs
2. `RLM/output/brief/{brief_id}-shotlist-{date}.md` — the `ShotList` record (also emitted on bus)
3. `eights.memory.remember` with `{type:"visual_direction", brief_id, palette, shot_count, total_cost}`

## Handoff
- Phase 06 (Production) consumes the ShotList and fans out `AssetJob`s to the Helios sub-crew.
- Channel-plan phase (05) runs in parallel — it does not block on visual.
- Emit: `{"phase":"04-visual","status":"complete","shotlist_id":"<id>","cost_estimate_usd":<n>}`.


## Visual Directives
### 3D Asset Creation Contract
- Helios delegates 3D mesh modeling to `blender-model` (retopo, UV/PBR, LOD, FBX/glTF/USD export).
- Helios delegates rigging and armature build to `blender-rig` (skinning, FK/IK, mocap retarget, NLA).
- All 3D assets (`.glb`, `.gltf`, `.fbx`, `.usd`, `.blend`) MUST pass `governance-c2pa` verification before commit.
