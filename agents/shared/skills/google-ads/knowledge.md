# Google Ads Knowledge Base

> Researched February 2026. If current date is 6+ months later, re-fetch key sources below for updated data before advising.

## 1. The Five Factors That Determine Keyword Value

No single metric determines whether a keyword is worth bidding on. Five factors interact:

### 1a. Search Intent (strongest predictor of conversion)

| Intent Type | Example | CPC | Conversion Potential |
|---|---|---|---|
| Transactional | "hire saxophonist for wedding" | Highest | Highest |
| Commercial investigation | "best wedding saxophonist Edinburgh reviews" | High | High |
| Navigational | "Jonny Diggens saxophonist" | Moderate | Moderate |
| Informational | "how much does a wedding saxophonist cost" | Lowest | Lowest |

52.65% of all searches are informational. Only ~14.5% are commercial/transactional. Bidding on informational keywords without a deliberate top-of-funnel strategy is the most common budget-wasting mistake.

Source: [HawkSEM — Search Intent](https://hawksem.com/blog/what-is-search-intent/), [Mat Nelson PPC — User Intent](https://www.matnelsonppc.com/blog/google-ads-user-intent-a-comprehensive-approach-to-campaign-optimization)

### 1b. Quality Score (biggest cost lever)

Google's 1–10 rating of keyword + ad + landing page alignment. Based on three components:
- Expected click-through rate
- Ad relevance
- Landing page experience

QS is NOT directly used in the auction, but the three underlying signals ARE used in real-time.

**CPC impact by Quality Score (WordStream, ~$100M in analysed spend):**

| QS | CPC vs Average (QS 5) | CPA vs Average |
|---|---|---|
| 10 | **−50%** (half price) | **−80%** |
| 8 | −37.5% | −48% |
| 6 | −16.7% | −16% |
| **5** | **Baseline** | **Baseline** |
| 4 | +25% | +16% |
| 2 | +150% | +48% |
| 1 | **+400%** (5× cost) | +64% |

A well-run account pays half what a poorly-run account pays for identical keywords. QS is the single biggest lever for reducing Google Ads costs.

Google's own statement: "Higher quality ads typically cost less per click than lower quality ads. If your ads are low quality, you may find that your actual CPC is close to your maximum CPC even when there is low competition."

Source: [WordStream — QS & Cost Per Conversion](https://www.wordstream.com/blog/ws/2013/07/16/quality-score-cost-per-conversion), [Google Ads Help — About Quality Score](https://support.google.com/google-ads/answer/6167118), [Google Ads Help — About Ad Quality](https://support.google.com/google-ads/answer/156066)

### 1c. Unit Economics (profitability filter)

A keyword is only worth bidding on if:

```
Max CPC = Booking value × Profit margin × Conversion rate
Break-even CPA = Booking value × Profit margin
Break-even ROAS = 1 / Profit margin
```

A £3 CPC that converts into a £400 booking is wildly profitable. A £0.50 CPC that never converts is waste. Cheap clicks are not inherently good; expensive clicks are not inherently bad.

Include ALL variable costs: payment processing (~2.9%), travel, materials — not just COGS.

Source: [Scott Redgate — Break-Even CPA](https://www.scottredgate.com/blog/google-ads-break-even-cpa-calculator), [Cometly — Break-Even ROAS](https://www.cometly.com/post/breakeven-roas-calculator)

### 1d. Search Volume (sufficient, not maximum)

Enough to generate meaningful traffic. High volume is not inherently better — it correlates with higher competition, higher cost, and often lower intent.

Multiple low-volume keywords collectively outperform a single high-volume keyword at lower cost. 70–90% of all searches are long-tail (3+ words).

Source: [Backlinko — Long-tail data](https://backlinko.com/), [SEER Interactive — Short vs Long Tail](https://www.seerinteractive.com/insights/short-tail-vs-long-tail-keywords)

### 1e. Competition

More advertisers bidding = higher CPC, generally. But:
- QS can offset competition dramatically (see 1b)
- Competition varies by geography (Edinburgh has more bidders than Aberdeen)
- Low competition does NOT guarantee low CPC — Google sets minimum Ad Rank thresholds regardless of competition

Source: [Google Ads Help — About Ad Rank](https://support.google.com/google-ads/answer/1722122), [DataForSEO — Competition](https://dataforseo.com/help-center/what-is-competition)

## 2. Long-Tail Keywords: The Data

| Metric | Short-tail (1–2 words) | Long-tail (3+ words) |
|---|---|---|
| Share of all searches | ~15% | 70–90% |
| Conversion rate | Baseline | **2.5–5× higher** |
| CPC | 50–75% higher | Significantly lower |
| Cost per conversion | 2×+ higher | Less than half |
| Bounce rate | Higher | **3.7× lower** |

WordStream paid search study: 90% of conversions came from queries with 1–100 clicks. The cost-per-conversion in the 6–99 click segment was less than half that of high-traffic competitive terms.

PPC Hero: ~1/3 of all conversions came from 4+ word terms. Over half of conversion volume came from long-tail. Diminishing returns after ~6 words / ~40 characters.

Source: [WordStream — Long-Tail Keywords](https://www.wordstream.com/long-tail-keywords), [PPC Hero — Long Tail Strategy](https://ppchero.com/a-long-tail-keywords-strategy-more-conversions-less-competition-in-google-ads/)

## 3. Match Types (2025–2026 State of Play)

Search Engine Land data across 7,000+ advertisers (June 2023–June 2025):
- Broad match CPCs rose 29%
- **Phrase match CPCs surged 43%**
- Close variants now cause phrase and exact to behave as broadly as broad match, but **without** the AI-driven relevance filtering that broad match gets

Expert consensus:
- **Exact match**: for control, especially at launch
- **Broad match + Smart Bidding**: for scale, after 30+ conversions/month. Broad match accesses AI signals (landing page content, user history, ad group context) unavailable to other match types
- **Phrase match**: declining value. Rising costs, degrading quality. Most experts predict phase-out within a few years. Skip it.
- **Negative keywords**: more important than ever. Up to 10,000 per campaign. Review search terms weekly.

**Never use broad match without Smart Bidding.** It's reckless without the AI relevance filter.

Source: [Search Engine Land — Phrase Match Losing Ground](https://searchengineland.com/phrase-match-losing-ground-broad-match-google-ads-458393), [WordStream — Future of Keywords: 6 Experts](https://www.wordstream.com/blog/2025-google-ads-keywords), [Google Ads Help — Match Options](https://support.google.com/google-ads/answer/7478529)

## 4. Location Strategy

### Separate campaigns per city, not one mega-campaign

Reasons:
- Independent budgets per city
- Tailored ad copy per location
- Clean per-city performance data
- Higher QS from city-matched keyword + ad + landing page
- **Smart Bidding ignores manual location bid adjustments** — making single-campaign geo-modifiers useless with automation

Source: [Google Ads Help — Geo-targeting](https://support.google.com/google-ads/answer/2404184?hl=en), [seoplus+ — Multi-Location PPC](https://seoplus.com/paid-ads/the-ultimate-guide-to-multi-location-ppc-advertising-on-google-ads/)

### "Presence" vs "Presence or Interest"

Google defaults to "Presence or Interest" — showing ads to people *in* your area AND people who've *shown interest* in it. For local services, switch to **"Presence" only** to avoid wasting budget on irrelevant out-of-area clicks.

Exception: wedding/tourism/event businesses benefit from a secondary campaign with national geo + location keywords to capture remote planners ("Edinburgh wedding photographer" searched from London). This is called **reverse location targeting**.

Source: [Search Engine Land — Reverse Location Targeting](https://searchengineland.com/reverse-location-targeting-google-ads-458080), [Arshinkov — Presence vs Interest](https://arshinkov.com/presence-vs-interest-the-google-ads-location-setting-you-should-not-ignore/)

### Budget allocation across cities

Start with population/search-volume weighting. After 4–8 weeks, shift aggressively based on actual conversion data. The 70/20/10 framework: 70% proven performers, 20% growth opportunities, 10% experiments.

Reverse-engineer budget per city:
```
Revenue goal / Average booking value = Required bookings
Required bookings / Conversion rate = Required leads
Required leads / Landing page CVR = Required clicks
Required clicks × Average CPC = Required budget
```

Source: [Lunio — Budget Allocation](https://www.lunio.ai/blog/google-budget-allocation), [Augurian — Google Ads Budget Guide](https://augurian.com/blog/google-ads-budget-allocation-guide/)

## 5. Bidding Strategy by Phase

| Phase | Strategy | When |
|---|---|---|
| Launch | Manual CPC or Maximise Clicks | First 30 conversions — maintain control |
| Optimisation | Maximise Conversions with Target CPA | After 30+ conversions — let algorithm optimise |
| Scale | Target ROAS | When tracking revenue per conversion accurately |

Advertisers switching from Target CPA to Target ROAS see ~14% more conversion value on average.

Source: [Google Ads Help — Bid Strategies](https://support.google.com/google-ads/answer/2472725), [Define Digital Academy — Bidding 2025](https://www.definedigitalacademy.com/blog/google-ads-bidding-strategies-in-2025-how-to-avoid-costly-mistakes-and-maximize-results)

## 6. Wedding/Local Service Benchmarks (UK, 2025–2026)

| Metric | Range |
|---|---|
| CPC (UK wedding keywords) | £0.80–3.50 |
| Cost per lead | £8–40 |
| Conversion rate (well-optimised) | 10–15% |
| ROAS (top performers) | 8–12× |
| ROAS (typical) | 2–4× |
| Recommended starting monthly spend | £300–1,000+ |

Case studies:
- London wedding photographer: £6/day, 96 leads/month, 15% CVR, 8–12× ROAS (AlxDoesDigital)
- Elopement photographer: 189% conversion increase, 50% CPA decrease (Succeeding Small)
- Wedding videographer from zero: $1,185/year total, 52 enquiries, 7 bookings (Book More Brides)
- Wedding venue: $3.71 CPL, 12.45% CVR (Snowmad Digital)

Key finding: it takes 3–6 months to optimise. First weeks are data gathering.

Source: [WordStream 2025 Benchmarks](https://www.wordstream.com/blog/2025-google-ads-benchmarks), [AlxDoesDigital — 96 Leads](https://alxdoesdigital.com/wedding-photography-96-leads), [Book More Brides — Google Ads](https://www.bookmorebrides.com/start-business-with-google-adwords/)

## 7. Common Mistakes (Ranked by Damage)

### Structural (most damaging)
1. **No clear goals before launch** — without target CPA/ROAS, you're "training Google's AI to waste your budget with maximum efficiency"
2. **Broken conversion tracking** — tracking wrong events corrupts Smart Bidding signals
3. **Keyword-ad-landing page misalignment** — tanks QS, inflates CPC

### Keyword selection
4. **Broad match without guardrails** — no negatives, no conversion data, no audience signals
5. **Neglecting negative keywords** — maintain 100+ minimum
6. **Ignoring search term reports** — review weekly, add converters as exact match, add junk as negatives
7. **Bidding on informational intent without strategy**

### Operational
8. **Accepting Google's auto-apply recommendations** — Google optimises for Google's revenue. Turn auto-apply off.
9. **"Set and forget" management** — keywords that were profitable last quarter may not be today
10. **Not understanding match type evolution** — exact match hasn't been truly exact since 2014

Source: [Search Engine Land — Top 10 Mistakes](https://searchengineland.com/google-ads-mistakes-avoid-449288), [WordStream — 7 Mistakes](https://www.wordstream.com/blog/ws/2022/03/07/google-ads-mistakes), [Zapier — 6 Mistakes](https://zapier.com/blog/google-ads-mistakes/)

## 8. The 4-Question Keyword Filter

For every keyword, ask:
1. **Would someone searching this actually buy what I sell?** (intent)
2. **Can I write an ad that directly answers this search?** (ad relevance → QS)
3. **Does my landing page match this search?** (landing page experience → QS)
4. **At this CPC and estimated conversion rate, is the cost per booking acceptable?** (profitability)

Pass all four → bid. Fail any one → skip.

## 9. Keyword Research Methodology

### Step 1: Google Keyword Planner (free with Google Ads account)
- "Discover new keywords" with seed phrases, per city
- "Start with a website" with competitor URLs
- Source of truth for volume, competition, suggested bid

### Step 2: Google autocomplete + "People also ask"
- Incognito browser, type seed phrases, screenshot suggestions
- These are real searches with real volume
- Free, no API needed. Automatable via `https://suggestqueries.google.com/complete/search?q=...&client=firefox`

### Step 3: Google Trends (free)
- Compare term variants ("saxophonist" vs "sax player")
- Check seasonality (wedding searches peak Jan–Mar)
- Compare regional interest

### Step 4: Google Search Console (free, if site is connected)
- Shows exact queries already bringing organic traffic
- Bid on terms not ranking well organically

### Step 5: Competitor ad spy
- Search target keywords manually, note who's advertising, their copy, their landing pages
- Or use SerpAPI ($50/mo) for automated competitor intelligence

Source: [Google Keyword Planner Help](https://support.google.com/google-ads/answer/3022575), [Google Trends](https://trends.google.com)

## 10. Key Sources for Re-Fetching

When this knowledge base is stale, re-fetch these for updated data:

| Topic | URL |
|---|---|
| Industry benchmarks (CPC, CVR, CPA) | https://www.wordstream.com/blog/2025-google-ads-benchmarks |
| Quality Score impact data | https://www.wordstream.com/blog/ws/2013/07/16/quality-score-cost-per-conversion |
| Match type trends | https://searchengineland.com/phrase-match-losing-ground-broad-match-google-ads-458393 |
| Keyword expert predictions | https://www.wordstream.com/blog/2025-google-ads-keywords |
| Google's own bidding docs | https://support.google.com/google-ads/answer/2472725 |
| Google's QS documentation | https://support.google.com/google-ads/answer/6167118 |
| Google's geo-targeting docs | https://support.google.com/google-ads/answer/2404184 |
| Long-tail keyword data | https://www.wordstream.com/long-tail-keywords |
| Wedding vendor case studies | https://alxdoesdigital.com/wedding-photography-96-leads |
| Common PPC mistakes | https://searchengineland.com/google-ads-mistakes-avoid-449288 |
