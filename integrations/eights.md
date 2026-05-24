# TheEights Integration - Memory and Evolution Contract

How the Eight Garland Heads crew uses TheEights for cross-campaign episodic memory, semantic knowledge accumulation, and governed skill evolution.

## Domain and scope vocabulary

Every TheEights memory operation from RLM-Creative uses:

```python
domain = "creative"
```

Controlled scope vocabulary:

| Scope tag | Meaning |
|---|---|
| `public` | Safe for any consumer; no client or IP data |
| `team:garland-crew` | Visible to all 8 heads and Helios sub-crew |
| `team:helios-sub` | Visible only to Helios and its 5 sub-agents |
| `sensitive:ip` | IP-encumbered assets; governance-c2pa gated |
| `sensitive:client-confidential` | NDA-bound client data; explicit grant required |
| `assetlib:approved` | References into `RLM/approved-assets/` |
| `render:4k` | 4K render output metadata |
| `render:hdr` | HDR render output metadata |
| `audio:5.1` | 5.1 surround audio output metadata |

Multiple scopes on a single write are additive. A C2PA-signed 4K hero video sits under `["assetlib:approved", "render:4k", "team:garland-crew"]`.

## Episodic write triggers

The rlm-bridge TheEights adapter tails `RLM/progress/events.jsonl` (written by `post-render-validate.ps1`) and converts events to episodic memories.

### 1. Campaign run (actor: calliope)

Written at `/creative-campaign` completion by Calliope:

```python
await mem.remember(
    "episodic",
    content=json.dumps(decision_record),
    actor="calliope",
    project_id=workflow_id,
    domain="creative",
    scopes=["team:garland-crew"],
    summary=f"Campaign '{brief.objective}' - {outcome}",
)
```

Episodic content fields: `brief_id`, `campaign_id`, `objective`, `channels`, `outcome` (pass/fail/hitl), `actor`, `duration_ms`.

### 2. Render event (sourced from events.jsonl)

Written by rlm-bridge for each new line in events.jsonl:

```python
await mem.remember(
    "episodic",
    content=json.dumps(event),
    actor=event["agent"],
    project_id=workflow_id,
    domain="creative",
    scopes=["team:helios-sub", "render:4k"],
    summary=f"Render by {event['agent']}: {event['output_path']} exit={event['exit_code']}",
)
```

### 3. Governance decision (actor: governance-c2pa)

Written when governance-c2pa completes an IP-clearance or C2PA signing step:

```python
await mem.remember(
    "episodic",
    content=json.dumps(decision_record),
    actor="governance-c2pa",
    project_id=workflow_id,
    domain="creative",
    scopes=["sensitive:ip", "team:garland-crew"],
    summary=f"Governance: {decision_type} - {asset_path} - {verdict}",
)
```

## Semantic write patterns

TheEights auto-extracts semantic memories from episodic content. Patterns registered for the `creative` domain:

| Pattern | Target agent for recall |
|---|---|
| "campaigns for {industry} that exceeded {ROAS} used {channels}" | Euterpe (paid-acquisition) |
| Brand-voice exemplars: tone descriptors + sample copy per client | Erato, Terpsichore |
| Shot-library vectors: frame thumbnails + lens metadata tuples | Helios |
| Channel performance benchmarks: platform x format x CTR triples | Euterpe, Polyhymnia |
| Press angle archetypes: narrative frame + coverage outcome | Clio |
| SEO cluster decay rates: cluster -> avg-rank-delta per quarter | Urania |

Semantic writes are owned by TheEights; agents do not call `remember` with `tier="semantic"` directly. They write episodic; TheEights extracts and indexes semantic patterns automatically.

## Procedural resource risk classes (RSPL)

| Risk class | Resources | Evolution policy |
|---|---|---|
| **low** (auto-evolve) | `editorial-calendar` templates, color-grade LUT presets, `comfyui-workflow-recipes` | TheEights may update without HITL |
| **medium** (auto-evolve + notify) | `platform-voice` guides, `shot-list-protocol` templates | TheEights proposes; Calliope notified; 24-hour veto window |
| **high** (HITL required) | `brand-safety` rubric, IP-clearance rubric, `channel-arbitrage` thresholds | Calliope + human sign-off required |
| **critical** (frozen) | C2PA signing keys, client NDA scope rules | No automated evolution; manual rotation only via governance-c2pa |

## Recall hook usage

### /creative-campaign

Before brief fan-out, Calliope recalls prior wisdom:

```python
hits = await mem.recall(
    query=brief.objective,
    actor="calliope",
    project_id=workflow_id,
    domain="creative",
    tiers=["episodic", "semantic"],
    scopes=["team:garland-crew"],
    k=8,
)
state["prior_wisdom"] = hits
```

Top-k results inject into Calliope's working context and reference in `CreativeBrief.context_refs` so all downstream heads have access.

### /brand-refresh

```python
hits = await mem.recall(
    query=f"brand identity {client}",
    actor="calliope",
    project_id=workflow_id,
    domain="creative",
    tiers=["episodic", "semantic"],
    scopes=["assetlib:approved", "team:garland-crew"],
    k=12,
)
```

Helios performs a separate recall scoped to `["assetlib:approved", "render:4k"]` for the client's visual asset history.

## events.jsonl tail contract

`RLM/progress/events.jsonl` is the bridge between render hooks and TheEights episodic memory.

- **Written** by `post-render-validate.ps1` (one JSON-line event per ffmpeg/ffprobe invocation).
- **Tailed** by the TheEights `rlm-bridge` adapter; polls for new lines, converts each to an episodic write.
- **Never truncated** - append-only; retention is managed by TheEights via TTL policies on episodic tier.

Event line schema:

```json
{"ts":"2026-05-19T14:23:01.042Z","agent":"video-synth","tool":"Bash","output_path":"RLM/output/production/hero-2026-05-19.mp4","duration_ms":87400,"exit_code":0}
```

rlm-bridge dedup key: `agent` + `output_path` + `ts`.

## EightsMemoryService API reference

```python
from hydra_core.eights_memory import EightsMemoryService, MemoryRef

async with await EightsMemoryService.connect() as mem:

    # --- recall ---
    hits: list[MemoryRef] = await mem.recall(
        query="...",
        actor="calliope",
        project_id="...",
        domain="creative",
        tiers=["episodic", "semantic"],
        scopes=["team:garland-crew"],
        k=8,
    )

    # --- remember ---
    ref: MemoryRef = await mem.remember(
        "episodic",
        content="...",
        actor="calliope",
        project_id="...",
        domain="creative",
        scopes=["team:garland-crew"],
        summary="One-line summary for episodic index",
    )
```

`EightsMemoryService.connect()` is an async context manager; spawns the daemon as a subprocess on first call and keeps it alive for the session. Use one service instance per Hydra process.
