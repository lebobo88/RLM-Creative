# Hydra Integration - RLM-Creative Eight Garland Heads

How Hydra routes a `CreativeBrief` into the Eight Garland Heads squad and manages the full creative workflow lifecycle.

## squad.yaml location

Canonical source: `squad.yaml` at this repository's root.

Hydra reads this via the `source_pack` field in its own copy at `squads/creative/squad.yaml` in the [Hydra repository](https://github.com/lebobo88/Hydra).

The Hydra copy MUST be kept in sync with (or symlinked to) the RLM-Creative canonical. RLM-Creative owns the contract; Hydra is a consumer.

## CreativeBrief envelope contract

Schema lives in `hydra_core/schemas.py:CreativeBrief` in the [Hydra repository](https://github.com/lebobo88/Hydra). Do not modify it - the shape is frozen for cross-squad compatibility.

```python
class CreativeBrief(HydraEnvelope):
    type: Literal["CREATIVE_BRIEF"] = "CREATIVE_BRIEF"
    campaign_id: UUID
    objective: str
    target_audience: str
    key_messages: list[str]
    channels: list[str]
    brand_constraints: list[str]
    assets_required: list[str]
```

Inherited from `HydraEnvelope`:

| Field | Purpose |
|---|---|
| `id` | Unique envelope UUID |
| `workflow_id` | Links to the originating Hydra workflow |
| `origin_squad` | `"executive"` when from CMO; `"creative"` for internal |
| `target_squad` | `"creative"` |
| `constraints.risk_tolerance` | Drives HITL gate activation (`low` = always HITL) |
| `constraints.budget_usd` | Caps render cost; triggers `media-cost-cap` gate at > $200 |
| `context_refs` | `MemoryRef` handles injected by Calliope from `eights.memory.recall` |

## /hydra:run routing

The router scores squads against the goal text using keyword fingerprints in `hydra_core/router.py:_KEYWORDS["creative"]`. The creative squad activates on any of:

```
campaign, brand, creative, copy, visual, social, content, media,
calliope, erato, polyhymnia, terpsichore, euterpe, clio, urania, helios,
garland, muse, muses, creative crew
```

Three or more keyword hits clears the `min_confidence=0.25` threshold. The `industries:` block in `squad.yaml` provides an independent boost when the workflow is pre-tagged.

```
/hydra:run "Draft a Q3 awareness campaign for Acme Bikes targeting urban commuters"
```

Hydra constructs a `CreativeBrief` and dispatches to the `creative` squad. The `entrypoint: claude-skill` adapter issues `/creative-campaign <brief-json>`. Calliope receives the envelope as the gatekeeper agent.

## HITL gates and /hydra:approve

When a gate fires with `hitl_required: true`, the supervisor sets `state.requires_human_approval = True` and halts.

| Gate | Trigger condition |
|---|---|
| `ip-clearance` | `risk_tolerance == 'low'` OR governance-c2pa flags IP risk |
| `media-cost-cap` | Cumulative render cost > $200 |
| `brand-consistency` | DecisionRecord contains unresolved dissent from Calliope |
| `brand-safety` | governance-c2pa flags brand-safety violation |

Resume:

```
/hydra:approve <workflow_id>
```

Hydra reads `state.pending_hitl` options and re-enters the squad at the interrupted node. Approval trace is written to `<project>/.hydra/<workflow_id>/trace.jsonl`.

## MCP shim - rlm_creative/server.py

Path: `mcp_servers/rlm_creative/server.py` in the [Hydra repository](https://github.com/lebobo88/Hydra)

| Tool | Signature | Description |
|---|---|---|
| `rlm.skill.list` | `() -> {skills:[...]}` | Lists skill directory names under `.claude/skills/` |
| `rlm.skill.get` | `(name) -> {content}` | Returns `SKILL.md` content for the named skill |
| `rlm.command.list` | `() -> {commands:[...]}` | Lists `rlm-*` and creative commands |
| `rlm.command.get` | `(name) -> {content}` | Returns command markdown |
| `rlm.agent.list` | `() -> {agents:[...]}` | Lists agent `.md` files from `.claude/agents/` |
| `rlm.agent.get` | `(slug) -> {content}` | Returns agent markdown by slug |
| `rlm.output.write` | `(phase, topic, content)` | Writes to `RLM/output/{phase}/{topic}-{date}.md` |
| `rlm.output.read` | `(path) -> {content}` | Reads a previously written output file |
| `rlm.ping` | `() -> {ok, root, exists}` | Health check; called by `hydra doctor` |

Root resolved via `HYDRA_RLM_ROOT` env var. For RLM-Creative, set:

```json
"rlm-creative": {
  "command": "python",
  "args": ["-m", "mcp_servers.rlm_creative"],
  "cwd": "${CLAUDE_PLUGIN_ROOT}",
  "env": { "HYDRA_RLM_ROOT": "<path-to-your-RLM-Creative-clone>" }
}
```

## Wiring checklist for activation

Mirrored from `CONTRIBUTING-SQUADS.md` §h. Check all boxes before flipping `entrypoint:` away from `stub`:

- [ ] `squad.yaml` parses cleanly: `python -m hydra_core.cli doctor` - no warnings.
- [ ] Gatekeepers exist for every gate with `hitl_required: true` (Calliope, governance-c2pa).
- [ ] Every `tools:` entry resolves: `rlm-creative`, `comfyui`, `gemini-image`, `gemini-content`, `frontend-design`, `eights-memory` MCP servers reachable.
- [ ] `accepts: [CREATIVE_BRIEF, SHOT_LIST, ASSET_JOB, HANDOFF]` - all schemas exist in `hydra_core/schemas.py`.
- [ ] `emits: [SHOT_LIST, ASSET_JOB, DECISION_RECORD]` - all schemas exist.
- [ ] Rubric ids `brand-consistency`, `ip-clearance`, `media-cost-cap`, `brand-safety` map to rubric yamls under `squads/creative/rubrics/` or `hydra_core/rubrics/`.
- [ ] Router keywords added to `hydra_core/router.py:_KEYWORDS["creative"]`.
- [ ] Adapter emits `telemetry.emit(...)` at `node_start`, `tool_call`, `node_end`.
- [ ] Adapter calls `governance.record_cost(state, usd, tokens)` after every model call.
- [ ] Adapter wraps outbound text in `governance.redact_for_squad_boundary(...)`.
- [ ] Results persisted via `memory.append_episodic(...)`; only `MemoryRef` handles cross squad boundaries.
- [ ] `HYDRA_RLM_ROOT` in `.mcp.json` points at the RLM-Creative repository root.
- [ ] Smoke run: `python -m hydra_core.cli run "Draft a campaign" --squad creative` produces a `DECISION_RECORD`.
- [ ] `/hydra:replay <workflow_id>` reconstructs end-to-end.
- [ ] `pre-asset-write.ps1` and `post-render-validate.ps1` registered in `.claude/settings.json` or `hooks.json`.
