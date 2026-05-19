---
name: semantic-clustering
description: "Urania's playbook. Topic-cluster authority model, entity SEO, schema.org markup, internal-link wiring, SERP-feature targeting."
user-invocable: false
argument-hint: "<cluster|entity|schema|interlink>"
allowed-tools:
  - Read
  - Write
---

# Semantic Clustering

Urania's playbook for organic discovery. Builds topical authority through pillar-cluster architecture, entity SEO, and schema.org markup. Designed for the AI-search era where the corpus is read by LLMs as much as crawled by spiders.

## Purpose

Convert `CreativeBrief.objective` into a defensible organic surface area: pillar pages, cluster pages, internal-link patterns, entity-rich content, and schema markup that earn SERP features and LLM citations.

## When to use

- A new product or brand needs an SEO foundation.
- An existing site has thin or scattered content lacking topical depth.
- Polyhymnia's editorial calendar needs SEO-grounded topic selection.
- A SERP feature (featured snippet, PAA, knowledge panel) is winnable but unwon.

## Inputs

- `CreativeBrief.objective`, `target_audience`, `key_messages`
- Existing site URL list (sitemap) if available
- Keyword research data (search volume, difficulty, intent) — supplied or pulled per tool availability
- Competitor SERP analysis for top 3-5 commercial keywords

## Outputs

- `cluster_map.json` to `RLM/output/seo/{campaign_id}-clusters-{date}.json` describing pillars, clusters, intents, internal links
- Schema.org JSON-LD snippets per page type
- Internal-link patch list for existing pages
- SERP-feature target list (snippet, PAA, knowledge panel, video carousel, image pack)

## Topic-cluster authority model

- **Pillar page** — a comprehensive, evergreen guide on a head term (e.g. "customer onboarding"). 3000-6000 words. Links out to all its cluster pages and is linked back from each.
- **Cluster pages** — focused articles on long-tail variants ("customer onboarding for SaaS", "customer onboarding KPIs", "customer onboarding software"). 1200-2500 words. Each links to the pillar and to 2-4 sibling clusters.
- **Hub-and-spoke wiring** — pillar is the hub; clusters are spokes. PageRank concentrates on the pillar; topical authority radiates to clusters.
- **Refresh cadence** — pillar reviewed quarterly; clusters reviewed bi-annually; both updated on any product or category change.

One pillar per buyer-journey stage per audience. Do not duplicate pillars across stages (awareness pillar vs consideration pillar vs decision pillar are distinct).

## Entity SEO

The modern search engine and the LLM both think in entities, not keywords. For each pillar:

- Identify the head entity (the thing the page is *about*) and 8-15 related entities (people, places, products, concepts) the page should mention.
- Cross-reference the entities with Wikidata or Wikipedia where applicable; align spelling and disambiguation.
- Mention every related entity at least once with context; link to canonical sources when authoritative.
- Build an `entity_glossary.md` per pillar so future updates preserve coverage.

LLMs cite content that names entities cleanly and provides definitional sentences. Definitional sentences ("X is a Y that does Z") get pulled into AI Overviews and chatbot answers.

## Schema.org markup

Minimum schema per page type (JSON-LD in `<head>`):

- **Pillar / cluster article** — `Article` or `BlogPosting` with `headline`, `author`, `datePublished`, `dateModified`, `image`, `publisher`, `mainEntityOfPage`.
- **Product page** — `Product` with `name`, `brand`, `offers` (`Offer` with `price`, `priceCurrency`, `availability`), `aggregateRating` if applicable, `review` if applicable.
- **FAQ section** — `FAQPage` with `mainEntity` array of `Question` -> `acceptedAnswer`.
- **How-to** — `HowTo` with `step` array.
- **Video** — `VideoObject` with `name`, `description`, `thumbnailUrl`, `uploadDate`, `duration` (ISO 8601), `contentUrl`.
- **Organization** (site-wide) — `Organization` on the home page with `logo`, `sameAs` (social profiles), `contactPoint`.
- **Breadcrumb** — `BreadcrumbList` on every non-home page.

Validate every snippet with Google's Rich Results Test before publish.

## Internal-link patterns

- Every cluster page links to its pillar with descriptive anchor text containing the pillar's head term.
- Pillar page links out to all its clusters in a single "Explore the topic" section AND in-line where contextually relevant.
- Each cluster links to 2-4 sibling clusters in-line, not just at the bottom.
- Older posts get retro-fitted links to new pillars/clusters (this is the highest-leverage SEO maintenance task).
- Avoid `nofollow` on internal links unless gating UGC.
- Use 60-80% descriptive anchor text; 20-40% generic ("read more", "learn how") for naturalness.

## SERP-feature targeting

- **Featured snippet (paragraph)** — open the relevant section with a 40-60 word direct answer to the query in plain prose. Use the query phrasing in the H2 above it.
- **Featured snippet (list)** — H2 in the form "How to X" or "X steps to Y"; follow with an ordered or unordered list of 5-8 items.
- **Featured snippet (table)** — H2 with comparative intent; follow with a markdown / HTML table of 3-5 columns.
- **People Also Ask** — include a FAQ section with `FAQPage` schema; phrase questions exactly as users ask them.
- **Knowledge panel** — `Organization` schema, consistent NAP (name/address/phone), populated Wikidata entry where eligible, brand mentions across authoritative outlets.
- **Image pack** — descriptive `alt` text, `<figure>` + `<figcaption>`, file names that match topic, image sitemap entry.
- **Video carousel** — `VideoObject` schema, transcript on page, hosted on YouTube + embedded, chapters via `Clip` schema.
- **Top stories** — requires `NewsArticle` schema + Google News inclusion; news-cadence sites only.
- **LLM citation (AI Overviews, Perplexity, ChatGPT browse)** — clean entity coverage, definitional sentences, freshness signals (`dateModified`), authoritative outbound citations, named author with bio page.

## Procedure

1. Identify 3-5 head terms most aligned with `objective` and audience.
2. For each head term, propose a pillar page; map 5-10 cluster pages per pillar with intent classification (informational / commercial / transactional / navigational).
3. Build entity lists per pillar; cross-check with Wikidata.
4. Audit existing site content; map old URLs to new clusters; plan redirects for retired pages (301 only).
5. Draft schema.org JSON-LD per page type; test with Rich Results Test.
6. Draft internal-link patch list: which existing pages must link to which new pillars/clusters.
7. Coordinate publication cadence with Polyhymnia's `editorial-calendar` so SEO content is also part of the content arc.
8. After publish: monitor SERP-feature acquisition, impressions, clicks, position; log to `eights.memory.remember(tags=["seo","cluster","serp"])`; quarterly refresh.

## Validation checklist

- [ ] Every pillar has 3-10 cluster pages mapped
- [ ] Every cluster page links to its pillar AND 2-4 siblings
- [ ] Every page has schema.org markup appropriate to its type, validated
- [ ] Every pillar has an entity glossary documented
- [ ] No two pages target the same primary keyword (cannibalization check)
- [ ] All redirects are 301; no chains; no loops
- [ ] FAQ schema used only where FAQs are visibly on the page (Google penalty risk otherwise)

## Failure modes / escalation

- **Cannibalization detected** — consolidate via 301; pick the stronger URL; do not run two competing pages.
- **Brand penalty / manual action** — pause SEO production; route to Calliope and `brand-safety`; remediate before continuing.
- **Schema validation fails** — fix before publish; rich results lost is worse than no rich results attempted.
- **Algorithm update tanks rankings** — wait 2-4 weeks before structural response; document hypothesis; recall similar past episodes.

## References

- Editorial cadence: `editorial-calendar` (Polyhymnia)
- Copy execution: `platform-voice` (Erato + Terpsichore)
- Memory tags: `seo`, `cluster`, `pillar`, `serp`, `entity`
