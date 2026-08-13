---
name: platform-voice
description: "Per-platform tone guides, caption length norms, hashtag etiquette, native-feeling formatting. Used by Terpsichore and Erato."
user-invocable: false
argument-hint: "<voice|format|hashtag>"
allowed-tools:
  - Read
  - Write
---

# Platform Voice

Reference for writing copy that reads as native to each platform. Terpsichore uses this to localize a single message into platform-native variants; Erato uses it during initial drafting to avoid one-size-fits-all copy.

## Purpose

A platform-native post outperforms a cross-posted one by orders of magnitude in engagement and reach. This skill encodes the voice, length, and formatting expectations of each major surface.

## When to use

- Erato is drafting the first version of campaign copy.
- Terpsichore is localizing a copy block for distribution across multiple platforms.
- An atom from `editorial-calendar`'s atomization pass needs platform-specific formatting.
- A repurpose review flags that copy reads off-platform.

## Inputs

- Core message (one or two sentences) and the supporting context
- Destination platform(s) from `CreativeBrief.channels`
- `brand_constraints.voice` and `brand_constraints.tone`

## Outputs

- One copy variant per destination platform, each compliant with the per-platform spec below
- Hashtag and formatting metadata per variant

## Per-platform tone guides

### Instagram (feed + Reels captions)

- Voice: warm, visual-first, lifestyle-aware. Captions complement the image; do not narrate it.
- Length: feed captions 138-150 chars before "more" truncation; sweet spot 70-150 chars; long captions (2000-2200 chars max) work for storytelling posts.
- Reels captions: shorter (under 125 chars often best); the video carries the story.
- Hashtags: 3-7 in feed; 0-3 in Reels; place after a line break or in first comment; avoid banned tags.
- Emoji: yes, sparingly, on-brand. Replace bullets with light emoji where tone permits.
- Mention: `@brand` for credit; do not bait-and-switch tag.
- CTA: "Save this" or "Send to a friend" outperform "Link in bio" for the algorithm.

### TikTok

- Voice: native, conversational, low-fi, internet-fluent. No corporate register. Authenticity > polish.
- Caption length: under 150 chars optimal; up to 4000 allowed but rarely read.
- Hooks: text overlay in first frame + caption hook. State the payoff or pose the question immediately.
- Hashtags: 3-5; mix one large (#fyp tier) + 2-3 niche + 1-2 branded. Avoid `#fyp` alone — algorithm discounts it.
- Sounds: use trending audio when it does not conflict with `brand-safety`; original sounds for sound-on identity over time.
- Captions on video (burned-in subtitles) are essential; 80%+ of TikTok plays start muted.

### X / Twitter

- Voice: punchy, opinionated, conversational. Wit rewarded; cringe punished.
- Length: under 280 chars per tweet; threads for depth (8-12 tweets max).
- Hooks: first 7 words decide whether the tweet gets the click or scroll-past.
- Hashtags: 0-2 max; usually none. Hashtags reduce reach on X.
- Mentions: @ a person only when they would actually want the tag.
- Reply game: replies and quote-tweets in the brand's niche compound faster than original posts.
- Avoid: corporate platitudes, threaded ads, "a thread" announcements before delivering value.

### LinkedIn

- Voice: professional but human; first-person; specific over generic; insight over inspiration.
- Length: 1300-1900 chars optimal for organic reach (post truncates around 210 chars; "see more" click is the engagement signal).
- Formatting: short paragraphs (1-2 sentences each); white space; occasional bullet via line breaks; avoid markdown (not rendered).
- Hashtags: 3-5 at the end; mix of broad and niche.
- CTA: ask a question that invites comment; comments drive reach more than likes.
- Avoid: humble-brags, generic career advice, AI-generated platitudes (the platform is fatigued).

### YouTube (titles + descriptions + community posts)

- Titles: 60 chars max before truncation; lead with the payoff; numbers and curiosity gaps perform; avoid clickbait that the video does not deliver.
- Descriptions: 200-500 words; first 150 chars matter most (above-the-fold); include keyword variants naturally; add timestamps as chapters; include CTAs and links at the bottom.
- Tags: less important than they used to be; still include 5-15 relevant.
- Community posts: 200-500 char polls, image posts, text updates; engagement here lifts video impressions.
- Shorts: title is the hook; description short; the video is everything.

### Threads

- Voice: conversational, lower-stakes than X; more personal, less aggressive.
- Length: 500 chars per post; threads via reply chains; sweet spot 100-300 chars.
- Hashtags: one per post max; often skipped.
- Replies: weight even higher than X; the platform's algorithm rewards conversation.
- Cross-posting from IG works but native posts do better; rewrite, do not paste.

### Substack / newsletter

- Voice: long-form, essayistic, personal. Subscribers expect a voice; deliver one.
- Length: 600-1800 words common; consistent length per series.
- Subject line: 30-50 chars; specific over clever; A/B test if volume allows.
- Pre-header: complements (does not repeat) subject line.
- Structure: lead with the most surprising sentence; deliver in body; close with a single CTA.
- Hashtags: not applicable.

## Caption length cheat sheet

| Platform | Sweet spot | Hard cap |
|---|---|---|
| Instagram feed | 70-150 chars | 2200 chars |
| Instagram Reels | <125 chars | 2200 chars |
| TikTok | <150 chars | 4000 chars |
| X / Twitter | <240 chars (room for RT) | 280 chars |
| LinkedIn | 1300-1900 chars | 3000 chars |
| YouTube title | <60 chars | 100 chars |
| YouTube description | 200-500 words | 5000 chars |
| Threads | 100-300 chars | 500 chars |
| Substack subject | 30-50 chars | 150 chars |

## Hashtag etiquette

- IG: 3-7 in feed, 0-3 in Reels; mix branded + niche + broad; avoid banned tags (Instagram silently suppresses).
- TikTok: 3-5; one broad + 2-3 niche + 1-2 branded; avoid `#fyp` alone.
- X: 0-2; usually zero; hashtags reduce reach.
- LinkedIn: 3-5 at end; mix of broad (#leadership, #marketing) and niche (#b2b-saas-pricing).
- Threads: 0-1.
- YouTube: in description, 3-15; first 3 show under title.
- Pinterest: 0-5 hashtags but use the description field for keyword-rich copy instead.

Never invent campaign hashtags that nobody will type. Use branded tags only when they will be re-used across many posts.

## Native-feeling formatting

- Match the platform's native punctuation rhythm — TikTok captions often skip periods; LinkedIn uses single-line paragraphs; X uses em-dashes and line breaks.
- Avoid markdown on platforms that do not render it (LinkedIn, X, Instagram). Use unicode bullets only when on-brand.
- Emoji: brand-dependent; never replace nouns with emoji on B2B platforms.
- Line breaks: load-bearing; previewable above-the-fold space is the first sentence on every platform.
- Subtitles on video: required for TikTok, Reels, YouTube Shorts; default for Feed.

## Procedure

1. Read the core message and destination platforms.
2. For each platform, draft a variant honoring the voice and length cheat sheet above.
3. Append platform-correct hashtags; verify against banned-tag lists where relevant.
4. Add subtitle text for any video destination.
5. Run `brand-safety` guardrail check on every variant.
6. Emit copy block per destination; hand to Terpsichore for scheduling.
7. After publication, log engagement per variant via `eights.memory.remember(tags=["platform","voice","performance"])` so future drafts inherit what works.

## Failure modes / escalation

- **Cross-posted copy reads off-platform** — rewrite; do not approve.
- **Hashtag in banned list** — substitute; verify before publish (lists shift).
- **Voice conflict between platforms** (e.g. exec wants the LinkedIn voice on TikTok) — escalate to Calliope; document the trade-off.

## References

- Brand guardrails: `brand-safety`
- Atom inventory and cadence: `editorial-calendar`
- Memory tags: `platform`, `voice`, `performance`
