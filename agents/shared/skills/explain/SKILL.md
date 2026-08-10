---
name: explain
description: Generate a rich, interactive HTML explainer page for a codebase concept, feature, or domain. Produces visual diagrams, data flows, interactive demos, and file maps. Use when you need to understand or document a feature, pattern, or architectural decision.
model: opus
allowed-tools: Read, Glob, Grep, Bash, Write
---

# Explain — Interactive HTML Explainer Generator

Generate a self-contained HTML page that explains a codebase concept, feature branch, domain model, or architectural pattern. The page is visual, interactive, and designed for engineers onboarding onto unfamiliar code.

## Inputs

The user provides one of:
- A feature or concept to explain (e.g. "product hierarchy", "tonnage list filtering")
- A branch name or PR to explain
- A domain model or pattern to document
- A question like "how does X work?"

If the user provides arguments, use them as the topic. Otherwise, ask what to explain.

## Research Phase

Before writing any HTML, thoroughly research the topic:

1. **Find all relevant source files** — domain models, repositories, DTOs, API routes, tests
2. **Trace the data flow** — from DB schema through infrastructure to domain to API response
3. **Identify the business context** — why does this exist? what problem does it solve?
4. **Find related patterns** — is this similar to something else in the codebase?
5. **Read tests** — they reveal intended behaviour and edge cases

Do NOT start writing HTML until you have a complete understanding.

## Output

Write a single self-contained HTML file to `/tmp/<topic-slug>-explainer.html` and open it in the browser.

The page MUST include these sections (adapt ordering to what makes sense for the topic):

### 1. Business Context
- Why does this feature/pattern exist?
- What user problem does it solve?
- What domain concepts are involved?
- Use cards with coloured left borders to distinguish context types (info, warning, success)

### 2. Visual Diagram
- SVG tree, graph, or architecture diagram showing the core structure
- Use the dark theme colour palette below
- Nodes should be interactive (hover effects minimum)
- Show IDs, types, or key properties on nodes

### 3. Interactive Demo (when applicable)
- Clickable controls that demonstrate the logic
- Show inputs, the lookup/computation, and the result
- Use green for matches, red for non-matches
- Help the reader build intuition, not just read about it

### 4. Data Flow
- Horizontal flow showing the path from source to consumer
- Label each box with its architectural layer (DB, Infrastructure, Domain, API)
- Include the key transformation at each step

### 5. Architecture / Pattern Comparison
- If the pattern mirrors something else in the codebase, show them side by side
- Use tabs to switch between the two implementations
- Highlight what's identical and what differs

### 6. Code Snippets
- Show key code blocks with syntax highlighting (use span classes, not a library)
- Only show the essential lines, not entire files
- Annotate with comments where helpful

### 7. Current State vs Changes (for PRs/branches)
- What existed before
- What this change adds
- What's coming next (if preparatory work)

### 8. Key Invariants / Rules
- Business rules enforced by validators
- Constraints that must hold
- Use checkmark lists

### 9. File Map
- Tree-style listing of all relevant files
- One-line description of each file's role
- Use coloured syntax for filenames vs comments

## Design System

### Dark Theme Palette
```
Background:     #0d1117
Card bg:        #161b22
Card border:    #30363d
Code bg:        #1f2937
Text primary:   #c9d1d9
Text secondary: #8b949e
Blue:           #58a6ff (links, info borders, headings)
Light blue:     #79c0ff (secondary headings, numbers)
Green:          #3fb950 (success, matches, valid)
Red:            #f85149 (errors, non-matches, dirty)
Orange:         #f0883e (code highlights, warnings)
Yellow:         #d29922 (caution borders)
Purple:         #d2a8ff (types, function names)
```

### Card Styles
- `.card-highlight` — blue left border (informational)
- `.card-warn` — yellow left border (problems, caveats)
- `.card-green` — green left border (solutions, good patterns)

### Typography
- Font: Inter / system-ui / sans-serif
- H1: 28px, blue
- H2: 20px, light blue, bottom border
- H3: 16px, purple
- Body: 14px
- Code: 13px, monospace, orange text on dark bg
- Small labels: 10-12px, secondary colour, uppercase + letter-spacing for layer labels

### Syntax Highlighting Classes
```html
<span class="keyword">class</span>    <!-- #ff7b72 -->
<span class="string">"value"</span>  <!-- #a5d6ff -->
<span class="comment"># note</span>  <!-- #8b949e -->
<span class="type">MyClass</span>   <!-- #d2a8ff -->
<span class="fn">method</span>     <!-- #d2a8ff -->
<span class="num">42</span>        <!-- #79c0ff -->
```

### Flow Diagram Pattern
```html
<div class="flow">
  <div class="flow-box">
    <div class="flow-layer db">Database</div>
    <h4>Table Name</h4>
    <p>Description</p>
  </div>
  <div class="flow-arrow">&rarr;</div>
  <!-- next box... -->
</div>
```

Layer label colours: `.domain` green, `.infra` yellow, `.db` red, `.api` blue.

### SVG Architecture Diagram — Reference Template

Use this as the canonical layout for hexagonal/layered architecture diagrams. Adapt box labels and counts to the topic, but keep the spatial structure: stacked dashed-border layer regions, inner rounded boxes with `#1f2937` fill, uppercase coloured layer labels, and `#8b949e` arrow connectors with annotation text.

```html
<svg viewBox="0 0 900 420" style="width:100%;max-width:900px;margin:20px auto;display:block">
  <!-- Full background -->
  <rect x="0" y="0" width="900" height="420" fill="#0d1117" rx="12"/>

  <!-- API Layer — blue dashed border, top row -->
  <rect x="40" y="30" width="820" height="80" rx="8" fill="#161b22" stroke="#58a6ff" stroke-width="1.5" stroke-dasharray="6,3"/>
  <text x="60" y="52" fill="#58a6ff" font-size="10" font-weight="600" letter-spacing="1.5">API LAYER</text>
  <!-- Inner boxes -->
  <rect x="60" y="60" width="200" height="40" rx="6" fill="#1f2937" stroke="#30363d"/>
  <text x="100" y="85" fill="#c9d1d9" font-size="12">POST /vessel-imo-classes</text>
  <rect x="280" y="60" width="260" height="40" rx="6" fill="#1f2937" stroke="#30363d"/>
  <text x="300" y="78" fill="#d2a8ff" font-size="11">CreateQueryDto</text>
  <text x="300" y="93" fill="#8b949e" font-size="10">imo + list[ImoClassDto]</text>
  <rect x="560" y="60" width="280" height="40" rx="6" fill="#1f2937" stroke="#30363d"/>
  <text x="580" y="78" fill="#d2a8ff" font-size="11">UserAddedVesselImoClassesResponse</text>
  <text x="580" y="93" fill="#8b949e" font-size="10">id + vessel_imo_classes{imo, classes}</text>

  <!-- Arrow: API -> Application -->
  <line x1="160" y1="100" x2="160" y2="150" stroke="#8b949e" stroke-width="1.5" marker-end="url(#arrow)"/>
  <text x="170" y="130" fill="#8b949e" font-size="10">dto.to_domain()</text>

  <!-- Application Layer — purple dashed border, second row -->
  <rect x="40" y="150" width="820" height="80" rx="8" fill="#161b22" stroke="#d2a8ff" stroke-width="1.5" stroke-dasharray="6,3"/>
  <text x="60" y="172" fill="#d2a8ff" font-size="10" font-weight="600" letter-spacing="1.5">APPLICATION LAYER</text>
  <rect x="60" y="180" width="340" height="40" rx="6" fill="#1f2937" stroke="#30363d"/>
  <text x="80" y="198" fill="#d2a8ff" font-size="11">CreateUserAddedVesselImoClassesHandler</text>
  <text x="80" y="213" fill="#8b949e" font-size="10">utc_now_tz_unaware() + get_next_id()</text>
  <rect x="420" y="180" width="300" height="40" rx="6" fill="#1f2937" stroke="#30363d"/>
  <text x="440" y="198" fill="#d2a8ff" font-size="11">CreateCommand</text>
  <text x="440" y="213" fill="#8b949e" font-size="10">user_id + org_id + VesselImoClasses</text>

  <!-- Arrow: Application -> Domain -->
  <line x1="230" y1="220" x2="230" y2="270" stroke="#8b949e" stroke-width="1.5" marker-end="url(#arrow)"/>
  <text x="240" y="250" fill="#8b949e" font-size="10">build_new()</text>

  <!-- Domain Layer — green dashed border, bottom-left -->
  <rect x="40" y="270" width="400" height="80" rx="8" fill="#161b22" stroke="#3fb950" stroke-width="1.5" stroke-dasharray="6,3"/>
  <text x="60" y="292" fill="#3fb950" font-size="10" font-weight="600" letter-spacing="1.5">DOMAIN LAYER</text>
  <rect x="60" y="300" width="170" height="40" rx="6" fill="#1f2937" stroke="#30363d"/>
  <text x="80" y="318" fill="#d2a8ff" font-size="11">VesselImoClasses</text>
  <text x="80" y="333" fill="#8b949e" font-size="10">imo + set[ImoClass]</text>
  <rect x="250" y="300" width="170" height="40" rx="6" fill="#1f2937" stroke="#30363d"/>
  <text x="262" y="318" fill="#d2a8ff" font-size="11">UserAddedVessel...</text>
  <text x="262" y="333" fill="#8b949e" font-size="10">id + author + classes</text>

  <!-- Infrastructure Layer — yellow dashed border, bottom-right -->
  <rect x="460" y="270" width="400" height="130" rx="8" fill="#161b22" stroke="#d29922" stroke-width="1.5" stroke-dasharray="6,3"/>
  <text x="480" y="292" fill="#d29922" font-size="10" font-weight="600" letter-spacing="1.5">INFRASTRUCTURE LAYER</text>
  <rect x="480" y="300" width="180" height="40" rx="6" fill="#1f2937" stroke="#30363d"/>
  <text x="495" y="318" fill="#d2a8ff" font-size="11">Repository</text>
  <text x="495" y="333" fill="#8b949e" font-size="10">add + get_next_id + dup check</text>
  <rect x="680" y="300" width="160" height="40" rx="6" fill="#1f2937" stroke="#30363d"/>
  <text x="695" y="318" fill="#d2a8ff" font-size="11">...ImoClassesDb</text>
  <text x="695" y="333" fill="#8b949e" font-size="10">from_domain / to_domain</text>

  <!-- DB box — red border, nested inside Infrastructure -->
  <rect x="480" y="355" width="360" height="35" rx="6" fill="#1f2937" stroke="#f85149" stroke-width="1.5"/>
  <text x="500" y="370" fill="#f85149" font-size="10" font-weight="600" letter-spacing="1">DB</text>
  <text x="540" y="377" fill="#c9d1d9" font-size="11">user_added_vessel_imo_classes</text>

  <!-- Horizontal/vertical arrows between layers -->
  <line x1="420" y1="320" x2="475" y2="320" stroke="#8b949e" stroke-width="1.5" marker-end="url(#arrow)"/>
  <line x1="660" y1="320" x2="675" y2="320" stroke="#8b949e" stroke-width="1.5" marker-end="url(#arrow)"/>
  <line x1="660" y1="340" x2="660" y2="355" stroke="#8b949e" stroke-width="1.5" marker-end="url(#arrow)"/>

  <!-- Arrow marker definition -->
  <defs>
    <marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-auto">
      <path d="M 0 0 L 10 5 L 0 10 z" fill="#8b949e"/>
    </marker>
  </defs>
</svg>
```

**Layout rules for this template:**
- viewBox `0 0 900 420` — adapt height if more/fewer layers
- Layer regions: dashed border (`stroke-dasharray="6,3"`), `#161b22` fill, 820px wide, 80px tall
- Inner boxes: solid `#30363d` border, `#1f2937` fill, 6px border-radius
- Layer labels: 10px uppercase, 1.5px letter-spacing, colour matches the layer border
- Box titles: 11px `#d2a8ff`, subtitles: 10px `#8b949e`
- Arrows: `#8b949e`, 1.5px stroke, annotation text beside the arrow
- Layer colours: API = `#58a6ff`, Application = `#d2a8ff`, Domain = `#3fb950`, Infrastructure = `#d29922`, DB = `#f85149`

### Interactive Demo Pattern
- Container with `.demo` class
- Button row with `.demo-controls`
- Buttons toggle `.selected` class
- Results area with `.demo-result`
- Use JS to compute and render results inline — no external dependencies

## Rules

- **Zero external dependencies** — no CDNs, no JS libraries, no font imports. Everything inline.
- **All CSS in a single `<style>` block** in the head.
- **All JS in `<script>` blocks** at the point of use (near the relevant HTML), not in a separate file.
- **SVG for diagrams** — not canvas, not images. SVG is inspectable and scales.
- **No lorem ipsum** — use real data from the codebase.
- **British English** for all text.
- **No emojis** unless the user explicitly asks.
- Adapt sections to the topic — skip sections that don't apply, add custom ones if needed.
- The page should be understandable by an engineer who has never seen this codebase.
- After writing the file, open it with `open <path>` (macOS).
