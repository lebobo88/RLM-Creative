# Creative Constitution

**Owner:** RLM Creative Operations  
**Applies to:** All agents, sub-agents, and automated pipelines in `C:\AiAppDeployments\RLM-Creative\`  
**Status:** Active  
**Last updated:** 2026-05-19

This document establishes mandatory rules for creative output. RFC-2119 normative language applies throughout: MUST, MUST NOT, SHOULD, MAY.

---

## Brand Non-Negotiables

### Clarity

- Every deliverable MUST have a single, unambiguous primary message. Multiple competing claims in one asset are prohibited.
- Body copy MUST be legible at its intended delivery size. Minimum body font size is 14px for digital; 8pt for print.
- CTAs MUST be action verbs. Passive constructions ("Click here to learn more") MUST be replaced with direct forms ("Get the guide", "Start free trial").

### Consistency

- Brand name, product names, and trademark symbols MUST be applied as specified in the active `CreativeBrief.brand_constraints`. Agents MUST NOT invent abbreviations or variant capitalizations.
- Color palette MUST conform to the client's brand system. Agents MUST NOT introduce off-palette colors without Calliope approval recorded in a `DecisionRecord`.
- Typography hierarchy MUST follow the brand system on file. Deviations require Calliope sign-off.

### IP Cleanliness

- No asset MAY incorporate third-party copyrighted material (images, audio, video, text, code) without documented clearance in the active `CreativeBrief` or a separate clearance record.
- All stock assets MUST have license records attached before delivery. `governance-c2pa` MUST validate before C2PA signing.
- Likenesses of real individuals MUST NOT be generated or used without documented consent. This restriction is absolute and cannot be overridden by any agent or HITL approval alone; legal sign-off is required.
- AI-generated assets submitted for commercial use MUST be C2PA-signed by `governance-c2pa` before being written to `assetlib:approved`.

---

## Render Budgets

- The maximum render cost for a single `AssetJob` without HITL approval is **$200 USD**.
- The maximum render cost for a proof-of-concept or exploratory render (not a deliverable) is **$50 USD**. If a PoC render is expected to exceed $50, the agent MUST request a budget increase via Calliope before submitting the `AssetJob`.
- Helios MUST include a `max_render_cost_usd` estimate in every `AssetJob` envelope before dispatch.
- Render costs MUST be logged as episodes in TheEights memory after each job completes, regardless of pass/fail outcome.
- Cumulative per-campaign render spend SHOULD be tracked in `RLM/progress/.current-context.md`. Calliope SHOULD surface the running total in campaign status updates.

---

## Asset Formats

Deliverables MUST conform to the following format specifications unless the `CreativeBrief` explicitly overrides for a specific platform.

### Video

- Container: MP4
- Codec: H.264 (broad compatibility) or H.265/HEVC (4K and HDR deliverables)
- Frame rate: match the brief's specified frame rate; default 23.976 fps for narrative, 29.97 fps for broadcast
- Resolution: minimum 1080p for all deliverables; 4K for scope-tagged `render:4k` jobs
- Color: Rec.709 for SDR; Rec.2020/PQ for HDR (tagged `render:hdr`)

### Audio

- Format: WAV, 48 kHz sample rate, 24-bit depth
- Channels: stereo for digital delivery; 5.1 surround for broadcast / cinema (tagged `audio:5.1`)
- Loudness: -14 LUFS integrated for streaming; -23 LUFS for broadcast (EBU R128)
- Dialogue, music, and effects MUST be delivered as separate stems in addition to the final mix

### Stills

- Format: PNG (lossless, transparency-supporting) or JPEG (delivery-optimized, no transparency)
- Minimum resolution: brief-specified; default 2400px on the longest edge for print-safe delivery
- Color profile: sRGB for digital; Adobe RGB or CMYK conversion required for offset print
- Metadata: EXIF and IPTC fields MUST be populated (title, creator, copyright, usage rights) before delivery

---

## Quality Gates

All deliverables MUST pass the following gates before `governance-c2pa` signs and the asset is written to `assetlib:approved`. Gate failures are logged and trigger HITL where specified.

### Brand-Consistency Rubric

`governance-c2pa` runs the brand-consistency rubric on every asset. The rubric checks:

- Brand name and trademark usage
- Color palette adherence
- Typography hierarchy
- CTA language
- Primary-message clarity

Assets failing brand-consistency MUST be returned to the originating head for revision. They MUST NOT be delivered to the client in a failed state.

### IP Clearance

`governance-c2pa` validates IP clearance for every asset before C2PA signing. Clearance checks:

- Stock asset license records present and valid
- AI model training data disclosure (where required by applicable law)
- Likeness release records (for assets depicting individuals)
- Music sync and master-use clearance (for audio assets)

IP clearance failures trigger HITL regardless of `risk_tolerance` setting. This gate cannot be configured off.

### C2PA Signing

Every asset approved for client delivery or written to `assetlib:approved` MUST be C2PA-signed by `governance-c2pa`. The signature MUST include:

- `claim.assertions.creative_work` with author and creation date
- `claim.assertions.ai_generated` if any AI model contributed to the asset
- `claim.assertions.rights` with license terms

Assets MUST NOT be distributed or published before C2PA signing is confirmed.

### WCAG 2.2 AA

Any asset that will be embedded in a web page or interactive experience (landing pages, email, social carousels) MUST pass WCAG 2.2 AA checks:

- Color contrast ratio >= 4.5:1 for normal text, >= 3:1 for large text
- All images have descriptive alt text
- Video assets have captions or a transcript

---

## Voice Rules

Platform-specific voice and tone rules are defined in `.claude/skills/platform-voice/SKILL.md`. Erato and Terpsichore are the primary consumers.

The general hierarchy for voice decisions:

1. Client brand guidelines (in `CreativeBrief.brand_constraints`) take precedence over all defaults.
2. Platform-voice skill rules apply where the brief does not specify.
3. Calliope arbitrates conflicts between client guidelines and platform-voice recommendations. The resolution MUST be recorded in the `DecisionRecord.dissenting_opinions` field if any head disagrees.

Tone MUST be derived from the `platform-voice` skill for each channel in the campaign plan. Generic or unattributed tone descriptors ("professional", "friendly") MUST NOT be used as the final tone specification in a deliverable brief; they MUST be expanded to concrete, platform-specific language by Erato or Terpsichore before copy is produced.
