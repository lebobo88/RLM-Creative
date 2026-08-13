---
name: creative-brief-protocol
description: "CreativeBrief envelope contract, intake template, and validation checklist for Calliope and any head receiving strategic intent."
user-invocable: false
argument-hint: "<intake|validate|emit>"
allowed-tools:
  - Read
  - Write
  - Edit
---

# CreativeBrief Protocol

The canonical contract between strategic intent (Hermes / CMO `CSuiteDecisionPacket`) and the Eight Garland Heads crew. Calliope owns this; every other head consumes it.

## Purpose

Ensure every campaign run begins with a fully-populated `CreativeBrief` envelope that matches the Hydra schema. A malformed or under-specified brief MUST NOT enter fan-out.

## When to use

- Calliope receives a raw request, `CSuiteDecisionPacket`, or `HANDOFF` envelope and must shape it into a `CreativeBrief`.
- Any head detects a missing required field on an inbound brief and needs to bounce it back.
- `/creative-campaign` or `/brand-refresh` is initialized.

## Envelope schema (Hydra `hydra_core/schemas.py:CreativeBrief`)

Required fields:

- `type` — literal string `"CreativeBrief"`
- `campaign_id` — stable slug, lowercase-kebab, prefix `cmp-` (e.g. `cmp-acme-q3-launch`)
- `objective` — single sentence stating the measurable outcome (impressions, signups, sentiment delta, etc.)
- `target_audience` — object with `primary` (persona name + 2-3 traits) and optional `secondary`
- `key_messages` — ordered list, 3 to 5 entries, each one full sentence
- `channels` — list drawn from controlled vocabulary: `instagram`, `tiktok`, `youtube`, `x`, `linkedin`, `threads`, `meta-ads`, `google-ads`, `programmatic`, `email`, `pr-earned`, `landing-page`, `ooh`, `broadcast`
- `brand_constraints` — object: `voice`, `tone`, `taboo_topics`, `competitor_mentions_allowed` (bool), `must_include`, `must_avoid`
- `assets_required` — list of `{kind, count, specs}` where `kind` is one of `key-art`, `hero-video`, `product-shot`, `social-cut`, `copy-block`, `press-release`, `landing-section`

Optional but recommended: `budget_usd`, `deadline_iso`, `risk_tolerance` (`low`|`med`|`high`), `prior_campaign_ids`.

## Inputs

- Raw human request, OR
- `CSuiteDecisionPacket` from ExecutiveSuite/Hermes, OR
- Upstream `HANDOFF` envelope from Hydra planner.

## Outputs

- A `CreativeBrief` JSON object MUST be emitted before any fan-out occurs.
- A `gaps.md` note SHOULD be written to `RLM/output/intake/{campaign_id}-{date}.md` when fields were inferred rather than supplied.

## Intake template (Calliope asks the requestor)

If the inbound request is under-specified, Calliope MUST send back these questions before proceeding:

1. What is the single measurable outcome by what date? (objective)
2. Who is the primary audience — name the persona and 2-3 defining traits.
3. What 3 things MUST the audience walk away believing? (key_messages)
4. Which channels are in-scope? Which are explicitly out-of-scope?
5. Voice/tone constraints — any taboo topics, banned phrases, or competitor mentions to avoid?
6. What deliverables and how many — key art, hero video, social cuts, copy blocks?
7. Budget ceiling for paid + production, and risk tolerance for edgy creative?
8. Any prior campaigns we should recall or explicitly diverge from?

## Procedure

1. Read the inbound payload. If it is a `CSuiteDecisionPacket`, map fields: `decision.summary` -> `objective`; `decision.audience` -> `target_audience.primary`; `decision.messaging_pillars` -> `key_messages`; `decision.channels` -> `channels`; `decision.brand_guardrails` -> `brand_constraints`.
2. Recall prior context: `eights.memory.recall(query=objective, domain="creative", scopes=["public","team:garland-crew"], k=8)`.
3. Run the validation checklist (below). For every missing required field, EITHER infer from recall + state the inference explicitly in `gaps.md`, OR bounce back the intake template questions.
4. Assign `campaign_id` (lowercase-kebab, `cmp-` prefix, 12-30 chars).
5. Emit `CreativeBrief` JSON via `rlm.output.write(domain="creative", scopes=["public","team:garland-crew"])`.
6. Notify fan-out targets (Erato, Polyhymnia, Terpsichore, Euterpe, Clio, Urania, Helios) by attaching the brief to the dispatch envelope.

## Validation checklist

- [ ] `campaign_id` matches `^cmp-[a-z0-9-]{8,28}$`
- [ ] `objective` is one sentence, contains a measurable noun (signups, ROAS, reach, sentiment, etc.) and a timeframe
- [ ] `target_audience.primary` has persona name AND 2-3 traits
- [ ] `key_messages` has 3-5 entries, each a complete sentence
- [ ] `channels` is non-empty and every entry is from the controlled vocab
- [ ] `brand_constraints.voice` and `brand_constraints.tone` are populated
- [ ] `assets_required` is non-empty; each entry has `kind`, `count`, `specs`
- [ ] No PII or client-confidential strings appear in `objective` or `key_messages` unless `scopes` includes `sensitive:client-confidential`

## Failure modes / escalation

- **Field missing AND not inferable** — bounce with intake template; do NOT fan out.
- **Schema mismatch on emit** — Hydra planner will reject; log to `RLM/progress/events.jsonl` with `error: schema_violation` and retry once.
- **`risk_tolerance == "low"` AND any `key_message` contains a competitor name** — escalate to HITL via `governance-c2pa`.
- **Conflicting constraints** (e.g. `must_include` overlaps `must_avoid`) — HITL; Calliope MUST NOT auto-resolve.

## References

- Schema: `hydra_core/schemas.py` in the [Hydra repository](https://github.com/lebobo88/Hydra) (`CreativeBrief`)
- Upstream mapping: `integrations/executive-suite.md`
- Memory contract: `integrations/eights.md`
