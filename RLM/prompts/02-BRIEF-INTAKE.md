# Phase 02 — BRIEF INTAKE (CreativeBrief envelope construction)

## Purpose
Convert the discovery notes from Phase 01 into a fully-populated, schema-valid `CreativeBrief` envelope (per `hydra_core/schemas.py`). This envelope is the single source of truth for every downstream head.

## Owners
- **Lead**: Calliope
- **Mode**: AUTOMATED with one user confirmation before emit

## Inputs
- `RLM/output/discovery/{topic}-{date}.md` (from Phase 01)
- Any attached `CSuiteDecisionPacket` from Hermes
- `eights.memory.recall` hits captured in Phase 01

## Field mapping (discovery → CreativeBrief)

| CreativeBrief field        | Source in discovery notes                                    | Validation rule                                          |
|----------------------------|--------------------------------------------------------------|----------------------------------------------------------|
| `brief_id`                 | Generate `BRF-{YYYYMMDD}-{slug}`                             | Unique against `RLM/tasks/`                              |
| `requester`                | Round 1 metadata                                             | Required, non-empty                                      |
| `objective`                | Round 1 Q1                                                   | One sentence, action verb, measurable                    |
| `success_metrics`          | Round 1 Q2                                                   | List of `{metric, target, deadline}` objects             |
| `target_audience`          | Round 2 Q5, Q6                                               | At least 1 persona; reject "everyone"                    |
| `key_messages`             | Derived from Round 2 Q7, Q8                                  | 3-5 items, ranked                                        |
| `tone`                     | Round 2 Q8                                                   | Exactly 3 adjectives                                     |
| `brand_constraints`        | Round 3 Q9-Q11                                               | `{artifacts_url, hard_donts[], legal_posture}`           |
| `risk_tolerance`           | Round 3 Q11                                                  | enum: `low` \| `medium` \| `high`                        |
| `channels`                 | Round 4 Q13                                                  | Non-empty list; each item from controlled vocabulary     |
| `assets_required`          | Round 4 Q14                                                  | List of `{format, dimensions, count, channel}`           |
| `localization`             | Round 4 Q15                                                  | List of locale codes; `["en-US"]` if unspecified         |
| `accessibility`            | Round 4 Q16                                                  | `{wcag_level, captions, audio_descriptions}`             |
| `budget`                   | Round 1 Q4                                                   | `{production_usd, paid_media_usd}`                       |
| `deadline`                 | Round 1 Q3                                                   | ISO-8601                                                 |
| `prior_wisdom_refs`        | Phase 01 recall hits                                         | List of `eights.memory` episode IDs                      |

## Validation gates (Calliope, must all pass before emit)
1. **Schema validity**: Every required field populated. If any is null, return to Phase 01 with a targeted re-ask, not a guess.
2. **Numeric coherence**: `budget.production_usd >= sum(estimated_render_costs)` from constitution. If not, flag `needs_hitl: true`.
3. **Channel coverage**: Every `channels` entry has at least one `assets_required` entry. Reject orphan channels.
4. **Risk gating**: If `risk_tolerance == "low"` and `assets_required` includes any AI-generated likeness, append `gates: ["ip-clearance-hitl"]`.
5. **Localization coherence**: If `len(localization) > 1`, every `key_messages` item must be flagged for transcreation, not literal translation.

## Confirmation step (HUMAN-IN-LOOP, one shot)
Render the envelope as a human-readable summary block. Ask the requester:
> "Below is the brief I will publish. Confirm or edit. Once confirmed, the crew fans out and changes cost time + budget."

Wait for explicit confirmation (or edits + re-render).

## Output
1. Write `RLM/tasks/CAMPAIGN-{brief_id}.md` containing the full envelope as YAML frontmatter + the readable summary.
2. Write the envelope JSON to `RLM/output/briefs/{brief_id}.json` via `rlm.output.write` with `domain="creative"`, `scopes=["team:garland-crew"]` plus `sensitive:client-confidential` if NDA noted.
3. Call `eights.memory.remember(domain="creative", episode={"type":"brief_published","brief_id":..., "actor":"calliope", "summary":...})`.
4. Emit the `CreativeBrief` envelope on Hydra's bus (the squad runtime handles this when the envelope JSON exists at the expected path).

## Handoff
- Phase 03 (Narrative draft) consumes the brief and begins composition.
- Phase 04 (Visual direction) starts in parallel — Helios can read the brief immediately.
- Log: `{"phase":"02-brief","status":"emitted","brief_id":"<id>"}`.
