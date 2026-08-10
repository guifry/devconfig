---
name: ads-plan
description: "Create a full Google Ads campaign strategy from scratch. Covers unit economics, campaign structure, budget allocation, bidding, match types, geo-targeting, and pre-launch checklist."
---

# Google Ads Campaign Planner

## Pre-requisite

Read `~/.claude/skills/google-ads/knowledge.md` in full before doing anything. If the current date is 6+ months after the research date at the top of that file, re-fetch the WordStream benchmarks URL and Google's bidding docs URL listed in section 10 to check for updated data.

## Gather inputs

If not already known from context, ask the user for:
- Business description (service/product, differentiators)
- Average booking/order value and profit margin
- Locations served (cities, radius)
- Target customer segments (e.g. weddings, corporate, private)
- Monthly budget range
- Whether they have an existing Google Ads account or are starting fresh
- Whether conversion tracking is set up
- Landing pages available (URLs or descriptions)

## Produce the strategy

Generate a complete strategy document covering:

### 1. Unit Economics
- Calculate break-even CPA: `booking value × profit margin`
- Calculate break-even ROAS: `1 / profit margin`
- Calculate max CPC: `booking value × profit margin × estimated conversion rate`
- State the target CPA/ROAS (break-even + 20–30% buffer)

### 2. Campaign Structure
- One campaign per city/location (reference knowledge base section 4 for why)
- Within each city campaign: one ad group per service/customer segment
- Explain the structure visually (tree format)
- If applicable: propose a reverse location targeting campaign for remote searchers (weddings, tourism, destination events)

### 3. Budget Allocation
- Per-city allocation based on estimated search volume and competition
- Use the reverse-engineering formula from the knowledge base: revenue goal → bookings → leads → clicks → budget
- Apply the 70/20/10 framework: proven/growth/experiment
- State the recommended starting daily budget per campaign

### 4. Bidding Strategy
- Phase 1 (launch): Manual CPC or Maximise Clicks
- Phase 2 (after 30 conversions): Target CPA
- Phase 3 (mature): Target ROAS if tracking revenue
- Explain the 30-conversion threshold and why

### 5. Match Type Strategy
- Exact match only at launch
- Test broad match + Smart Bidding after 30+ conversions/month
- Skip phrase match (reference the 43% CPC inflation data)
- Negative keywords from day one

### 6. Conversion Tracking Requirements
- What to track (form submissions, phone calls, bookings)
- Where to place tags (thank-you page, GA4 events)
- Why this is non-negotiable for Smart Bidding

### 7. Geo-Targeting Settings
- "Presence" only (not "Presence or Interest") for local campaigns
- Radius or city-level targeting per campaign
- Reverse targeting setup if applicable

### 8. Timeline & Expectations
- Weeks 1–2: data gathering, expect limited conversions
- Weeks 3–4: first optimisation pass (search terms, negatives, ad copy)
- Months 2–3: enough data for Smart Bidding transition
- Months 3–6: full optimisation, scaling profitable campaigns

### 9. Pre-Launch Checklist
- [ ] Google Ads account created
- [ ] Conversion tracking verified
- [ ] Campaigns structured (per city × per service)
- [ ] Keywords added (exact match)
- [ ] Negative keyword list applied (100+ minimum)
- [ ] Ad copy written with extensions
- [ ] Landing pages verified (one per campaign)
- [ ] "Presence" targeting set
- [ ] Auto-apply recommendations turned OFF
- [ ] Daily budgets set
- [ ] Manual CPC bidding selected

### 10. Risks & Mistakes to Avoid
- Reference the common mistakes from knowledge base section 7
- Flag any business-specific risks

## Format

Output as a clean markdown document the user can save and reference. Use tables where appropriate. Be precise and data-backed, referencing the knowledge base.

Context: $ARGUMENTS
