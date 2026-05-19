# RLM-Creative — Eight Garland Heads Studio

**Owner:** RLM Creative Operations  
**Status:** Active  
**Last updated:** 2026-05-19

---

## Name and Purpose

RLM-Creative is a CrewAI-style multi-agent studio wired into the Hydra orchestrator. It provides end-to-end creative and production capability — from strategic brand brief through asset delivery — via eight specialized agents named after the classical Muses plus Helios (photo-cinema). A five-agent sub-crew under Helios handles video synthesis, audio, music, dialogue, and IP governance.

The studio replaces the generic `squads/creative/` entry in Hydra with a fully defined eight-head topology. It is the canonical creative squad for all RLM ecosystem projects.

---

## The Eight Garland Heads

| Mythic | Plaza Slug | Authority | Scope |
|---|---|---|---|
| Calliope | brand-strategist | gatekeeper (crew lead) | Brand strategy, brief intake, stakeholder communications, creative direction |
| Erato | copywriter | execute | Long-form and short-form copy, voice adaptation per platform |
| Polyhymnia | content-strategist | execute | Content calendar, pillar-to-repurpose planning, editorial architecture |
| Terpsichore | social-community | execute | Platform-native social content, community engagement, tone calibration |
| Euterpe | paid-acquisition | execute | Paid channel strategy, ROAS optimization, ad creative specification |
| Clio | pr-earned | execute | Press angles, embargo management, press-kit assembly, earned media |
| Urania | seo-discovery | execute | Semantic topic clusters, entity SEO, search-intent mapping |
| Helios | photo-cinema | gatekeeper (sub-crew lead) | Visual direction, shot lists, key art, video synthesis, C2PA governance |

### Helios Sub-Crew (5 Specialists)

| Slug | Scope |
|---|---|
| video-synth | Kling / Veo / Seedance / Wan video model orchestration |
| audio-foley | Ambience, SFX, cue-sheet-driven audio production |
| music-score | Narrative-arc-driven music composition |
| dialogue-mix | Dialogue QC and multi-channel routing |
| governance-c2pa | IP risk scoring, C2PA signing, brand-safety enforcement (HITL authority) |

---

## Architecture Summary

The studio follows the **CrewAI pattern**: each head has a role, goal, backstory, and tool list. Agents are event-driven peers that communicate via Hydra's typed envelopes. The graph-level supervision belongs to Hydra's planner; RLM-Creative owns only the agent definitions and crew contract.

```
ExecutiveSuite/CMO (Hermes) ──CSuiteDecisionPacket──> Hydra planner
                                                       |
                                                       v  CreativeBrief envelope
                                              +------------------+
                                              |  Calliope (lead) |  brand-strategist
                                              +--------+---------+
                                                       | fan-out
         +----------+----------+-----------+----------+---------+----------+----------+
         v          v          v           v                    v          v          v
       Erato   Polyhymnia  Terpsichore  Euterpe               Clio      Urania     Helios
      (copy)   (content)   (social)     (paid)               (PR)      (SEO)   (photo/cinema)
                                                                                    |
                                               +-------------------+----------------+---+
                                               v                   v                v   v
                                         video-synth          audio-foley     music-score dialogue-mix
                                                                                          |
                                                                             governance-c2pa
```

**Hermes -> Calliope bridge:** Hydra detects `domain: marketing` or `assets_required: [...]` in a `CSuiteDecisionPacket` emitted by the ExecutiveSuite CMO and converts it to a `CreativeBrief` envelope, which is dispatched to the `creative` squad and received by Calliope.

**Tool absorption:** `comfyui`, `gemini-image`, and `gemini-content` are tools the heads call (via `hydra-creative.*` MCP namespace), not peer agents. Only Helios may delegate to `comfyui`.

---

## Three Orchestrator Commands

### `/creative-campaign <brief>`

Full-crew run from brief through deliverables.

1. Calliope intakes the brief and emits a `CreativeBrief` envelope.
2. Calliope calls `eights.memory.recall(domain="creative")` to surface prior campaign wisdom.
3. Parallel fan-out: Erato (copy variants), Polyhymnia (content calendar), Terpsichore (platform plan), Euterpe (paid plan), Clio (PR angles), Urania (SEO clusters), Helios (visual direction → `ShotList` → `AssetJob`).
4. `governance-c2pa` gates every asset. HITL interrupts on IP-clearance failure.
5. Synthesizer collates into `DecisionRecord` and writes `RLM/output/launch/{topic}-{date}.md`.

### `/photo-direction <subject>`

Helios-led shot list and key art workflow. Skips Calliope when already inside an active campaign.

1. Helios intakes subject and generates a `ShotList` via the `shot-list-protocol` skill.
2. Sub-crew renders: video-synth, comfyui, gemini-image.
3. `governance-c2pa` signs approved assets.
4. `rlm.output.write` to `RLM/output/photo/{subject}-{date}.md`.

### `/brand-refresh <client>`

Calliope-led brand audit and reposition.

1. Calliope recalls existing brand artifacts from `eights.memory.recall(domain="creative", scopes=["assetlib:approved"])`.
2. Audits voice (Erato), positioning (Calliope), visual identity (Helios in advisory mode).
3. Emits reposition recommendation and delta artifacts. HITL gate before publish.
4. Persists as `DecisionRecord`; `dissenting_opinions` field populated if Erato or Helios disagreed.

---

## Running Under Hydra

The studio is registered as the `creative` squad in Hydra. The canonical squad manifest is `squad.yaml` at the repo root; `C:\AiAppDeployments\Hydra\squads\creative\squad.yaml` is a copy that MUST be kept in sync.

**Start a campaign via Hydra CLI:**

```powershell
cd C:\AiAppDeployments\Hydra
python -m hydra_core.cli run "draft Q3 brand campaign for Acme" --squad creative
```

**Verify squad is loaded:**

```powershell
python -m hydra_core.cli doctor
python -m hydra_core.cli squads
```

**Approve a HITL gate:**

```
/hydra:approve
```

---

## Running Standalone in Claude Code

Open `C:\AiAppDeployments\RLM-Creative\` as your Claude Code working directory. `CLAUDE.md` imports `AGENTS.md` automatically, making all behavioral rules and head definitions available.

```
# Start a full campaign
/creative-campaign Draft a launch campaign for Project Meridian targeting B2B SaaS buyers.

# Photo direction only
/photo-direction hero product shot — matte black hardware, studio lighting, minimalist

# Brand audit
/brand-refresh Acme Corp
```

Agents are resolved from `.claude/agents/`. Skills are in `.claude/skills/`. Commands are in `.claude/commands/`.

---

## Integration with ExecutiveSuite, TheEights, and Pair-Programmer

**ExecutiveSuite (Hermes/CMO):** The CMO agent at `ExecutiveSuite/.claude/agents/cmo.md` emits `CSuiteDecisionPacket` envelopes. Hydra detects `domain: marketing` and converts to `CreativeBrief`. No changes required to ExecutiveSuite. See `integrations/executive-suite.md` for the field-mapping table.

**TheEights (shared memory):** All memory operations use `domain="creative"`. Calliope calls `eights.memory.recall` before every campaign run. Post-run, episodes are written back via the `rlm-bridge` adapter tailing `RLM/progress/events.jsonl`. See `integrations/eights.md` for the recall/remember contract.

**Pair-Programmer (/pp):** `.harness/profile.yaml` defines the `creative-media` profile. `/pp:run` and `/pp:team` operate over this repo the same way they do over RLM-CLI-Starter. The `engineer` agent auto-discovers `AGENTS.md` and honors the asset-write restriction.

---

## Repo Layout

```
RLM-Creative/
├── README.md                        # This file
├── AGENTS.md                        # Cross-tool behavioral contract
├── CLAUDE.md                        # @AGENTS.md import shim
├── heads.yaml                       # Canonical 8-head + 5-sub-agent registry
├── squad.yaml                       # Hydra squad manifest
├── hooks.json                       # Top-level hook registry
├── .harness/profile.yaml            # Pair-programmer profile: creative-media
├── .claude/
│   ├── agents/                      # 8 head agent files + helios-crew/
│   ├── commands/                    # /creative-campaign, /photo-direction, /brand-refresh
│   ├── skills/                      # 10 reusable skill modules
│   └── hooks/                       # PowerShell hooks
├── RLM/
│   ├── prompts/                     # 8 phase prompt files (01–08)
│   ├── specs/creative-constitution.md
│   ├── tasks/                       # CAMPAIGN-NNN.md instances
│   ├── progress/                    # .current-context.md, events.jsonl
│   └── output/                      # {phase}/{topic}-{date}.md
└── integrations/
    ├── hydra.md
    ├── executive-suite.md
    └── eights.md
```

---

## Quick Start

**Prerequisites:** Hydra running, TheEights bridge active, Claude Code installed.

```powershell
# 1. Open studio in Claude Code
code C:\AiAppDeployments\RLM-Creative

# 2. Verify Hydra doctor passes
cd C:\AiAppDeployments\Hydra
python -m hydra_core.cli doctor

# 3. Run a campaign from Claude Code (RLM-Creative cwd)
/creative-campaign <your brief here>

# 4. Check output
ls RLM\output\launch\
```

**HITL behavior:** If `governance-c2pa` flags an IP-clearance failure or a render job exceeds $200, Hydra will pause and prompt for human approval before continuing. Use `/hydra:approve` or `/hydra:reject` to resume.
