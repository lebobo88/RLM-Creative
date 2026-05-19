# Phase 01 — DISCOVER CAMPAIGN

## Purpose
Surface enough strategic context from the requester to construct a valid `CreativeBrief` envelope downstream. This phase produces **intake notes** only — no envelope writes yet.

## Owners
- **Lead**: Calliope (brand-strategist, crew gatekeeper)
- **Mode**: SUPERVISED — Calliope MUST wait for human answers before progressing

## Pre-flight (always run)
1. Read `RLM/specs/creative-constitution.md` for non-negotiables (render budgets, brand rules).
2. Call `eights.memory.recall(domain="creative", query=<requester+industry>, scopes=["public","team:garland-crew","assetlib:approved"], k=8)`.
3. Read `RLM/progress/.current-context.md` to detect prior campaign state.
4. If any `CSuiteDecisionPacket` arrived from Hermes/CMO, pre-fill known fields and SKIP the corresponding questions — confirm rather than re-ask.

## Intake Rounds

### Round 1 — Objective and outcome (CRITICAL, must answer)
1. **Objective**: What outcome must this campaign produce? (awareness, acquisition, retention, launch, repositioning, crisis-response)
2. **Success metrics**: Concrete numbers — leads, ROAS target, impressions, sentiment lift, retention curve. If the requester gives vibes only, demand a number with a deadline.
3. **Timing**: Hard launch date, soft launch window, embargo? Any tentpole event tie-in?
4. **Budget envelope**: Total production budget AND paid media budget (separate). Flag if render budget exceeds the constitution's `media-cost-cap` — Helios must HITL.

### Round 2 — Audience and positioning (CRITICAL)
5. **Primary audience**: Demographic + psychographic + jobs-to-be-done. Reject "everyone" — push for 1-2 segments max.
6. **Secondary audience**: If any. Note dilution risk if more than two.
7. **Competitive frame**: Who are we positioning against, or alongside? What is the differentiator in one sentence?
8. **Tone vector**: Three adjectives. (e.g., "irreverent, precise, warm".)

### Round 3 — Brand constraints (HIGH)
9. **Brand artifacts**: Logo lockups, color tokens, type system, voice guide — where do they live? (URL or path)
10. **Hard "do nots"**: Words, imagery, claims, comparisons, regulated terms.
11. **Legal posture**: Any active litigation, NDA scope, regulated industry (pharma, finance, kids)? Set `risk_tolerance` accordingly (`low` triggers HITL gates).
12. **Talent / likeness**: Any named persons, athletes, employees appearing? Cleared usage rights on file?

### Round 4 — Channels and deliverables (HIGH)
13. **Channels in scope**: Owned (site, email, blog), social (which platforms, ranked), paid (which networks), earned (PR targets), SEO. Be exact — "social" alone is not an answer.
14. **Format inventory**: Hero film? 6/15/30s cuts? Stills? Long-form copy? Landing page? Press kit?
15. **Localization**: Languages, markets, region-specific compliance?
16. **Accessibility**: Captions, audio descriptions, WCAG 2.2 AA on landing pages — yes by default unless requester opts out with reason.

## Reasoning gates (Calliope, before exit)
- If any Round 1 or Round 2 answer is missing, STOP and re-ask. Do not proceed.
- If render-cost ceiling × shot count > constitution's `media-cost-cap`, mark `needs_hitl: true` and surface to user.
- If `risk_tolerance == "low"` OR talent likeness involved, append a note that `governance-c2pa` will gate every asset.

## Output
Write `RLM/output/discovery/{topic}-{date}.md` via `rlm.output.write` with `domain="creative"`, `scopes=["team:garland-crew"]`. The file MUST contain:
- Requester, date, campaign codename
- All Q&A verbatim (no paraphrasing of user words)
- Calliope's annotations: open issues, assumption log with confidence, recall hits from `eights.memory.recall`
- Recommended `risk_tolerance` value and rationale
- Pointer to next phase: `02-BRIEF-INTAKE`

## Handoff
Emit a `progress/events.jsonl` line: `{"phase":"01-discover","status":"complete","artifact":"<path>","needs_hitl":<bool>}`. Do NOT emit a `CreativeBrief` yet — that is Phase 02.
