---
name: channel-arbitrage
description: "Euterpe's paid-acquisition playbook. ROAS targets, bid strategies, fatigue detection, scale vs rotate decisions, CAC payback heuristics."
user-invocable: false
argument-hint: "<plan|allocate|diagnose|scale>"
allowed-tools:
  - Read
  - Write
---

# Channel Arbitrage

Euterpe's playbook. Buys attention at the lowest stable cost while preserving brand integrity and downstream LTV.

## Purpose

Produce a paid-media plan with explicit ROAS targets per channel, bid strategies, creative-rotation cadence, and exit conditions. Track CAC payback and LTV:CAC continuously.

## When to use

- A `CreativeBrief.channels` includes any paid surface.
- A live campaign's performance crosses a fatigue or efficiency threshold.
- Quarterly budget allocation across channels.
- Diagnosing a sudden CAC spike or ROAS collapse.

## Inputs

- `CreativeBrief.budget_usd`, `objective`, `target_audience`, `channels`
- Historical channel performance via `eights.memory.recall(tags=["paid","roas","channel"], k=20)`
- Product economics: AOV, gross margin, repeat rate, LTV (60/90/365-day cohorts)

## Outputs

- `paid_plan.json` to `RLM/output/paid/{campaign_id}-plan-{date}.json` with per-channel budget, bid strategy, creative rotation, KPIs, kill switches
- Weekly performance read-out written back to memory tagged `paid:performance`

## ROAS targets per channel (baseline; tune by category)

ROAS = revenue / ad spend. These are healthy floors for direct-response e-commerce-style funnels; brand-building campaigns underwrite lower direct ROAS in exchange for assisted conversions.

| Channel | Healthy ROAS floor | Notes |
|---|---|---|
| Meta (Facebook + Instagram) | 2.5-4.0x | Best for mid-funnel + retargeting; broad targeting + Advantage+ now dominant |
| Google Search (branded) | 8-15x | Cheap; almost always positive; cap spend or competitors will harvest |
| Google Search (non-branded) | 2.0-3.5x | Intent-rich; protect from competitor bids |
| Google Performance Max | 2.5-4.0x | Black box; requires asset variety; watch placement reports |
| Google Display / YouTube | 1.2-2.0x direct, 3x+ assisted | Upper-funnel; measure via incrementality |
| TikTok Ads | 1.5-3.0x | Creative is everything; expect 7-day rotations |
| YouTube TrueView / In-Stream | 1.2-2.5x | Long view-through; brand-lift studies essential |
| X / Twitter Ads | 1.0-2.0x | Audience-dependent; B2B and crypto outperform |
| Programmatic display (DSP) | 1.0-1.8x direct | Best in retargeting and contextual; viewability >70% required |
| Reddit | 1.5-3.0x | Niche communities; creative must be native or it gets downvoted |
| LinkedIn | 1.0-2.5x | High CPM, high quality; B2B only; AOV must support it |

## Bid strategies

- **Manual CPC / max-CPC cap** — for early-stage learning, branded search, or when auto-bidding misbehaves.
- **Target CPA** — once you have >30 conversions / 30 days; algorithm bids to hit cost-per-acquisition.
- **Target ROAS** — for shops with stable AOV; needs accurate revenue passback.
- **Maximize conversions / value** — uncapped; only after you trust the funnel.
- **Cost cap (Meta)** — useful for protecting CAC while letting volume scale.
- **Bid cap** — for ruthless efficiency; sacrifices volume.

Guideline: start manual or capped; graduate to target CPA after 30 conversions; only run uncapped after sustained 4 weeks of healthy ROAS.

## Creative-fatigue detection

Signals (any 2+ triggers a rotation):

- Frequency > 2.5 (Meta) within 7 days
- CTR drops >25% vs first-week baseline
- CPM rises >20% with no auction-wide CPM movement
- CPA rises >30% over a rolling 7-day window
- Comments-to-impressions ratio drops sharply (engagement decay)
- Audience saturation: reach plateau on a non-broad audience

Measure per ad, not per ad set.

## Rotate vs scale

- **Rotate** when fatigue triggers fire on a winning creative. Refresh hook, opening 3 seconds, or thumbnail. Keep promise + offer constant.
- **Scale** when 7-day rolling ROAS >= target AND fatigue triggers are clean AND incrementality test (geo or holdout) shows lift. Scale by 20-30% / day on Meta; faster on Google Search.
- **Kill** when 14-day ROAS < 0.75x of target with no fixable fatigue cause. Do not nurse.

Never scale and rotate the same creative simultaneously.

## CAC payback and LTV:CAC heuristics

- **CAC payback** — months to recover blended CAC from gross profit. Healthy SaaS: <= 12 months; consumer subscription: <= 6 months; one-time-purchase e-com: payback on first order ideally, otherwise via repeat orders within 90 days.
- **LTV:CAC** — target >= 3:1 for sustainable growth; 4-5:1 means you are likely under-investing in growth; <2:1 means tighten funnel or cut spend.
- **Marginal LTV:CAC** — measure the *next* dollar's return, not the average. As you scale, marginal LTV:CAC compresses; stop scaling when marginal hits 1.5:1.
- **Incrementality** — geo-holdouts or ghost-bid tests every quarter. Last-click ROAS lies; assume 20-40% inflation on Meta and PMax until proven otherwise.

## Procedure

1. Read `CreativeBrief.budget_usd` and `channels`. Recall prior performance for this product + audience.
2. Allocate budget by channel: branded search gets priority (high ROAS, defensive); allocate the remainder by historical marginal ROAS, holding 10-20% in a test budget for new channels or creative concepts.
3. Set bid strategy per channel using the guideline above.
4. Define KPIs: per-channel ROAS floor, CPA ceiling, fatigue triggers, kill thresholds, scale conditions.
5. Coordinate creative supply with Helios (visual variants) and Erato (copy variants) to feed rotation cadence.
6. Schedule weekly read-out: budget delivered, ROAS, CAC, frequency, fatigue signals, scale/rotate/kill decisions. Persist via `eights.memory.remember(tags=["paid","performance"])`.
7. Quarterly incrementality test; recalibrate channel mix.

## Failure modes / escalation

- **Brand-safety incident on a paid surface** — pause campaign within 1 hour; route to `governance-c2pa`; HITL on resume.
- **Sustained CAC > LTV** — escalate to Calliope; campaign may need product/offer changes upstream of media.
- **Privacy/regulatory issue (signal loss, ATT, cookie deprecation)** — re-baseline measurement; warn that historic ROAS comparisons are invalid.
- **Auction-wide CPM spike (election season, Black Friday)** — recalibrate ROAS expectations; do not kill on temporary inflation.

## References

- Memory tags: `paid`, `roas`, `channel`, `paid:performance`, `incrementality`
- Creative supply: `platform-voice` (copy), `color-science` + `shot-list-protocol` (visual)
