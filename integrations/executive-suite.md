# ExecutiveSuite Integration - Hermes CMO to CreativeBrief Bridge

How a strategic marketing decision made inside ExecutiveSuite flows into the Eight Garland Heads crew as a `CreativeBrief` envelope. RLM-Creative is a **consumer-only** participant - no ExecutiveSuite code changes are required.

## CMO agent location

```
C:\AiAppDeployments\ExecutiveSuite\.claude\agents\cmo.md
```

The CMO agent is named `cmo` and operates under the `executive-protocol` skill. Output dir is `output/marketing/`. Referred to as **Hermes** in architectural diagrams; the file slug remains `cmo`.

## Trigger events

Creative work is initiated when ExecutiveSuite produces output from either of these commands:

| Command | When it triggers creative work |
|---|---|
| `/exec-brief` | CMO decision contains `domain: marketing` or non-empty `assets_required` |
| `/board-meeting` | Board resolution assigns a marketing objective to the CMO; CMO emits a follow-on `CSuiteDecisionPacket` |

Hydra's planner detects the packet, checks `proposed_tasks[*].target_squad == "creative"` or derives it from the `domain` field, and converts the packet to a `CreativeBrief`.

## CSuiteDecisionPacket to CreativeBrief field mapping

| CSuiteDecisionPacket field | CreativeBrief field | Transformation |
|---|---|---|
| `objective` | `objective` | Pass through verbatim |
| `proposed_tasks[0].description` | `objective` (fallback) | Used when top-level `objective` is generic |
| `notes` | `key_messages` | Split on newlines; non-empty lines |
| `proposed_tasks[*].description` | `channels` | Tasks whose description starts with a channel keyword |
| `constraints.industries` | `brand_constraints` | Each industry tag maps to brand guardrails via `brand-safety` lookup |
| `proposed_tasks[*]` (creative target) | `assets_required` | Tasks mentioning an asset format |
| `constraints.risk_tolerance` | `constraints.risk_tolerance` | Inherited unchanged |
| `constraints.budget_usd` | `constraints.budget_usd` | Inherited |
| `dissenting_opinions` | Calliope context | Passed as `context_refs` memo |
| `workflow_id` | `workflow_id` | Inherited |
| `id` | `parent_id` | Decision packet is parent of the brief |

Fields generated at conversion time:

| CreativeBrief field | Source |
|---|---|
| `campaign_id` | Generated fresh (UUID4) by Hydra planner |
| `target_audience` | Extracted from `notes` via LLM call; defaults to `"general"` |

## Dissent-handling conventions

When `CSuiteDecisionPacket.dissenting_opinions` is non-empty, Calliope applies the `executive-protocol` skill dissent-handling section:

1. Dissents recorded in a `context_refs` `MemoryRef` tagged `episodic`, surfaced to Calliope's working context at campaign start.
2. If a dissent references a brand constraint conflicting with the campaign objective, Calliope raises a `brand-consistency` gate with `hitl_required: true` BEFORE fan-out.
3. After approval via `/hydra:approve`, dissent recorded in final `DecisionRecord.dissenting_opinions` for audit.
4. Peer dissents: CFO budget objections route to Euterpe; CTO data-use flags route to governance-c2pa.

## Consumer-only boundary

No changes are required to ExecutiveSuite:

- Hydra's planner conversion node (`hydra_core/squad_node.py`) handles packet-to-brief translation.
- Calliope reads `CreativeBrief` the same way regardless of origin (`/creative-campaign` internal vs CMO upstream).
- ExecutiveSuite agents do not call any RLM-Creative tools or MCP endpoints.
- Only shared surface is `hydra_core/schemas.py`, imported read-only by both projects.

## Example flow

```
ExecutiveSuite session
  -> /exec-brief "We need a product launch campaign for Acme Bikes v2"
  -> CMO emits CSuiteDecisionPacket {
        origin: "CMO",
        objective: "Launch Acme Bikes v2 to urban commuters, Q3",
        proposed_tasks: [
          { target_squad: "creative", description: "hero video 30s + 3 statics" },
          { target_squad: "creative", description: "instagram + paid-search activation" }
        ],
        constraints: { budget_usd: 150, risk_tolerance: "medium" }
    }

Hydra planner
  -> detects target_squad: "creative"
  -> converts to CreativeBrief {
        campaign_id: <new UUID>,
        objective: "Launch Acme Bikes v2 to urban commuters, Q3",
        assets_required: ["hero-video:30s", "static:1080x1080 x3"],
        channels: ["instagram", "paid-search"],
        constraints: { budget_usd: 150, risk_tolerance: "medium" }
    }
  -> dispatches to creative squad

RLM-Creative
  -> Calliope receives CreativeBrief
  -> /creative-campaign workflow begins
```
