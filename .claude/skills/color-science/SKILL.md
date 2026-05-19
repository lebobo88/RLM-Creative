---
name: color-science
description: "LUTs, white-balance, mood-driven grading, and color-space deliverable mapping. Helios uses this to brief comfyui and color sub-pipelines."
user-invocable: false
argument-hint: "<grade|lut|deliverable-map>"
allowed-tools:
  - Read
---

# Color Science

The color-grading and color-management reference. Helios uses it to translate a `mood` slot in a `ShotList` into concrete LUT choices, white-balance, and a deliverable color space.

## Purpose

Ensure every render leaves the studio in the correct color space for its destination, carries a consistent mood-driven grade, and survives the round-trip from generation -> grade -> compression -> playback.

## When to use

- Helios is assembling a `ShotList` and needs to populate `lighting_notes` and grade intent per shot.
- A render is about to be exported and the deliverable channel needs a specific color space.
- A campaign spans multiple channels and grade consistency must be enforced across cuts.
- Picking a reference LUT or building a custom grade for a new mood.

## Inputs

- `mood` keyword (from controlled vocab below)
- Source render color space (typically linear or Rec.709 from comfyui)
- Destination channel(s) from `CreativeBrief.channels`

## Outputs

- A grade brief: `{primary_lut, white_balance_k, tint, contrast_curve, saturation, highlight_rolloff, shadow_lift, deliverable_color_space, deliverable_transfer}`
- A delivery profile per channel

## Color-space deliverable mapping

| Channel | Color space | Transfer | Bit depth | Notes |
|---|---|---|---|---|
| Web / social (IG, TikTok, X, LinkedIn, Threads) | Rec.709 | sRGB / gamma 2.2 | 8-bit | Convert from linear; clamp to legal range |
| YouTube SDR | Rec.709 | BT.1886 | 8-bit | Upload h.264 high profile or VP9 |
| YouTube HDR | Rec.2020 | PQ (SMPTE ST 2084) | 10-bit | HDR10 metadata required |
| Streaming HDR (Netflix-style) | Rec.2020 | PQ or HLG | 10-bit min | Per-stream metadata; consult deliverable spec |
| Theatrical / DCP | DCI-P3 | gamma 2.6 | 12-bit XYZ | DCP is XYZ, but grade in P3 |
| Broadcast SDR | Rec.709 | BT.1886 | 10-bit | Legal levels mandatory; QC for chroma subsampling |
| Print / OOH | sRGB or Adobe RGB or CMYK | per print house | varies | Convert with soft-proof; ICC profile must match press |
| Email / web hero stills | sRGB | gamma 2.2 | 8-bit | Strip EXIF; embed sRGB profile |

Rule: never deliver Rec.2020 to a Rec.709 endpoint without an explicit downconvert. Never assume a viewer's screen is calibrated.

## White-balance reference

| Light source | Kelvin | Tint bias |
|---|---|---|
| Candle / tungsten warm | 2000-2700K | +magenta slight |
| Tungsten halogen | 3200K | neutral |
| Fluorescent (varies) | 3500-5000K | +green often |
| Daylight (noon) | 5500-6000K | neutral |
| Overcast | 6500-7500K | +blue |
| Shade / blue hour | 8000-10000K | +cyan |

## Reference grades by mood

- **neon-noir** — WB 3200K, +magenta tint, crushed shadows, neon-saturated highlights (cyan + magenta), low overall saturation outside neon hues, hard contrast S-curve, halation on speculars. LUT family: cyber, blade-runner, miami-vice.
- **golden-hour** — WB 4200K, +amber tint, soft highlight rolloff, lifted shadows, warm saturation skew, mild bloom on sky and skin. LUT family: kodak-2383, fuji-3513, anamorphic-warm.
- **clinical-clean** — WB 5600K daylight neutral, no tint, high mid-tone contrast, full saturation but cool skin tones, zero halation, hard whites at 100 IRE. LUT family: medtech, apple-ad, scandi-minimal.
- **gritty-doc** — WB on-set as captured, slightly desaturated, lifted blacks, grain overlay, no rolloff, natural skin. LUT family: arri-logc-natural, news-rec709.
- **pastel-dream** — WB 5200K, +slight magenta, very low contrast, lifted blacks, lifted whites, heavy desaturation in greens/blues, milk-bath highlights. LUT family: wes-anderson, pastel-portrait.
- **product-luxe** — WB 4800K, neutral tint, deep blacks, controlled speculars, +saturation only in product-hue, vignette. LUT family: hero-product, watch-ad.
- **moody-cinematic** — WB 4000K, teal-orange complementary push, S-curve, controlled highlights, no clipping. LUT family: blockbuster-teal-orange, denis-villeneuve.
- **broadcast-news** — WB 5600K, no creative grade, legal-range only, +slight saturation on flesh. LUT family: rec709-legal.

## How Helios uses this to brief comfyui

In the comfyui workflow brief (see `comfyui-workflow-recipes`), Helios populates:

- `style_prompt` snippets pulled from the mood entry (e.g. for `neon-noir`: "crushed shadows, neon magenta-cyan highlights, halation on speculars, anamorphic flare")
- `negative_prompt` to suppress unwanted shifts (e.g. "oversaturated greens, daylight balance, flat contrast")
- A post-render LUT application node if the workflow includes one (1D for tone, 3D for full grade)
- `output_color_space` matched to the destination channel

## Procedure

1. Read the `ShotList` shot's `mood` (or infer from `CreativeBrief.brand_constraints.tone`).
2. Look up the mood entry above; copy WB, tint, contrast, saturation, LUT family into the grade brief.
3. Determine destination channel(s) from `CreativeBrief.channels`; pick `deliverable_color_space` and `deliverable_transfer` from the mapping.
4. Attach the grade brief to the `AssetJob` payload for the shot.
5. After render, verify: scopes within legal range, no clipping above 100 IRE for broadcast, embedded ICC/transfer matches deliverable spec.
6. Log grade decisions to `eights.memory.remember(domain="creative", scopes=["public"], tags=["color","grade"])` for future recall.

## Failure modes / escalation

- **Mood not in vocab** — propose a new entry; HITL approves before first use; log to procedural resources (low-risk, auto-evolve).
- **Channel needs HDR but source pipeline is SDR** — escalate; HDR requires a different generation/grade pipeline.
- **Mixed-channel campaign with conflicting grades** — produce a master grade in the highest gamut (Rec.2020 / P3) and derive SDR trims; document trims in `RLM/output/photo/`.

## References

- ITU-R BT.709, BT.2020, BT.1886; SMPTE ST 2084; ISO 22028.
- comfyui workflow recipes: `comfyui-workflow-recipes`
