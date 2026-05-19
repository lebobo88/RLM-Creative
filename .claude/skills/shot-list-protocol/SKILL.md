---
name: shot-list-protocol
description: "ShotList schema authoring, camera and lens grammar, pacing rules per channel. Owned by Helios."
user-invocable: false
argument-hint: "<draft|validate|pace>"
allowed-tools:
  - Read
  - Write
---

# Shot List Protocol

Helios's working document for translating a `CreativeBrief` into a renderable `ShotList`. Every visual asset traces back to a shot entry.

## Purpose

Produce a `ShotList` envelope that satisfies the Hydra schema, follows channel-appropriate pacing, and gives downstream generation tools (comfyui, video-synth, gemini-image) unambiguous direction.

## When to use

- `/photo-direction` is invoked.
- `/creative-campaign` reaches the visual-direction phase and Helios needs to fan out renders.
- An asset fails QC and a re-shot/re-render needs a refreshed entry.

## Envelope schema (Hydra `hydra_core/schemas.py:Shot`)

Each shot:

- `shot_id` — `sh-{seq:03}` within a list (e.g. `sh-001`, `sh-002`)
- `description` — one sentence, action-first, subject-second
- `camera_angle` — one of `wide`, `closeup`, `medium`, `aerial`, `pov`
- `focal_length_mm` — integer; see lens grammar below
- `duration_sec` — float; only for motion shots, omit for stills
- `lighting_notes` — concise: key, fill, rim, practicals, time-of-day, mood ref

The enclosing `ShotList` envelope adds: `type: "ShotList"`, `campaign_id`, `shots: [Shot]`, `target_channel`, `aspect_ratio`, `total_runtime_sec`.

## Inputs

- Active `CreativeBrief` (objective, key_messages, channels, brand_constraints)
- Optional mood references from `eights.memory.recall(tags=["shot-library"])`

## Outputs

- `ShotList` JSON written via `rlm.output.write` to `RLM/output/photo/{campaign_id}-shotlist-{date}.json`
- One or more `AssetJob` envelopes derived from the list, dispatched to comfyui / video-synth / gemini-image

## Camera angle grammar

- **wide** — establishes geography; subject occupies < 25% of frame; use to orient
- **medium** — subject from waist or hip up; conversational; default for product-in-context
- **closeup** — subject from shoulders up, or product macro; emotional or detail beat
- **aerial** — top-down or high-angle drone perspective; scale, scope, pattern
- **pov** — first-person; immersive, used sparingly; pairs with hand-held motion

## Lens / focal-length grammar (full-frame equivalent)

| mm | Use |
|---|---|
| 14-24 | Ultra-wide; environment, architecture, immersive POV; distortion warning |
| 28-35 | Reportage / documentary; wide-medium; lifestyle in context |
| 50 | Normal lens; matches human perspective; honest portraiture |
| 85 | Classic portrait; flattering compression; soft background separation |
| 100-135 | Tight portrait, beauty, product macro |
| 200+ | Telephoto compression; isolated subject, sports, candid |
| Macro (any mm with macro mode) | 1:1 or closer; product details, textures |

Anamorphic: prefix with `anamorphic-` and the squeezed FF-equivalent (e.g. `anamorphic-40`).

## Pacing rules per channel

Total runtime caps and cut cadence:

| Channel | Max runtime | Cut cadence | Aspect | Safe area notes |
|---|---|---|---|---|
| TikTok | <= 30s (sweet spot 9-21s) | every 1.5-3s in first 6s; then 2-4s | 9:16 | Top 15% / bottom 20% UI overlay |
| Instagram Reel | <= 90s (sweet spot 15-45s) | every 2-4s | 9:16 | Caption-safe bottom 18% |
| Instagram Feed video | <= 60s | every 2-5s | 4:5 or 1:1 | |
| YouTube Shorts | <= 60s | every 2-4s | 9:16 | |
| YouTube standard | no hard cap; ad-cut every 7-12s | varies by genre | 16:9 (4K master) | |
| X / Twitter | <= 140s (sweet spot 30s) | 2-4s | 16:9 or 1:1 | Autoplay muted; first frame must read |
| LinkedIn | <= 10 min (sweet spot 30-90s) | 3-6s | 16:9 or 1:1 | |
| Threads | <= 5 min (sweet spot 15-30s) | 2-4s | 9:16 or 1:1 | |
| Broadcast TVC | :15 / :30 / :60 exact | per board | 16:9 | Title-safe 90%, action-safe 93% |
| OOH digital | 6-15s loop | static-feeling | varies | Legibility at distance |

Hook rule: the first shot MUST land the core key_message visually within the first 3 seconds for short-form social, first 2 seconds for TikTok.

Rule of thumb: shots/min = 60 / average_cut_seconds. Hand-edit if narrative beats demand longer holds.

## Procedure

1. Read the `CreativeBrief`. Identify which `key_messages` map to visual beats vs copy beats.
2. Pull mood + reference shots from `eights.memory.recall(tags=["shot-library"], k=12)`.
3. Draft 6-12 shots (longer for broadcast; 4-8 for short-form social).
4. For each shot: pick angle, focal length, duration, lighting; populate `lighting_notes` using `color-science` mood entries.
5. Validate: `shot_id` sequence is contiguous; total `duration_sec` <= channel cap; first 3 seconds carry the hook.
6. Emit `ShotList` envelope; derive an `AssetJob` per shot tagged with the destination workflow recipe (see `comfyui-workflow-recipes`).
7. Hand off to Helios sub-crew for render; await `brand-safety` and `color-science` checks before sign-off.

## Validation checklist

- [ ] Every shot has all six required fields populated
- [ ] `camera_angle` is from the controlled vocabulary
- [ ] `focal_length_mm` is a positive integer
- [ ] `duration_sec` is omitted for stills; present for motion
- [ ] Sum of `duration_sec` <= channel max runtime
- [ ] First-3s hook is identified and labeled
- [ ] `aspect_ratio` matches `target_channel`
- [ ] No two adjacent shots share identical `camera_angle` AND `focal_length_mm` unless intentional (a held beat)

## Failure modes / escalation

- **Total runtime exceeds channel cap** — trim, or split into multi-cut campaign; do NOT emit over-cap.
- **A shot requires a real person's likeness** — route through `brand-safety` IP-clearance before render.
- **Workflow recipe unavailable for an asset kind** — escalate to Helios; consider adding a new recipe (procedural resource, low-risk class).

## References

- Schema: `C:\AiAppDeployments\Hydra\hydra_core\schemas.py` (`Shot`, `ShotList`)
- Mood + grade: `color-science`
- Render: `comfyui-workflow-recipes`
