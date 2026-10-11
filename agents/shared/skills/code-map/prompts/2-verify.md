<!-- Adapt the paths, code trees and scope to the system being mapped. This prompt was first used to map an ETL pipeline (FreeAgent/Xero). -->

Adversarial accuracy review of a pipeline map the owner is reading right now. A previous run produced freeagent.json, xero.json and pipeline-map.html in ~/projects/taisk-orchestration/2026-10-11/PIPELINE-MAP/, from these code trees:
- ~/projects/taisk-wt-pipeline-map-fa (origin/main d4061b535)
- ~/projects/taisk-wt-pipeline-map-xero (origin/feat/v2-xero-capture a2cd1f186)
Both trees are read-only. Don't modify, commit or push them. No network calls to providers or databases.

Your job: assume the map contains errors and find them. For EVERY node, check its claims against the code at its reference and at the code it calls:
- endpoint path and params;
- pagination, batching, concurrency and parallel structure (are the forks real? which things actually run in parallel?);
- rate-limit and retry behaviour;
- windows and partitions;
- what is dropped or tokenised;
- the domain object's fields and identity;
- table columns and keys (check them against the migrations/SQL);
- readiness conditions;
- chronological order (rank) and the edges.
Also look for important missing nodes: endpoints called but not shown, tables written but not shown.

Known fact to use (measured on staging on 11 Oct): on origin/main, attachment objects are NOT dropped. `attachment.content_src`, `content_src_medium`, `content_src_small` and `expires_at` on bank_transaction_explanations, bank_transactions' nested explanations, expenses and the company logo get tokenised into pd_vault as FREE_TEXT, and per-page HTTP Date headers too (`date_header_tokens`). Make the map say exactly this on origin/main, as a known issue (a fix is in progress on another branch), and resolve the matching "unverified" notes.

Then:
1. Fix every error you find directly in freeagent.json and xero.json. Resolve "unverified" items wherever the code can settle them; leave them marked only if the code really can't.
2. Don't touch any HTML; the map is re-rendered from the JSON afterwards.
3. Add a top-level field "verified": "<date/time>, N corrections" to each model.
4. Write REVIEW.md in the same folder: every correction (node id, what was wrong, what is right, with code evidence path:line), plus anything still unverified and why.
5. Re-run the checks: the JSON parses, the edges are valid, every code path exists with the line in range, both files are valid models.
Print a short summary: number of corrections per provider, the most important ones, and what remains unverified.
