---
name: ads-expert
description: "Google Ads expert knowledge. Activates when the user discusses Google Ads strategy, keywords, bidding, campaigns, or PPC marketing. Loads the researched knowledge base covering the 5-factor keyword model, Quality Score economics, match types, location strategy, and common mistakes."
user-invocable: false
---

# Google Ads Expert — Background Knowledge

## Step 1: Load the knowledge base

Read the file `~/.claude/skills/google-ads/knowledge.md` in full. This is a researched, source-backed reference covering:

- The 5-factor keyword valuation model (intent, QS, unit economics, volume, competition)
- Quality Score CPC impact data (QS 10 = −50% CPC, QS 1 = +400%)
- Long-tail keyword conversion data (2.5–5× higher CVR, half the CPC)
- Match type state of play (2025–2026: exact + broad, skip phrase)
- Location strategy (campaign-per-city, reverse targeting)
- Bidding strategy by phase (manual CPC → target CPA → target ROAS)
- Wedding/local service benchmarks (UK CPCs, CVRs, case studies)
- Common mistakes ranked by damage
- Keyword research methodology (free tools)
- Key source URLs for re-fetching when data is stale

Absorb all of it. This is the foundation for all Google Ads advice.

## Step 2: Check staleness

Look at the research date at the top of the knowledge base. If the current date is more than 6 months after that date, fetch these URLs from section 10 of the knowledge file to check for updates:
- WordStream benchmarks URL (CPC, CVR, CPA data changes yearly)
- Search Engine Land match type article (match types are actively evolving)
- Google's own bidding and QS documentation (Google updates these)

Report any significant changes to the user.

## Step 3: Apply knowledge

When advising on Google Ads:
- Never recommend a keyword strategy without grounding it in the 4-question filter (section 8: intent, ad relevance, landing page match, profitability)
- Always calculate break-even CPA/ROAS before recommending budget or bids
- Default to exact match at launch, broad match + Smart Bidding after 30 conversions
- Skip phrase match unless the user has a specific reason
- Recommend separate campaigns per city, never one mega-campaign with bid modifiers
- Flag common mistakes proactively (auto-apply recommendations, missing negatives, broken tracking)
- When uncertain about current Google Ads features or benchmarks, fetch the relevant source URL from section 10 rather than guessing

## Available action skills

If the user needs a structured workflow, these skills are available:
- `/ads-plan` — full campaign strategy from scratch
- `/ads-keywords` — keyword research and evaluation
- `/ads-copy` — ad copy, headlines, extensions
- `/ads-audit` — campaign performance review
