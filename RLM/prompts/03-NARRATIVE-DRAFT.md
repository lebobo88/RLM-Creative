# Phase 03 — NARRATIVE DRAFT

## Purpose
Translate the published `CreativeBrief` into a campaign narrative architecture: the spine, key messages laddered to proof, voice pillars, and the central creative idea. This is the prose backbone every other head will quote.

## Owners
- **Lead**: Calliope (owns the strategic story; final word on the central idea)
- **Co-lead**: Erato (owns voice, line-level craft, headline drafting)
- **Mode**: AUTOMATED with two checkpoints

## Inputs
- `RLM/output/briefs/{brief_id}.json` (the CreativeBrief)
- `eights.memory.recall(domain="creative", query=brief.objective + brief.industry, scopes=["public","team:garland-crew","assetlib:approved"], k=10)` — pull prior winning narratives
- Skill: `platform-voice` (Erato), `creative-brief-protocol` (Calliope)

## Step 1 — Central Creative Idea (Calliope alone)
Compose ONE sentence that names the campaign's central insight. Format:
> "We tell {audience} that {tension} so they {desired shift}, by showing {distinctive proof}."

Constraints:
- The sentence MUST be ownable — if a competitor could run it unchanged, it is rejected.
- It MUST be defensible against the `brand_constraints.hard_donts` list.
- It MUST be expressible in the campaign's `tone` adjectives.

If Calliope cannot produce 3 candidate sentences that meet these tests, STOP and request a discovery refresh.

## Step 2 — Story Spine (Calliope drafts, Erato refines)
Use the 7-beat spine:
1. **World** — the audience's status quo in one line
2. **Tension** — the unresolved problem the brand recognizes
3. **Promise** — what the brand offers, in audience language (not feature language)
4. **Proof** — three concrete reasons-to-believe, ranked by `key_messages`
5. **Demonstration** — the moment the audience sees the promise made real
6. **Invitation** — the call-to-action, expressed as an emotional choice not a button
7. **Aftermath** — the future-state the audience lives in post-conversion

Each beat MUST be one paragraph max, written in the campaign's `tone`.

## Step 3 — Voice Pillars (Erato leads)
Define exactly 4 voice pillars as `{name, do, dont, exemplar}`. The exemplar is a 25-word line in voice. Examples:
- `Pillar: Plain` — Do: short Anglo-Saxon words. Don't: jargon, hedging. Exemplar: `<line>`.
- `Pillar: Specific` — Do: numbers, named places, brand-specific nouns. Don't: superlatives without proof.

These pillars become the rubric every downstream head writes against (Polyhymnia, Terpsichore, Euterpe, Clio, Urania ALL grade their copy against these).

## Step 4 — Key-Message Ladder (Calliope + Erato)
For each `key_messages` entry from the brief, produce:
- **Audience phrasing** (how the audience would say it back)
- **Brand phrasing** (the canonical line, ready for headlines)
- **Long phrasing** (~50 words, for PR and SEO body copy)
- **Proof anchor** (the asset, stat, or testimonial that justifies it)

## Reasoning gate
Before emitting, Calliope checks:
- No claim in any key-message ladder is unbacked. Anything unbacked is flagged for `clio` to source or `governance-c2pa` to reject.
- The story spine survives the "swap the brand name" test — if it works for any competitor, it is too generic.
- Tone adjectives appear demonstrably in at least 2 voice pillars.

## Output
Write `RLM/output/narrative/{brief_id}-narrative.md` containing:
- Central idea (one sentence + 2 runner-up candidates)
- Story spine (7 beats)
- Voice pillars (4 pillars with exemplars)
- Key-message ladder (one block per message)
- Open prompts for Helios (visual moments implied by the spine)
- Open prompts for Polyhymnia (content extensions implied by the spine)

Then `eights.memory.remember` with `{type:"narrative_published", brief_id, central_idea, voice_pillars}`.

## Handoff
- Helios begins Phase 04 keyed to the spine's Demonstration beat.
- Polyhymnia, Terpsichore, Euterpe, Clio, Urania each receive the voice pillars as their copy rubric.
- Emit: `{"phase":"03-narrative","status":"complete","artifact":"<path>"}`.
