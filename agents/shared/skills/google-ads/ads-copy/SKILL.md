---
name: ads-copy
description: "Write Google Ads copy — responsive search ad headlines, descriptions, extensions, seasonal variants. Uses psychological principles (authority, social proof, scarcity) and optimises for Quality Score."
---

# Google Ads Copy Writer

## Pre-requisite

Read `~/.claude/skills/google-ads/knowledge.md` in full before doing anything. Pay special attention to sections 1b (Quality Score — ad relevance is a direct QS component), 6 (benchmarks for what converts), and 7 (keyword-ad-landing page alignment as structural requirement).

## Gather inputs

If not already known from context, ask:
- Campaign and ad group details (which city, which service)
- Target keywords for each ad group
- Landing page URL or description
- Business differentiators (awards, experience, notable clients, credentials)
- Testimonials or review quotes available
- Current availability / scarcity signals (e.g. "Only 4 Saturdays left for summer")
- Price points (if used in ads)

## Responsive Search Ad structure

Google Ads uses Responsive Search Ads (RSAs): up to 15 headlines (30 chars each) and 4 descriptions (90 chars each). Google mixes and matches them.

### Headlines (generate 15 per ad group)

Organise into categories:

**Authority headlines (3–4):**
Use the strongest credibility signals. These create pattern interrupts — they elevate above generic competitor ads.
- "Performed at Royal Events"
- "13 Years' Professional Experience"
- "As Featured on BBC / ITV" (if true)

**Social proof headlines (3–4):**
Specific numbers outperform vague claims. "1000+ Events" beats "Experienced Musician."
- "1000+ Events Worldwide"
- "200+ Five-Star Reviews"
- "Trusted by [Notable Client]"

**Scarcity headlines (2–3):**
Must be honest and time-bound. Update monthly.
- "Limited Summer 2026 Dates"
- "Only 4 Saturdays Left in June"
- "Book Early — Peak Season Filling"

**Location/service match headlines (3–4):**
These directly match the search query, boosting expected CTR (QS component). Matching text appears **bold** in the ad.
- "Wedding Saxophonist Edinburgh"
- "Corporate Entertainment Glasgow"
- "[Service] in [City]"

**CTA headlines (1–2):**
- "Get a Free Quote Today"
- "Check Availability Now"

### Descriptions (generate 4 per ad group)

Each description should combine multiple persuasion elements:

**Description 1 — Value stack:**
List what's included. Make the offer tangible.
"Live saxophone for ceremony, drinks & evening party. PA system included. DJ integration. No hidden fees."

**Description 2 — Authority + social proof:**
"13 years, 1000+ events. Performed for royalty, praised by Kenny G. Scotland's most in-demand saxophonist."

**Description 3 — Location-specific + trust:**
"Edinburgh-based, regularly performing in [City]. Full insurance, professional PA, wireless performance."

**Description 4 — CTA + urgency:**
"Popular dates book fast. Get a personalised quote within 24 hours. No obligation."

### Pinning strategy

Pin only when necessary:
- Pin one keyword-matching headline to position 1 (ensures relevance)
- Pin one CTA headline to position 3
- Let Google rotate everything else — it optimises combinations better than humans

## Ad Extensions

Generate all applicable extensions:

**Sitelinks (4–6):**
Link to specific pages. Each sitelink should match a likely user interest.
- Weddings | Corporate Events | Private Parties | Reviews | Contact | About

**Callouts (4–6):**
Short benefit phrases, no links.
- "No Travel Fee (Edinburgh)" | "13 Years' Experience" | "PA Included" | "Fully Insured" | "DJ Integration" | "Wireless Performance"

**Structured snippets:**
- Event types: Weddings, Corporate, Birthdays, Restaurants, Festivals
- Service catalogue: Ceremony, Drinks Reception, Evening Party, DJ Integration

**Call extension:** Phone number for direct calls (if available)
**Location extension:** Add once Google Business Profile is live

## Seasonal copy variants

Reference knowledge base section 6 benchmarks — wedding searches have strong seasonality.

| Period | Buyer psychology | Copy emphasis |
|---|---|---|
| Jan–Mar | Planners booking ahead | Trust: credentials, video, testimonials. "Book Your 2026 Wedding Entertainment" |
| Apr–Jun | Late bookers, some urgency | Availability: "Still Available for Summer". Speed: "Quote Within 2 Hours" |
| Jul–Sep | Peak season, last-minute | Scarcity: "Limited Autumn Dates". Social proof from recent events. |
| Oct–Dec | Corporate season + early 2027 planners | Corporate messaging. "Book Your 2027 Wedding Now" |

Generate variant headlines/descriptions for each season. Advise the user to rotate quarterly.

## Landing page alignment check

For each ad group, verify:
1. **Headline match**: Does the landing page H1 contain the same service + city as the ad? If not, QS will suffer.
2. **Value stack present**: Does the page list what's included? (section, not just a paragraph)
3. **Social proof visible**: Testimonials above the fold?
4. **Form length**: 5 fields maximum. Every extra field drops CVR 10–15%.
5. **Mobile experience**: Page loads fast, form is easy to tap, CTA is visible without scrolling.

If any check fails, flag it and recommend specific fixes. Landing page experience is 1/3 of Quality Score.

## Thank-you page recommendations

After form submission, the thank-you page should:
1. Show a 30–60 second performance video
2. Display 2 testimonials relevant to the event type
3. State response time: "I'll reply within 24 hours with a personalised quote"
4. Include social links for further proof

This page continues selling while the business owner responds. Reference the wedding vendor case studies — this converts warm leads to bookings.

## Output format

For each ad group, produce:
1. 15 headlines with category labels
2. 4 descriptions
3. Pinning recommendations
4. Full extension set
5. Seasonal variant notes
6. Landing page alignment audit results
7. Thank-you page recommendations (if not already implemented)

Context: $ARGUMENTS
