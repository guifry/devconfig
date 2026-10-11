---
name: property-research
description: Research live property listings for a move or purchase. Screens commutable areas by budget, schools and safety, finds current listings with photos, and outputs a comparison HTML page. Use when the user asks where they can afford to live, wants house options near a city, or asks to research listings.
---

# Property Research

Turn a one-line brief ("4-bed house with garden, ≤40 min from Edinburgh, £250k") into screened areas plus live listings with photos, as an HTML page.

Server-side web tools are unaffected by anything blocking sites in the user's browser, so listings are reachable even when the user's own machine cannot open them.

## Inputs

Get these before searching. Infer sensible defaults and state them if the user omits any:

- **Anchor** — city/area and the point commuters travel to (e.g. Edinburgh city centre).
- **Budget** — max price. Ask for a stretch figure too; run both tiers when given (the £250k vs £400k tier is a different property class).
- **Min bedrooms**, **property type** (house vs flat, terrace/semi/detached).
- **Must-haves** — garden, garage, parking, condition (turnkey vs project).
- **Hard limits** — max commute, must-avoid areas, schools priority (primary/secondary age).

## Workflow

1. **Belt and tier.** Find the commuter towns/suburbs within the commute limit. Use rail time to the anchor as the reliable metric (drive times are traffic-dependent). Note the budget tier: cheap belts (ex-mining/new-town) vs desirable towns with top schools vs city fringe. Establish what the budget buys in each — that's the core answer.
2. **Screen areas.** For each candidate: train time, school results (secondary exam % five-Highers in Scotland), and safety (flag known rough estates, not whole towns). Drop the ones that fail a limit.
3. **Find listings.** Search per area, gather 2–4 current options each, prefer ones matching the must-haves. Record price, beds, type, garden, condition, school catchment, commute, and **status** (available / under offer / SSTC / off market).
4. **Capture photos.** For each listing fetch the page and read `og:image`; where a gallery is present, take the first image or a couple.
5. **Output.** Write the HTML page (below) and open it with `open`. Then summarise: best value/quality picks, trade-offs, and the handful of listings to see.

## Area screening sources

- **Commute/sold prices (Scotland)** — sold prices are Registers of Scotland / ESPC, not HM Land Registry. Average prices from ESPC or commuter-town guides; rail times from ScotRail.
- **Schools** — newspaper league tables (Scotsman "Top <council> High Schools <year>", Sunday Times), `schoolatlas.co.uk`, `datamap-scotland.co.uk`. Report the share achieving five Highers.
- **Safety** — Police Scotland / Scottish Government data (`datamap-scotland.co.uk`), local-press reporting on anti-social behaviour. Flag specific estates within a town; do not write off a whole town from one article.

## Listing sources and quirks

- **Work when fetched server-side**: OnTheMarket, home.co.uk, Zoopla, onedome, McEwan Fraser, RE/MAX (`remax-scotland.homes`, images on `property.eacdn.co.uk`), Malcolm Jack, ESPC (sometimes), estate-agent sites on the EstateApps platform.
- **Usually blocked to fetchers**: Rightmove (transport error), Redfin (405), some agents (e.g. Northwood). Do not keep retrying — fall back to search-result snippets, or show a placeholder card with the link.
- **Images**:
  - Any page: `og:image` in the `<head>`.
  - OnTheMarket: `https://media.onthemarket.com/properties/<id>/<timestamp>/image-N-1024x1024.jpg` (`<timestamp>` comes from the `og:image`).
  - home.co.uk: `https://cdn.home.co.uk/listing-images/...` array in the page's schema.org JSON.
  - Zoopla: `https://lid.zoocdn.com/645/430/<hash>.jpg`.
  - McEwan Fraser / imgix: `mcewanfraserlegal.imgix.net/property-images/<ref>_111.jpg`.
- Add `referrerpolicy="no-referrer"` and `loading="lazy"` to hotlinked `<img>` tags so hotlink protection is less likely to break them.

## Output HTML

Single self-contained file (inline CSS, no build step), one `<section>` per area, a responsive card grid. Each card: photo (or a labelled placeholder), price badge, status badge (available / under-offer / off-market colour-coded), address, beds/type, garden, school, commute tags, and a listing link. Add a status key and a "verify availability" note at the top. Write to `~/<area>-property-options.html` and `open` it.

Card shape:

```html
<article class="card">
  <div class="thumb"><span class="price">£245,000</span><span class="status ok">available</span>
    <img src="<og:image>" alt="<address>" referrerpolicy="no-referrer" loading="lazy">
  </div>
  <div class="body">
    <div class="addr">Address (postcode)</div>
    <div class="facts"><b>4-bed semi</b> · garden, garage · condition</div>
    <div><span class="tag">School</span><span class="tag">Commute</span></div>
    <a class="link" href="<listing-url>" target="_blank" rel="noopener">View listing →</a>
  </div>
</article>
```

## Reusing the skill

Invoke with the brief, e.g.:

```text
Use the property-research skill. Up to £400k, 4+ bed house with a garden,
house not flat, max 40 min to Edinburgh centre, good schools, non-dodgy areas.
```

Vary the anchor, budget and commute limit for any city. Keep sold-price and school sources matched to the country (Registers of Scotland in Scotland; HM Land Registry in England/Wales).

## Notes for future runs

- Always confirm listing status — the belt moves fast and many options end up SSTC/off market between runs.
- When showing two budget tiers, make the delta explicit: it is usually the jump from terrace/semi-doer-upper to detached-move-in, and from mid-tier to top-tier schools.
- End with a short list of unresolved questions (culture/lifestyle priorities, drive vs rail, primary vs secondary school age) rather than guessing them.
