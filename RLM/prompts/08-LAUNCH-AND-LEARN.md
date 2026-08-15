# Phase 08 — LAUNCH AND LEARN

## Purpose
Sequence the launch, wire telemetry to the success metrics defined in the `CreativeBrief`, run the post-launch retrospective, and persist learnings to TheEights so the next campaign starts smarter. This is the closing phase — it MUST run; campaigns that skip it forfeit the crew's compounding advantage.

## Owners
- **Launch conductor**: Calliope (sequencing + go/no-go)
- **Channel operators**: Polyhymnia (owned), Terpsichore (social), Euterpe (paid), Clio (earned), Urania (discovery)
- **Telemetry**: Calliope owns the dashboard contract; each channel head supplies its feed
- **Retrospective facilitator**: Calliope, with explicit dissent invitation to every head
- **Mode**: SUPERVISED launch (human GO/NO-GO), AUTOMATED retrospective synthesis

## Inputs
- `RLM/output/governance/approved-assets/` (only `APPROVED` / `APPROVED-WITH-NOTE` items)
- `RLM/output/governance/{brief_id}-dispositions-{date}.md`
- `RLM/output/launch/{brief_id}-deliverables-{date}.md`
- `CreativeBrief.success_metrics`
- `CreativeBrief.deadline` and any tentpole timing constraints

## Step 1 — Launch readiness check
Calliope confirms:
- Every deliverable in the channel plan has either an APPROVED asset or an explicit deferral
- C2PA signatures present on every motion/still asset
- Tracking parameters (UTMs, click IDs, pixel events) defined per channel
- Spokespeople briefed (Clio confirms)
- Customer-support / community-management coverage scheduled (Terpsichore confirms)
- Rollback plan documented (what we pull and how, if a hard issue surfaces)

If any item is missing, STOP. Do not launch on partial readiness.

## Step 2 — Launch sequence (Calliope orchestrates)
Default ordering (override only with documented reason):
1. **T-72h**: Clio sends embargoed press materials to T1 outlets
2. **T-24h**: Polyhymnia publishes owned site/blog (no-index until T-0 if needed)
3. **T-2h**: Urania confirms search indexing + schema validation
4. **T-0**: Terpsichore launches organic social; Euterpe enables paid campaigns at learning budget
5. **T+24h**: Euterpe reads first signal, adjusts bid posture per kill-criteria
6. **T+72h**: Clio follows up with T2/T3 outlets using early traction proof
7. **T+7d**: First telemetry checkpoint
8. **T+28d**: Retrospective trigger (Step 4)

## Step 3 — Telemetry hookup
Each channel head wires the agreed event stream. Calliope MUST receive a unified dashboard contract: `{metric_name, source, refresh_cadence, owner_head, brief_target, current_value}` keyed to `brief.success_metrics`.

If a metric in the brief has no operational source, that is a failure of Phase 02 and a learning to record — do not paper over it.

Append daily snapshots to `RLM/progress/events.jsonl` with `{phase:"08-launch", metric, value, ts}` so TheEights bridge captures the trajectory as episodic memory.

## Step 4 — Retrospective (the learning phase)
Triggered at T+28d (or the deadline + 7d, whichever is later).

### 4a. Episode summary (Calliope drafts)
A 300-500 word narrative covering:
- What we set out to do (brief.objective, success_metrics)
- What we shipped (counts per disposition, channel mix delivered, budget actual vs plan)
- What happened (metric outcomes vs targets, qualitative signals)
- What surprised us

### 4b. Learnings (every head contributes, in writing)
Each head submits 1-3 learnings as `{claim, evidence, confidence, propagation}`:
- `claim`: the lesson in one sentence
- `evidence`: the metric / artifact that justifies it
- `confidence`: low / medium / high
- `propagation`: which skill or playbook should be updated, if any (low/medium risk-class auto-evolve; high risk-class HITL)

### 4c. Dissenting opinions (REQUIRED FIELD — do not leave empty)
Calliope explicitly polls each head for dissent against the episode summary or the dominant learnings. Even synthetic dissent is logged. The `DecisionRecord.dissenting_opinions` field MUST be populated; "none" is only acceptable if every head was asked and declined in writing.

### 4d. eights.memory.remember (the canonical write)
Call `eights.memory.remember(domain="creative", episode={...})` with:
- `type: "campaign_retrospective"`
- `brief_id`
- `summary` (the 4a narrative)
- `learnings` (the 4b list)
- `dissenting_opinions` (the 4c list)
- `outcomes` (`{metric, target, actual, delta_pct}` per success metric)
- `actors` (the 8 heads + sub-crew involved)
- `scopes` (`["team:garland-crew"]` + `"sensitive:client-confidential"` if NDA)

## Step 5 — DecisionRecord emit
Author the `DecisionRecord` envelope per `hydra_core/schemas.py`:
- `decision_id` (`DEC-{brief_id}-retro`)
- `context` (one paragraph)
- `decision` (what we will do differently next time — concrete, not aspirational)
- `reviewers` (the 8 heads, governance-c2pa)
- `dissenting_opinions` (from 4c)
- `propagation_actions` (skill/playbook updates queued for TheEights RSPL evolution)

Emit on bus and persist at `RLM/output/launch/{brief_id}-retro-{date}.md`.

## Output (the final artifacts)
- `RLM/output/launch/{brief_id}-runbook.md` — launch sequence + tracking contract
- `RLM/output/launch/{brief_id}-retro-{date}.md` — human-readable retrospective and `DecisionRecord` record
- TheEights episode persisted via `eights.memory.remember`
- Skill/playbook update PRs queued for low/medium risk-class auto-evolution

## Reasoning gate (Calliope, before close)
- If `success_metrics` actuals are unknown for > 20% of metrics, the retrospective is INCOMPLETE — schedule a T+60d follow-up rather than closing.
- If dissenting_opinions is empty, the facilitation failed — re-run Step 4c.
- If no learnings were marked `propagation != "none"`, either the campaign was perfect (rare) or the crew is being incurious — surface to HITL.

## Handoff
- Run closes. Calliope notifies Hermes (CMO) with the `DecisionRecord` summary.
- Emit: `{"phase":"08-launch","status":"closed","brief_id":"<id>","decision_id":"<id>"}`.
