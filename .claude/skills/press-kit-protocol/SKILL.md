---
name: press-kit-protocol
description: "Clio's playbook. Story angles, embargo etiquette, press-kit assembly, outlet tiering."
user-invocable: false
argument-hint: "<angle|assemble|pitch|tier>"
allowed-tools:
  - Read
  - Write
---

# Press Kit Protocol

Clio's playbook for earned media. Converts a `CreativeBrief` into press-ready angles, an assembled press kit, and a tiered outlet pitch plan.

## Purpose

Produce coverage that compounds brand equity. The protocol enforces angle clarity, embargo discipline, and a kit assembly that does not waste a reporter's time.

## When to use

- A campaign has a hard news hook (launch, funding, partnership, milestone).
- A founder, exec, or research drop creates a thought-leadership opportunity.
- A `/creative-campaign` includes `pr-earned` in `channels`.
- A response is needed to a competitor narrative or industry event.

## Inputs

- `CreativeBrief.objective`, `key_messages`, `brand_constraints`
- Available facts: dates, numbers, exclusivity status, available executives, embargo windows
- Prior coverage and outlet relationships via `eights.memory.recall(tags=["pr","outlet","reporter"])`

## Outputs

- `press_kit/` directory with: boilerplate, fact sheet, exec bios, hi-res asset bundle, contact card, embargoed release
- `pitch_plan.json` with tiered outlet list, reporter assignments, pitch angles, send schedule
- Coverage tracker initialized for measurement

## Story angles framework

A pitch lives or dies on its angle. Pick at least one; combine no more than two.

1. **News hook** — there is a hard, dated, verifiable event. The simplest angle. Requires real news.
2. **Exclusivity** — one outlet gets it first. Trade: depth and front-of-mind placement for breadth.
3. **Data drop** — original research, novel dataset, surprising finding. Pairs well with a chart-rich kit. Reporters love numbers they can quote.
4. **Founder-led** — origin story, contrarian operator perspective, or founder taking a public position. Requires a media-ready founder.
5. **Contrarian take** — counter the conventional industry wisdom. High risk of clapback; must be defensible with data.
6. **Trend-mapping** — "X is happening across the industry; we are the proof point." Works for trade press.
7. **Customer story** — named customer, measurable outcome, on-the-record quote. The gold standard for B2B.
8. **Milestone** — anniversaries, headcounts, user counts; only when the number is genuinely impressive.
9. **Personnel** — exec hire, board addition, advisor announcement. Trade and vertical only unless the person is industry-famous.
10. **Issue-led** — anchor to a topical issue (policy, regulation, cultural moment). Walk the brand-safety line; coordinate with `brand-safety`.

Kill any angle that is purely promotional. Reporters can smell a press release dressed as a story.

## Embargo etiquette

- Always specify the embargo time, time zone, and date in the subject line and the first line of the email.
- Embargo windows: 24-72 hours typical; <24h is rude; >5 business days leaks.
- Do NOT pitch on embargo to outlets you have no prior relationship with; they may publish early.
- If a reporter says "I can't agree to your embargo," do not send the materials. Move on.
- One embargo break = that outlet does not get embargoed pitches from you again. Tell them why.
- Exclusives override embargo: if one outlet has the exclusive, others receive the kit only at publish-time.
- For data drops, embargoed access to the underlying dataset is more valuable than the press release.

## Press kit assembly

Directory layout under `press_kit/{campaign_id}/`:

- `release.md` — the embargoed press release; one page; inverted pyramid; quote from named exec; quote from named customer or partner where possible; boilerplate at bottom.
- `boilerplate.md` — 75-120 word company description; identical across all releases; updated centrally.
- `fact_sheet.md` — founded date, HQ, founders, funding history, key numbers, leadership; bullet form.
- `exec_bios/` — one .md per executive; 100-200 words; current title; pronouns; high-res headshot referenced.
- `assets/` — hi-res images (3000px+ on long edge), product shots, logo bundle (SVG + PNG, light + dark), screenshots with browser chrome optional, b-roll if available.
- `data/` — for data-drop angles: the dataset (cleaned), methodology, chart files (PNG + source data CSV).
- `contact.md` — single point of contact, direct email, phone, time zone, availability windows.
- `quotes.md` — pre-approved exec and partner quotes that reporters can pull verbatim.

Deliver as a Dropbox / Google Drive / Notion link with view-only access OR a `.zip` for trade press that prefers attachments. Avoid PDFs that lock copy; reporters need quotable text.

## Tiering outlets

- **Tier 1** — top general-business and tech outlets (e.g. Wall Street Journal, New York Times, Financial Times, Bloomberg, Reuters, The Information, Wired). Long lead times, exclusivity-driven, one shot per angle. Pitch with concrete exclusivity offer.
- **Tier 2** — strong tech / business outlets and major industry trades (e.g. TechCrunch, Fast Company, Forbes contributors who report, Axios, Business Insider, The Verge, Ars Technica). Embargoes respected; pitch with angle + exclusive lever if possible.
- **Trade press** — industry-specific (AdAge, AdWeek, Variety, Hollywood Reporter, MediaPost, MarTech, Modern Retail, etc.). Highest hit rate; reporters appreciate operational detail.
- **Vertical / niche** — newsletters with engaged audiences (Stratechery, Lenny's, Hustle, etc.), Substack independents, podcast hosts, YouTube reviewers. Often outperform Tier 1 for actual conversions; relationship-driven.
- **Local / regional** — for hiring stories, office openings, community initiatives.

Do not pitch the same angle to Tier 1 and Tier 2 simultaneously. Cascade: Tier 1 first with exclusivity OR embargo; Tier 2 + trade at release; vertical / niche at release + ongoing.

## Procedure

1. Identify the strongest angle (max two). Stress-test: would a reporter cover this if it were a competitor doing it? If no, the angle is too thin.
2. Confirm available facts; secure exec quotes; lock customer / partner quotes with sign-off.
3. Assemble the press kit. Run `brand-safety` IP-clearance on every asset in `assets/`.
4. Decide cascade: pure exclusive to one Tier 1, OR embargoed multi-pitch to Tier 1 + Tier 2.
5. Draft pitch emails: subject line names the angle; first paragraph delivers the news; second paragraph offers access (exec interview, demo, dataset, embargo terms).
6. Send according to schedule; log responses in `pitch_plan.json`.
7. Publish day: release the kit broadly; brief Terpsichore for amplification; brief Euterpe if paid syndication is in plan.
8. Track coverage; write back to memory with `tags=["pr","coverage","outlet","reporter"]` including reporter, outlet tier, angle, sentiment, traffic delta, and any quote pulls.

## Failure modes / escalation

- **Embargo breaks early** — pivot to immediate publication; do not punish other outlets who honored the embargo; note the breaker for future exclusion.
- **Story misrepresents the brand** — Calliope coordinates a correction request; do NOT publicly contradict the reporter without strategic reason.
- **Reporter requests data not yet cleared** — route to `brand-safety` and Calliope; do not send unsigned.
- **No coverage from Tier 1** — fall back to vertical / niche where conversion impact is often higher anyway.

## References

- Brand voice and quote approval: `platform-voice`, `brand-safety`
- Memory tags: `pr`, `outlet`, `reporter`, `coverage`, `embargo`
