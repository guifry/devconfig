---
name: ads-keywords
description: "Research and evaluate Google Ads keywords. Generates seed keywords by intent tier, applies the 4-question profitability filter, produces negative keyword lists, and provides a validation workflow using free tools."
---

# Google Ads Keyword Research

## Pre-requisite

Read `~/.claude/skills/google-ads/knowledge.md` in full before doing anything. Pay special attention to sections 2 (long-tail data), 3 (match types), 8 (4-question filter), and 9 (research methodology).

If the current date is 6+ months after the research date, re-fetch the long-tail keyword data URL and match type trends URL from section 10.

## Gather inputs

If not already known from context, ask:
- Business description and services offered
- All locations served
- Average booking value and profit margin (needed for max CPC calculation)
- Existing keyword lists (if any, to build on)
- Landing pages available (needed for the 4-question filter)

## Phase 1: Generate seed keywords

For each service × location combination, produce:

### Transactional intent seeds (highest priority)
Keywords where the searcher is ready to buy/book. Pattern: `[action] + [service] + [location]`
- "hire saxophonist edinburgh"
- "book wedding band glasgow"
- "corporate entertainment edinburgh"

### Commercial investigation seeds (second priority)
Keywords where the searcher is comparing options. Pattern: `[best/top/reviews] + [service] + [location]`
- "best wedding saxophonist edinburgh"
- "wedding musician reviews scotland"

### Long-tail variants (high priority — reference section 2 data)
4–6 word phrases with strong intent. Pattern: `[service] + [for] + [event type] + [location]`
- "live saxophonist for wedding reception edinburgh"
- "saxophone player for corporate awards dinner"

### Informational seeds (low priority — flag as top-of-funnel only)
- "how much does a wedding saxophonist cost"
- "what to expect from live saxophone at wedding"

Mark these clearly as informational. Only bid if there's a deliberate awareness strategy.

## Phase 2: Apply the 4-question filter

For each keyword, evaluate:
1. **Would someone searching this actually book?** → Keep only if yes
2. **Can we write an ad that directly answers this search?** → If not, the keyword is too generic
3. **Does the landing page match?** → Map each keyword to a specific landing page
4. **At estimated CPC and conversion rate, is cost per booking acceptable?** → Calculate: `estimated CPC / estimated CVR = estimated CPA`. Compare to break-even CPA.

Remove any keyword that fails a filter. Flag borderline cases.

## Phase 3: Negative keywords

Generate a comprehensive negative keyword list:

### Universal negatives (apply to all campaigns)
- Learning/education: lessons, tutorial, how to play, learn, course, beginner, school
- Free content: free, download, mp3, spotify, youtube, backing track, karaoke
- Employment: salary, job, vacancy, career, hiring
- Equipment: reed, mouthpiece, fingering, sheet music
- Budget signals: cheap, budget, DIY, free

### Industry-specific negatives
Based on the business type, add negatives that would attract wrong-intent clicks.

### Location negatives (if relevant)
Exclude locations outside the service area.

Aim for 100+ negative keywords minimum. Reference knowledge base section 7 — neglecting negatives is a top-5 mistake.

## Phase 4: Organisation

Present keywords in a structured table:

| Keyword | Intent Tier | Match Type | Est. Volume | Est. CPC | Target Landing Page | City Campaign |
|---|---|---|---|---|---|---|

Group by city campaign → ad group (service type).

## Phase 5: Validation workflow

Give the user a step-by-step guide to validate these keywords using free tools:

### Google Keyword Planner
1. Go to Tools → Keyword Planner → "Discover new keywords"
2. Enter the seed phrases from Phase 1
3. Set location to [specific city]
4. Sort results by: Avg. monthly searches, then Competition, then Suggested bid
5. For each keyword, record: volume, competition level, suggested bid range
6. Also try: "Start with a website" → enter 2–3 competitor URLs

### Google Keyword Planner — per-city comparison
Run the same seeds with location set to each target city separately. Note differences in volume and CPC — these determine budget allocation.

### Google autocomplete
Open incognito browser. Type each seed phrase partially. Screenshot/record all suggestions. These are real searches.

### Google Trends
Compare term variants: e.g. "saxophonist" vs "sax player" vs "saxophone player". Check which is more common in each target region. Check seasonality.

### Search term review (post-launch)
After 1–2 weeks of running ads: go to Keywords → Search Terms report. This shows actual queries. Add high-converters as exact match. Add irrelevant terms as negatives. This is the most valuable data source — review weekly.

## Output format

Produce:
1. Keyword lists per campaign (city) and ad group (service), with intent tier and recommended match type
2. Negative keyword list (100+ terms)
3. Keyword-to-landing-page mapping
4. Validation workflow checklist
5. Seasonal notes (if relevant — e.g. wedding booking peaks Jan–Mar)

Context: $ARGUMENTS
