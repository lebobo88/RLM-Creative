---
name: editorial-calendar
description: "Pillar to cluster to repurpose cadence. Polyhymnia's playbook. Atomic-unit framework."
user-invocable: false
argument-hint: "<plan|atomize|quarter-arc>"
allowed-tools:
  - Read
  - Write
---

# Editorial Calendar

Polyhymnia's playbook for sustained content production. Translates a `CreativeBrief.objective` into a quarterly arc of pillars, clusters, and repurposed atoms.

## Purpose

Maximize compounding return on creative work by producing fewer, denser pillar pieces and atomizing each into 8-12 channel-native units. Avoid the trap of bespoke per-post effort.

## When to use

- A new `CreativeBrief` arrives with `objective` spanning more than 2 weeks.
- A `/brand-refresh` requires a content rollout plan post-launch.
- Quarterly planning kickoff.
- An evergreen asset is ready for a repurpose pass.

## Inputs

- `CreativeBrief` with `objective`, `target_audience`, `channels`, `key_messages`
- Optional: prior quarter's `editorial_calendar.json` for theme continuity
- Optional: SEO clusters from Urania (`semantic-clustering`)

## Outputs

- `editorial_calendar` record written to `RLM/output/launch/{campaign_id}-calendar-{date}.md` with structure `{quarter_arc, pillars[], clusters[], atoms[], cadence}`
- A weekly cadence schedule per channel
- Per-pillar `AssetJob` envelopes for the long-form deliverable

## Pillar -> cluster -> atom hierarchy

- **Pillar** — one substantial long-form unit per quarter month or every 2-3 weeks. Format options: 2000-4000 word essay, 8-12 minute video, podcast episode, research report. Carries one `key_message` end-to-end.
- **Cluster** — 3-5 supporting mid-length pieces per pillar that deepen sub-topics. 800-1500 words, 3-5 minute videos, carousels, infographics. Each cluster targets a SERP intent or a platform-native format.
- **Atom** — 8-12 short repurposed units per pillar. Single quote cards, 15-30s video cuts, single-tweet hooks, single email subject-line tests, single carousel slides as standalone posts.

## Atomic-unit framework

From one pillar (e.g. a 3000-word essay + 8-minute companion video):

1. Twitter/X thread (8-12 tweets) carrying the spine
2. LinkedIn long-form post (text-only, 1300-1900 chars)
3. Instagram carousel (8-10 slides, image + caption per slide)
4. Two TikTok hooks (15-30s each) from the most quotable moments
5. YouTube Short (45-60s) — the strongest TikTok cut re-edited 9:16 with subtitles
6. Threads post (sub-500 chars) seeding the discussion
7. Email newsletter section (200-400 words + CTA)
8. 2-4 quote cards (1:1 image + pull quote, for IG feed and Threads)
9. Pinterest pin (vertical infographic of the core framework)
10. Substack note or Medium cross-post
11. Podcast-style 60s audiogram (waveform + pull quote)
12. Internal sales-enablement one-pager (PDF, gated)

Not every pillar yields all 12; pick by channel mix.

## Quarterly theme arc

Structure: 13 weeks per quarter. Reserve weeks 1 and 13 as bookends.

- **Week 1** — theme announcement pillar (sets the macro thesis)
- **Weeks 2-4** — pillar A + clusters + atoms
- **Weeks 5-7** — pillar B + clusters + atoms
- **Weeks 8-10** — pillar C + clusters + atoms
- **Weeks 11-12** — pillar D + clusters + atoms (lighter; reserve capacity for reactive content)
- **Week 13** — synthesis pillar (recap + roadmap; recirculates atoms with new framing)

Reactive content (industry news, trending audio, real-time response) lives outside this cadence and uses 10-20% of channel capacity.

## Cadence per channel (typical, tune per audience)

| Channel | Cadence |
|---|---|
| Blog / pillar | 1 pillar / 3 weeks |
| Newsletter | 1 / week |
| LinkedIn | 3-5 / week |
| X / Twitter | 1-5 / day mix of original + reply |
| Instagram feed | 3-5 / week |
| Instagram Reels | 3-7 / week |
| TikTok | 1-3 / day |
| YouTube long | 1 / week to 1 / 2 weeks |
| YouTube Shorts | 3-7 / week |
| Threads | 3-10 / day light |
| Pinterest | 5-15 / week (compounds well) |

## Procedure

1. Read `CreativeBrief.objective` and `key_messages`. Each pillar maps to one key_message or sub-theme.
2. Recall: `eights.memory.recall(tags=["calendar","pillar"], k=10)` for prior cadence + performance data.
3. Draft the 13-week arc; assign 3-5 pillars; align pillar topics with Urania's `semantic-clustering` output.
4. For each pillar, draft the cluster list (3-5) and atom backlog (8-12).
5. Pick channel cadence per channel from the table; adjust for team capacity.
6. Emit `editorial_calendar.json`; hand pillar + cluster items to Erato (copy) and Helios (visuals). Atoms flow to Terpsichore for distribution.
7. After publication, write episode `eights.memory.remember(tags=["calendar","performance"], domain="creative")` with engagement metrics so next quarter's planning recalls what cadence + topic combos worked.

## Failure modes / escalation

- **Team capacity cannot sustain cadence** — cut cadence in half rather than reduce pillar depth.
- **Pillar topic conflicts with `brand-safety` taboo list** — bounce to Calliope.
- **Quarter-arc collides with launch campaign** — calendar pauses; campaign takes channel space; document the swap in `DecisionRecord`.

## References

- SEO clusters: `semantic-clustering` (Urania)
- Distribution: `platform-voice` (Terpsichore)
- Memory tags: `calendar`, `pillar`, `cluster`, `atom`, `performance`
