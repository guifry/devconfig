---
name: ads-audit
description: "Audit a running Google Ads campaign. Diagnoses Quality Score issues, evaluates keyword profitability, reviews search terms, recommends budget reallocation, checks for common mistakes, and produces a prioritised action list."
---

# Google Ads Campaign Audit

## Pre-requisite

Read `~/.claude/skills/google-ads/knowledge.md` in full before doing anything. This audit framework is grounded in the research data within that file.

If the current date is 6+ months after the knowledge base research date, re-fetch these URLs from section 10 before advising:
- WordStream benchmarks (CPC, CVR, CPA data changes yearly)
- Google's QS documentation (Google updates scoring factors)
- Match type trends (match types are actively evolving)

## Gather inputs

Ask the user for as much of the following as available:
- Campaign structure (campaigns, ad groups, locations)
- Time period being reviewed
- Key metrics: impressions, clicks, CTR, CPC, conversions, CVR, CPA, ROAS
- Quality Score data per keyword (if available)
- Search terms report (or a summary of problematic terms)
- Current bid strategy
- Current match types in use
- Monthly budget and spend
- Business targets: target CPA, target ROAS, or revenue goal
- Any known issues or concerns

If the user can export data, accept CSV/spreadsheet data and parse it.

## Audit framework

### 1. Goal alignment check

Before looking at any metrics, verify:
- Does the account have a defined target CPA or ROAS?
- Is conversion tracking working correctly? (What action is being tracked? Is it the right action?)
- Are auto-apply recommendations turned off?

If any of these are wrong, flag as **critical** — nothing else matters until these are fixed. Reference knowledge base section 7: these are the top-3 most damaging structural mistakes.

### 2. Quality Score diagnosis

Reference the QS→CPC impact table in knowledge base section 1b.

For each keyword with QS data:
- **QS 7–10**: healthy. Low priority for optimisation.
- **QS 5–6**: average. Check which component is "below average" (expected CTR, ad relevance, or landing page experience). Prioritise the weakest component.
- **QS 1–4**: urgent. These keywords are paying 25–400% more than necessary. Either fix the alignment (ad copy, landing page) or pause the keyword.

Provide specific recommendations per component:
- **Expected CTR below average**: ad copy isn't compelling enough. Review headlines for authority/social proof signals. Test new variants.
- **Ad relevance below average**: keyword doesn't match the ad closely enough. Tighten ad group theming — move the keyword to a more specific ad group or write keyword-matched headlines.
- **Landing page below average**: the page doesn't match the search intent. Check H1 match, load speed, mobile experience, content relevance.

### 3. Keyword efficiency analysis

For each keyword, calculate:
- CPA = spend / conversions
- Compare CPA to the business's break-even CPA (from knowledge base section 1c formula)
- If tracking revenue: ROAS = revenue / spend. Compare to break-even ROAS.

Categorise keywords:

| Category | Criteria | Action |
|---|---|---|
| **Stars** | CPA well below break-even, good volume | Increase bids/budget. These are your winners. |
| **Performers** | CPA near break-even, decent volume | Maintain. Optimise QS to improve margins. |
| **Question marks** | Low volume, insufficient data to judge | Keep running for data. Review in 2 weeks. |
| **Losers** | CPA well above break-even, sufficient data | Pause or reduce bids. Don't throw good money after bad. |
| **Zombies** | No impressions or clicks | Check match type, bid, and QS. Either increase bid or remove. |

Flag statistical significance: a keyword with 5 clicks and 0 conversions is not necessarily bad — it's just insufficient data. Rule of thumb: need 100+ clicks before making conversion-rate judgements.

### 4. Search terms review

If the user provides search terms data:
- Identify high-converting search terms not yet added as keywords → recommend adding as exact match
- Identify irrelevant search terms → recommend adding as negative keywords
- Check for informational queries triggering ads → add as negatives unless there's a top-of-funnel strategy
- Estimate wasted spend on irrelevant terms

If no search terms data: remind the user this is the most important regular review task. Instruct them to export it from Google Ads → Keywords → Search Terms.

### 5. Match type assessment

Reference knowledge base section 3.

- If using phrase match: check CPC trend. If rising without conversion improvement, recommend testing exact match replacements.
- If using broad match without Smart Bidding: flag as high risk. Recommend switching to exact match or enabling Smart Bidding.
- If conversion volume is 30+/month and still on manual CPC: recommend testing broad match + Target CPA.
- If conversion volume is <30/month: stay on exact match + manual CPC. Not enough data for automation.

### 6. Budget reallocation

Compare performance across campaigns (cities) and ad groups (services):

| Campaign | Spend | Conversions | CPA | ROAS | Recommendation |
|---|---|---|---|---|---|

Apply the 70/20/10 framework:
- 70% to proven performers (best CPA/ROAS)
- 20% to promising campaigns that need more data
- 10% to experimental campaigns or new locations

Flag any campaign where impression share is very low (<20%) — this means budget is too thin to compete. Either increase budget or narrow keyword set.

### 7. Seasonal check

Reference knowledge base section 6 benchmarks.

- Is the current season aligned with ad copy? (e.g. are "Book your summer wedding" ads still running in October?)
- Are budgets adjusted for seasonality? (Wedding searches peak Jan–Mar)
- Is scarcity messaging up to date? (Dates/months mentioned in ads must be current)

### 8. Retargeting health check

- Is a remarketing audience set up? (All page visitors who didn't convert)
- If running: check frequency cap (max 3/day recommended), creative freshness, spend level
- If not running: recommend setup. Previous visitors convert at ~70% higher rate.

### 9. Follow-up process check

Beyond the ad platform:
- Is there a follow-up email sequence for enquiries? (Day 0: quote, Day 3: video, Day 7: check-in, Day 14: scarcity)
- What's the average response time to enquiries?
- What's the enquiry-to-booking close rate?

If close rate is low, the problem may not be the ads — it may be the follow-up.

### 10. Mistakes checklist

Run through knowledge base section 7. For each common mistake, check whether the account is committing it:

- [ ] Clear target CPA/ROAS defined
- [ ] Conversion tracking verified and correct
- [ ] Keyword-ad-landing page alignment per ad group
- [ ] No unconstrained broad match
- [ ] 100+ negative keywords
- [ ] Search terms reviewed in last 7 days
- [ ] No informational keywords without strategy
- [ ] Auto-apply recommendations OFF
- [ ] Active management (not "set and forget")
- [ ] Match type understanding current

## Output format

Produce a structured audit report:

1. **Executive summary**: 3–5 bullet points, most critical findings
2. **Critical issues** (fix immediately): anything that's actively wasting money
3. **Optimisation opportunities** (improve this week): QS improvements, keyword changes, budget shifts
4. **Monitoring items** (review next week): insufficient data, tests to continue
5. **Action checklist**: numbered, prioritised list of specific changes to make

Be specific. "Pause keyword X" not "consider reviewing keywords." "Add 'lessons' as negative" not "review negative keywords." Actionable > advisory.

Context: $ARGUMENTS
