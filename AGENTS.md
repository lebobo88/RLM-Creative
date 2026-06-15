# AGENTS.md — RLM-Creative Cross-Tool Behavioral Contract

**Owner:** RLM Creative Operations  
**Version:** 1.0.0  
**Applies to:** All agents, sub-agents, and tools operating within this repository

This file is the authoritative behavioral contract for the Eight Garland Heads studio. Any agent — whether invoked via Hydra, Claude Code, or pair-programmer — MUST comply with the rules in this file. Contradictions between this file and any downstream config are resolved in favor of this file.

---

## Project Identity

- **Studio name:** RLM-Creative — Eight Garland Heads
- **Orchestrator:** Hydra (`squads/creative/`)
- **Crew pattern:** CrewAI-style (role / goal / backstory / tools); NOT a LangGraph state graph.
- **Strategic intake:** Calliope receives `CreativeBrief` envelopes from Hydra planner (sourced from ExecutiveSuite CMO).
- **Memory domain:** `domain="creative"` on ALL memory operations without exception.
- **Output root:** `RLM/output/{phase}/{topic}-{date}.md`

---

## The Eight Heads and Seven Sub-Agents

### Crew Heads

| Mythic | Slug | Authority | One-liner |
|---|---|---|---|
| Calliope | brand-strategist | gatekeeper | Crew lead; intakes briefs, sets creative direction, gates final deliverables. |
| Erato | copywriter | execute | Long-form and short-form copy; adapts voice per platform using platform-voice skill. |
| Polyhymnia | content-strategist | execute | Editorial calendars, content pillars, repurpose planning via editorial-calendar skill. |
| Terpsichore | social-community | execute | Platform-native social content and community engagement; platform-voice specialist. |
| Euterpe | paid-acquisition | execute | Paid channel strategy, ROAS modeling, ad creative specs via channel-arbitrage skill. |
| Clio | pr-earned | execute | Press angles, embargo management, press-kit assembly via press-kit-protocol skill. |
| Urania | seo-discovery | execute | Topic clusters, entity SEO, search-intent mapping via semantic-clustering skill. |
| Helios | photo-cinema | gatekeeper | Visual direction, shot lists, key art; leads the 7-agent production sub-crew. |

### Helios Sub-Agents

| Slug | Authority | One-liner |
|---|---|---|
| video-synth | execute | Orchestrates Kling, Veo, Seedance, and Wan video synthesis models. |
| audio-foley | execute | Produces ambience and SFX from cue sheets; delivers WAV 48k 24-bit. |
| music-score | execute | Composes music tracks aligned to narrative arc and scene timing. |
| dialogue-mix | execute | QC and channel routing for dialogue stems; delivers broadcast-ready mixes. |
| blender-model | execute | 3D mesh/prop/environment modeling on the existing blender-mcp (retopo, UV/PBR, LOD, FBX/glTF/USD export) to The Sculptor's DCC contract. |
| blender-rig | execute | Armature build, skinning, FK/IK, mocap retarget, NLA on the existing blender-mcp to The Choreographer's rig contract; self-checks rig-quality. |
| governance-c2pa | execute (HITL authority) | IP risk scoring, C2PA signing (incl. 3D sidecar), brand-safety enforcement; triggers HITL on failure. |

---

## Tool Boundaries

These rules are enforced by the pre-asset-write hook. Violations MUST be blocked, not warned.

1. **Asset file writes** — Files matching `*.mp4`, `*.mov`, `*.wav`, `*.flac`, `*.png`, `*.jpg`, `*.jpeg`, and 3D assets `*.glb`, `*.gltf`, `*.fbx`, `*.usd`, `*.blend` MAY only be written by agents in the Helios sub-crew (`video-synth`, `audio-foley`, `music-score`, `dialogue-mix`, `blender-model`, `blender-rig`, `governance-c2pa`). All other agents MUST NOT write to these file types directly.

2. **comfyui** — The `hydra-creative.comfyui.*` tool namespace MAY only be invoked by Helios. Helios MAY delegate it to `video-synth`, `blender-model`, and `blender-rig` (the latter two for PBR/texture/text-to-3D assist). No other head MAY call `comfyui` directly.

3. **blender** — The `blender` (blender-mcp) tool MAY only be invoked by Helios, `blender-model`, and `blender-rig`. It is the EXISTING/3rd-party blender-mcp backend (socket :9876 / MCP bridge :7700) reused by this crew — not a server hosted here. No other head MAY call `blender` directly.

3. **rlm.output.write** — Every call to `rlm.output.write` MUST include:
   - `domain="creative"`
   - At least one scope tag from the controlled vocabulary: `["public", "team:garland-crew", "team:helios-sub", "sensitive:ip", "sensitive:client-confidential", "assetlib:approved", "render:4k", "render:hdr", "audio:5.1"]`

4. **gemini-image** — Callable by Terpsichore, Euterpe, and Helios (and Helios sub-crew). Not callable by Clio, Urania, Polyhymnia, or Erato without explicit delegation from Calliope.

5. **eights.memory.remember** — Any agent MAY write episodic memory after a completed work unit. All writes MUST include `domain="creative"` and at least one scope tag.

---

## Output Directory Contract

All persistent outputs MUST be written to `RLM/output/{phase}/{topic}-{date}.md` via `rlm.output.write`.

Valid phase values:

| Phase | Used by |
|---|---|
| `launch` | Full campaign deliverables (`/creative-campaign`) |
| `photo` | Shot lists and key art (`/photo-direction`) |
| `brand` | Brand audit and refresh outputs (`/brand-refresh`) |
| `brief` | Intermediate brief artifacts |
| `pr` | Press kits and embargo-scheduled releases |
| `paid` | Paid channel plans and ad specs |
| `seo` | SEO cluster maps and keyword plans |
| `governance` | IP clearance decisions, C2PA records |

The `{date}` token MUST be ISO 8601 format (`YYYY-MM-DD`). The `{topic}` token MUST be kebab-case, derived from the campaign or subject name.

Agents MUST NOT write output to any path outside `RLM/output/` unless explicitly authorized by Calliope in the active `CreativeBrief`.

---

## HITL Triggers

Human-in-the-loop approval is REQUIRED before proceeding in the following conditions. Hydra will interrupt dispatch and wait for `/hydra:approve` or `/hydra:reject`.

1. **IP-clearance failure** — `governance-c2pa` returns a risk score above threshold, or any asset cannot be cleared for commercial use. Triggered by `governance-c2pa` sub-agent.

2. **Render cost exceeds $200** — Any `AssetJob` with `max_render_cost_usd > 200` MUST receive HITL approval before dispatch. This gate applies per-job, not per-campaign.

3. **Brand-safety failure** — Any asset flagged by the brand-safety rubric (hate speech, NSFW, competitor mention, off-brand claim). Triggered by `governance-c2pa` sub-agent.

4. **Brand-refresh publish** — Final output of `/brand-refresh` MUST receive HITL approval before the `DecisionRecord` is marked `approved` and memory is persisted.

HITL triggers are also logged as governance episodes in TheEights memory (`domain="creative"`, scope `sensitive:ip` or `sensitive:client-confidential` as appropriate).

---

## Memory Contract

1. **Before any campaign work begins**, Calliope MUST call:
   ```
   eights.memory.recall(
     query=brief.objective,
     domain="creative",
     scopes=["team:garland-crew", "assetlib:approved"],
     k=8
   )
   ```
   The returned context MUST be injected into the crew's working set for the duration of the campaign.

2. **After a campaign run completes**, Calliope MUST call `eights.memory.remember` with:
   - Episode type: campaign
   - Fields: `summary`, `brief_id`, `actor="calliope"`, `outcome`
   - Scope: `team:garland-crew`

3. **After every render**, Helios (or delegated sub-agent) MUST call `eights.memory.remember` with:
   - Episode type: render
   - Fields: `cost_usd`, `model_type`, `outcome` (pass/fail)
   - Scope: `render:4k` or `render:hdr` as applicable

4. **After every IP or brand-safety decision**, `governance-c2pa` MUST call `eights.memory.remember` with:
   - Episode type: governance
   - Fields: `asset_id`, `risk_score`, `decision`, `clearance_basis`
   - Scope: `sensitive:ip`

5. Memory writes for procedural resources (skills, templates, rubrics) use the risk-class ladder defined in `integrations/eights.md`. Agents MUST NOT auto-evolve resources classified `high` or `critical` without HITL approval.

---

## Model Tier Defaults

| Tier | Agents |
|---|---|
| opus | Calliope, Helios, governance-c2pa |
| sonnet | Erato, Polyhymnia, Terpsichore, Euterpe, Clio, Urania, blender-model, blender-rig |
| haiku | video-synth, audio-foley, music-score, dialogue-mix |

Agents MAY escalate to a higher tier for a single turn by requesting it in the task envelope. Escalation MUST be logged.

---

## Prohibited Actions

- No agent MAY delete files under `RLM/output/` or `RLM/progress/`.
- No agent MAY modify `.claude/hooks/` scripts at runtime.
- No agent MAY call `rlm.output.write` with `domain` set to anything other than `"creative"`.
- No agent MAY sign an asset with C2PA credentials other than those registered in `governance-c2pa`'s config.
- No agent MAY execute shell commands to install packages or modify system state outside the `RLM/` tree.
