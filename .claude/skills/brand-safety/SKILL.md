---
name: brand-safety
description: "IP clearance checklist and brand-guardrail rubric. Owned by governance-c2pa, consumed by Calliope and Helios."
user-invocable: false
argument-hint: "<ip-check|guardrail-check|escalate>"
allowed-tools:
  - Read
  - Grep
---

# Brand Safety

The defensive layer. Every asset and every copy block passes through this skill before it can be marked `approved`.

## Purpose

Prevent IP infringement, brand-voice violations, and reputational risk from leaving the studio. The skill produces a `brand_safety_review` artifact that gates publish.

## When to use

- governance-c2pa runs this on every `AssetJob` output before signing.
- Calliope runs this at brief-intake when `risk_tolerance == "low"`.
- Helios runs this on any third-party reference (mood-board, stock plate, talent photo) before incorporating it into a generation prompt.
- Erato/Terpsichore run this on copy that names a competitor or quotes a third party.

## Inputs

- Asset file path OR copy block text
- `brand_constraints` from the active `CreativeBrief`
- Optional: source-of-record for third-party material (URL, license, talent release on file)

## Outputs

- `brand_safety_review.json` with: `verdict` (`pass`|`fail`|`hitl`), `ip_findings[]`, `guardrail_findings[]`, `recommendations[]`
- Episode written to `eights.memory.remember(domain="creative", scopes=["sensitive:ip"], tags=["governance"])`

## Sources of IP risk

1. **Stock imagery / video** — license tier (editorial vs commercial), model release on file, geographic restrictions, duration-of-use clause.
2. **Brand likeness** — third-party logos, trade dress, distinctive product silhouettes (a Coke bottle, a Birkin bag, an Apple device chassis).
3. **Music samples** — sync license, master + publishing both cleared, AI-generated tracks need provenance for training-data risk.
4. **Talent rights** — name/image/likeness, voice clones, deepfakes, deceased-celebrity rights of publicity.
5. **Trademarks** — competitor marks, slogans, registered taglines, sound marks (the NBC chime, the Intel bong).
6. **Architectural / location** — recognizable landmarks with trademark protection (Hollywood sign, Eiffel Tower at night).
7. **Generative model provenance** — was the base model trained on opted-out data? Does the workflow include `ip-adapter` referencing a copyrighted character?

## IP clearance checklist

- [ ] Every external asset has a license file or URL on record
- [ ] License tier matches intended use (editorial / commercial / broadcast / paid)
- [ ] All identifiable humans have a model release OR are clearly de-identified
- [ ] No third-party logos, marks, or trade-dress in frame unless authorized
- [ ] No music cue used without sync + master clearance
- [ ] No AI-generated likeness of a real person without written consent
- [ ] No reference image fed to `ip-adapter` or `controlnet` is a copyrighted character or celebrity
- [ ] C2PA manifest will be attached on sign-off

## Brand-guardrail rubric

Score each dimension 0-3 (0 = violation, 3 = exemplary). Asset passes only if all dimensions >= 2.

| Dimension | 0 (fail) | 2 (acceptable) | 3 (exemplary) |
|---|---|---|---|
| Voice match | Off-brand register | Matches voice rubric | Captures voice with distinctive flourish |
| Tone fit | Inappropriate for moment | Tone-appropriate | Tone-appropriate AND emotionally resonant |
| Taboo topics | Mentions a taboo topic | Avoids taboo list | Avoids AND proactively reframes risky adjacencies |
| Competitor mentions | Names competitor without authorization | No competitor mentions | No mention AND no implicit shade |
| Inclusivity | Excludes or stereotypes audience segments | Neutral / inclusive | Actively representative without tokenism |
| Factual accuracy | Contains false claim | Verifiable claims only | Verifiable AND cited |
| Legal claims | Makes regulated claim without disclaimer | No regulated claims | No claims AND has counsel-approved disclaimer where needed |

## Procedure

1. Load the asset or copy block and the active `CreativeBrief.brand_constraints`.
2. Run the IP clearance checklist. Any unchecked box -> `verdict = hitl` unless explicitly waived in brief.
3. Run the brand-guardrail rubric. Any dimension scoring 0 -> `verdict = fail`. Any scoring 1 -> `verdict = hitl`.
4. Run automated checks: regex sweep for taboo terms; OCR/transcript sweep for visible/audible competitor names; reverse-image search for stock provenance when license is missing.
5. Write `brand_safety_review.json` to `RLM/output/governance/{asset_id}-{date}.json`.
6. If `verdict != pass`, file a `DecisionRecord` with `dissenting_opinions` populated and trigger HITL.

## When to escalate to HITL

- Any IP-clearance checkbox cannot be confirmed and `risk_tolerance != "high"`
- Any guardrail dimension scores 0 or 1
- Asset features a real person's likeness AND release-on-file status is `unknown`
- Copy makes a regulated claim (health, finance, safety) without counsel-approved disclaimer
- Conflicting constraints in the brief that the rubric cannot resolve
- ANY use of a deceased celebrity's name/voice/image

## Failure modes / escalation

- **Reference image is a copyrighted character** — strip from prompt, regenerate, log episode tagged `governance`.
- **License file missing** — set `verdict = hitl`; do NOT publish; ping Calliope.
- **Voice rubric score conflicts between governance-c2pa and Erato** — `DecisionRecord` with both opinions; HITL adjudicates.

## References

- Constitution: `RLM/specs/creative-constitution.md`
- C2PA signing: `governance-c2pa` sub-agent
- Memory tags: `governance`, `sensitive:ip`
