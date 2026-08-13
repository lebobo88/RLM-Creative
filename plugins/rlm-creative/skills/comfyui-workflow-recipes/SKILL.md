---
name: comfyui-workflow-recipes
description: "Curated comfyui workflow recipes Helios fires via the hydra-creative.comfyui.* MCP tool. Each recipe lists input schema, output, when-to-use, and cost."
user-invocable: false
argument-hint: "<list|pick|run>"
allowed-tools:
  - Read
---

# ComfyUI Workflow Recipes

A curated registry of canonical comfyui workflows Helios can dispatch. Each recipe is a stable JSON workflow with a documented input schema, predictable output, and a rough cost estimate.

## Purpose

Keep workflow knowledge in one place so Helios and its sub-crew can pick the correct recipe for an `AssetJob` without re-inventing graphs per shot. Recipes are versioned and live as procedural resources (low-risk class, auto-evolve).

## When to use

- Helios is converting a `Shot` from a `ShotList` into an `AssetJob` and needs to pick a workflow.
- A new visual style requires a workflow that does not exist yet — propose addition.
- A render fails and a different recipe is being evaluated.

## Inputs

- The `Shot` entry (subject, mood, camera angle, lens, lighting notes)
- Destination channel and aspect ratio
- Color-space target (from `color-science`)

## Outputs

- Selected recipe id + filled input schema
- Cost estimate for the render
- Predicted output format (PNG/JPG/MP4/MOV), resolution, color space

## How a recipe is invoked

Via `hydra-creative.comfyui.run` (existing comfyui agent reused; declared as a tool dependency in `squad.yaml`):

```
hydra-creative.comfyui.run(
  recipe_id="key-art-portrait",
  inputs={...recipe input schema...},
  output_dir="RLM/output/photo/{campaign_id}/",
  c2pa_sign=true
)
```

Helios never calls comfyui directly except through this MCP path; the sub-crew is delegated by Helios only. All renders pass through `governance-c2pa` for IP and brand-safety checks before publish.

## Canonical workflows

### 1. key-art-portrait

- **When to use** — single-subject hero stills (talent, founder, customer); editorial portraits; key art for campaigns where a face anchors the frame.
- **Input schema**:
  - `subject_prompt` (string) — describe the subject; do NOT reference a real person's likeness without `brand-safety` clearance.
  - `style_prompt` (string) — populated from `color-science` mood entry.
  - `negative_prompt` (string).
  - `aspect_ratio` ("1:1"|"4:5"|"9:16"|"3:4"|"2:3"|"16:9").
  - `resolution` (int, long edge px; default 2048).
  - `seed` (int|null).
  - `face_fix` (bool, default true).
- **Output** — PNG, sRGB, embedded ICC, C2PA manifest attached.
- **Cost estimate** — ~$0.05-0.15 per image (model-dependent); face-fix pass adds ~30% time.

### 2. product-hero

- **When to use** — product-on-seamless or product-in-context stills for e-com, paid ads, PR kits.
- **Input schema**:
  - `product_reference_image` (path) — required; clean cutout preferred.
  - `scene_prompt` (string) — environment, surface, lighting.
  - `style_prompt` (string).
  - `aspect_ratio`, `resolution`, `seed`.
  - `controlnet` ("canny"|"depth"|"none", default "canny" for shape fidelity).
  - `shadow_pass` (bool, default true) — generate a separate shadow plate for compositing flexibility.
- **Output** — PNG main + optional shadow plate; sRGB.
- **Cost estimate** — ~$0.10-0.25 per shot; controlnet adds ~20%.

### 3. cinematic-keyframe

- **When to use** — narrative-driven still frames intended to be extended into motion via `video-synth` sub-agent; mood boards; pitch decks.
- **Input schema**:
  - `scene_prompt` (string) — composition, subject, action.
  - `style_prompt` (string) — anamorphic, film stock emulation, etc.
  - `camera_angle` (enum from `shot-list-protocol` vocab).
  - `focal_length_mm` (int).
  - `aspect_ratio` (default "2.39:1" cinematic).
  - `resolution` (default 2560 long edge).
  - `seed`.
  - `lut_family` (string|null) — from `color-science` mood entries.
- **Output** — PNG, Rec.709 or P3 (per `lut_family`), C2PA-signed.
- **Cost estimate** — ~$0.10-0.20 per frame.

### 4. style-transfer-loop

- **When to use** — apply a brand-defined style to a batch of stock or existing assets; refresh older creative without re-shoot.
- **Input schema**:
  - `source_images` (list of paths).
  - `style_reference` (path) — brand-style reference image; MUST be brand-owned or licensed (run `brand-safety` first).
  - `strength` (float 0.0-1.0, default 0.6) — higher = more style, less source fidelity.
  - `preserve_subject` (bool, default true).
  - `output_format` ("png"|"jpg").
- **Output** — one transformed image per source; same dimensions.
- **Cost estimate** — ~$0.04-0.08 per image; batches discount via shared model load.

### 5. ip-adapter-character-consistency

- **When to use** — generate multiple shots of the same fictional character (mascot, illustrated talent, internal avatar) with visual consistency across a series.
- **Input schema**:
  - `character_reference_images` (list of 3-8 paths) — MUST be brand-owned IP or licensed; `governance-c2pa` rejects copyrighted-character references.
  - `scene_prompts` (list of strings) — one per output shot.
  - `style_prompt` (string).
  - `aspect_ratio`, `resolution`, `seed_base` (int).
  - `consistency_weight` (float 0.0-1.0, default 0.75).
- **Output** — N images, one per scene_prompt, with consistent character identity.
- **Cost estimate** — ~$0.08-0.18 per output image; reference encoding amortized per batch.

## Picking a recipe

Decision rules:

| Shot kind | Recipe |
|---|---|
| Human portrait, single subject | key-art-portrait |
| Product on white or in context | product-hero |
| Narrative frame, intended for motion | cinematic-keyframe |
| Refresh batch in brand style | style-transfer-loop |
| Repeated character across series | ip-adapter-character-consistency |

If no recipe fits, escalate to Helios; do not improvise an unversioned workflow inside a campaign.

## Procedure

1. Read the `Shot` and identify the shot kind.
2. Pick recipe per decision rules.
3. Fill the recipe input schema. Populate `style_prompt`, `negative_prompt`, `aspect_ratio`, and color-space target from `color-science` and `shot-list-protocol`.
4. Validate references: any `*_reference_image` and any `style_reference` MUST pass `brand-safety` IP-clearance before submission.
5. Estimate cost; if > $200 cumulative for the campaign so far, trigger `media-cost-cap` HITL gate per `squad.yaml`.
6. Dispatch via `hydra-creative.comfyui.run`; await completion.
7. Route output through `governance-c2pa` for C2PA signing and final brand-safety check.
8. Write outputs to `RLM/output/photo/{campaign_id}/`; log episode to memory with `tags=["render","comfyui",recipe_id]`.

## Failure modes / escalation

- **Recipe absent for a shot kind** — propose new recipe; HITL approves; once approved, register as procedural resource (low-risk, auto-evolve).
- **Reference image fails `brand-safety`** — strip and regenerate; if no clean reference available, abandon shot or escalate.
- **Render cost exceeds gate** — pause; HITL via `media-cost-cap`.
- **Output color space drifts from spec** — re-export with explicit color-management node; re-run `color-science` validation.
- **Repeated face artifacts** — re-run with `face_fix` true and different seed; if persistent, switch base model.

## References

- Color-management: `color-science`
- Shot grammar: `shot-list-protocol`
- Governance: `brand-safety`, `governance-c2pa` sub-agent
- Memory tags: `render`, `comfyui`, `recipe-id`
