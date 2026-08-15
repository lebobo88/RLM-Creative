# Phase 05 — CHANNEL PLAN

## Purpose
Translate the `CreativeBrief.channels` list and the narrative spine into per-channel deliverable plans owned by the specialist heads. Output is one consolidated channel-plan artifact and a populated deliverable list that Phase 06 (Production) will execute against.

## Owners (one head per channel family)
- **Owned content**: Polyhymnia (content-strategist) — blog, email, site copy, editorial calendar
- **Social**: Terpsichore (social-community) — per-platform posts, community calendar, UGC seeds
- **Paid**: Euterpe (paid-acquisition) — ad creative briefs, audience targets, ROAS plan, bid posture
- **Earned**: Clio (pr-earned) — angle pitches, press kit, embargo plan, target outlets
- **SEO / Discovery**: Urania (seo-discovery) — topic clusters, query targets, schema/entities, internal links
- **Convener**: Calliope synthesizes; she does NOT author per-channel — she gates consistency

## Mode
Parallel fan-out, time-boxed. Each head produces a section against the same template. Calliope merges.

## Shared inputs (each head receives)
- `CreativeBrief` envelope
- Narrative artifact (`03-narrative-draft` output): central idea, story spine, voice pillars, key-message ladder
- Visual direction summary (`04-visual-direction`): palette, key-art previews
- `eights.memory.recall(domain="creative", query=<head's playbook + brief.industry>, k=6)` filtered per head

## Per-head deliverables (each writes its own subsection)

### Polyhymnia — Owned
- 8-week editorial calendar mapped to the story spine (pillar posts, repurpose ladder)
- Site/landing copy outline (H1, sub, sections, CTA — anchored to key-message ladder)
- Email sequence (welcome / nurture / launch — 3-5 messages with subject + first-line A/B candidates)
- Owned-content deliverable list: `{title, format, length, owner, due_date, channel: "owned"}`

### Terpsichore — Social
- Per-platform plan (only platforms in `brief.channels`): tone calibration against voice pillars
- Cadence (posts/week per platform), best-time hypothesis with rationale
- Post archetypes (3-5 per platform) with caption skeletons + hook patterns
- UGC + community-prompt seeds
- Deliverable list: `{platform, format, copy_variant_count, asset_ref, due_date, channel: "social:<platform>"}`

### Euterpe — Paid
- Channel mix recommendation (Meta / Google / TikTok / LinkedIn / programmatic) with `% of brief.budget.paid_media_usd`
- Audience definitions per channel (interest stacks, lookalikes, exclusion lists)
- Creative variant matrix (hook × visual × CTA — minimum 3×3×2 unless budget < $25k, then 2×2×2)
- ROAS target per channel laddering up to `success_metrics`
- Bid posture, learning-budget carve-out, kill-criteria
- Deliverable list: `{network, placement, format, variant_count, asset_ref, channel: "paid:<network>"}`

### Clio — Earned
- 5-8 angle pitches (each: headline, hook, why-now, journalist persona it fits)
- Target outlet tiers (T1/T2/T3 with named journalists, embargo posture)
- Press kit contents list (release, fact sheet, executive bios, hi-res stills, b-roll spec)
- Spokesperson briefing notes (talking points anchored to key-message ladder)
- Deliverable list: `{asset, owner, due_date, channel: "earned"}`

### Urania — SEO / Discovery
- Primary topic cluster + 3-5 supporting clusters (hub-and-spoke)
- Query map: head terms, mid-tail, long-tail (with intent labels)
- Entity / schema plan (Organization, Product, FAQ, HowTo as relevant)
- Internal linking diagram (text-based)
- Discovery-surface coverage (web SERP, YouTube, Reddit, AI-answer engines)
- Deliverable list: `{url_slug, target_query, word_count, schema_type, channel: "seo"}`

## Consistency gates (Calliope, before exit)
1. Every deliverable across heads references at least one `key_messages` entry. Orphan deliverables are rejected.
2. Every deliverable's voice grades against the 4 voice pillars (Calliope spot-checks 20%).
3. Budget reconciliation: Euterpe's spend == `brief.budget.paid_media_usd` (±5%). If over, return to Euterpe.
4. Coverage check: every `channels` entry in the brief has ≥1 deliverable. Missing channel = STOP.
5. De-duplication: identical asset needs across heads (e.g., a hero still wanted by Terpsichore and Euterpe) collapse to one `AssetJob` with multiple channel targets.

## Output
- `RLM/output/launch/{brief_id}-plan-{date}.md` (the consolidated artifact, one section per head)
- `RLM/output/launch/{brief_id}-deliverables-{date}.md` — the flat deliverable record (input to Phase 06)
- `eights.memory.remember` with `{type:"channel_plan", brief_id, deliverable_count, channel_mix}`

## Handoff
- Phase 06 (Production) reads the deliverables list and fans out copy + `AssetJob` work.
- Emit: `{"phase":"05-channels","status":"complete","deliverable_count":<n>}`.
