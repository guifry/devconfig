<!-- Adapt the paths, code trees and scope to the system being mapped. This prompt was first used to map an ETL pipeline (FreeAgent/Xero). -->

You are mapping the v2 ETL (ingestion) pipeline of this codebase for the owner, who has never read this code. Accuracy is everything: every claim must come from the code, with a file:line reference. Never invent behaviour. Where something is unclear, mark it "unverified" in the node.

READ-ONLY. Don't modify, commit or push anything in either code tree. No network calls to providers or databases. Only read code and docs, and write the output files listed below.

Two code trees (detached, read-only):
- FreeAgent pipeline: ~/projects/taisk-wt-pipeline-map-fa (origin/main d4061b535; this is what runs on staging).
- Xero pipeline: ~/projects/taisk-wt-pipeline-map-xero (origin/feat/v2-xero-capture a2cd1f186, the redesigned Xero capture; main's Xero code is older).

Scope, for each provider, from trigger to the tables the forecasting engines read:
1. Trigger: OAuth callback / nightly planner / manual sync → owner sync run row → Cloud Tasks / local dispatch → worker → capture.
2. Discovery: what it fetches first (inventory, bank accounts, etc.).
3. Capture: every HTTP endpoint actually called, in execution order.
   - For each endpoint:
     - method + path;
     - query params (view, per_page/pageSize, from/to dates, nested flags, If-Modified-Since…);
     - pagination;
     - batching;
     - concurrency/parallelism, and what runs in parallel with what;
     - rate-limit handling (quota store, Retry-After, backoff);
     - partitioning (per bank account, per month, per date…);
     - the window (e.g. 25 months);
     - completeness/count checks;
     - what is filtered or dropped.
   - Where things run in parallel, represent a fork: sibling nodes at the same level, joining after.
4. Landing: raw storage (raw.fetch, raw.object, landing_intent), the privacy transform (what is tokenised into pd_vault and what is dropped, e.g. attachments), gzip, chapters/sections, resume.
5. Fold / translation: the anti-corruption translators from provider JSON to the domain ontology. For each **uppermost encapsulating domain object** (e.g. Invoice, Bill, BankTransaction, LedgerAccount, TrialBalance, MonthlyAccountHistory, Contact/Party, Payroll…):
   - what it represents;
   - its most important fields;
   - its natural key/identity;
   - which endpoint(s) feed it.
6. Database tables written (schema.table):
   - what the table is about;
   - its most important columns, with what each means;
   - the key/upsert identity;
   - which domain object it stores.
   Get columns from the Alembic migrations / SQL files.
7. Downstream: the derived/prepared tables and the projection inputs the engines read (domain_projection, pipeline_app), and readiness (how onboarding becomes "ready").

OUTPUT 1: a JSON graph model for each provider, at ~/projects/taisk-orchestration/2026-10-11/PIPELINE-MAP/freeagent.json and ~/projects/taisk-orchestration/2026-10-11/PIPELINE-MAP/xero.json:
{
  "provider": "FreeAgent", "code_ref": "origin/main d4061b535",
  "chapters": [ {"id": "trigger", "title": "1. Trigger & dispatch", "summary": "..."} , ...],
  "nodes": [
    {"id": "...", "chapter": "<chapter id>", "type": "step|endpoint|transform|domain|table|engine",
     "title": "short label shown in the box",
     "rank": <int, chronological order top→bottom; parallel siblings share the same rank>,
     "details": { ... type-specific key/value pairs in plain English, as described in the scope above ... },
     "code": "backend/relative/path.py:LINE"   // repo-relative path + line of the most relevant definition
    }
  ],
  "edges": [ {"from": "id", "to": "id", "label": "optional, e.g. 'per bank account', 'parallel'"} ]
}
Aim for about 40–90 nodes per provider: complete but readable. Group repetitive endpoints sensibly, e.g. one node per endpoint family, with the details listing the variants.

OUTPUT 2: none. Don't build any HTML; the map is rendered afterwards from the JSON with the skill's template (scripts/embed.py).

Quality bar:
- Every endpoint, domain object and table node has a correct code reference, at a line that exists.
- Verify each reference with `sed -n` before writing it.
- Plain English in details; no jargon without a short explanation.
- After writing the files, self-check:
  - the JSON parses;
  - every edge references existing nodes;
  - every `code` path exists, with the line in range;
  
When done, print a short summary: node counts per provider, chapters, anything marked unverified.
