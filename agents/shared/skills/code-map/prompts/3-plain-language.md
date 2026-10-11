<!-- Adapt the paths, code trees and scope to the system being mapped. This prompt was first used to map an ETL pipeline (FreeAgent/Xero). -->

Add a newcomer-friendly explanation to every node of the two pipeline maps.

Files (edit in place, JSON only):
- ~/projects/taisk-orchestration/2026-10-11/PIPELINE-MAP/freeagent.json
- ~/projects/taisk-orchestration/2026-10-11/PIPELINE-MAP/xero.json

These models are already verified against the code. Don't change any existing field. Don't explore the codebase: write only from each node's own data (title, type, details, chapter) and its neighbours via the edges (what comes before, what comes after).

PURPOSE (owner, binding): a very practical, BUSINESS-LEVEL explanation. Why does this step exist from the business's point of view, what does it do, and how does it fit in the whole flow? The whole flow: a business owner connects their accounting software, we copy their books safely, organise them into our own model, and use that to forecast their cash. Each explanation should make clear what business problem the step solves or prevents, for example:
- giving the owner a working forecast quickly;
- knowing who owes the business money;
- not breaking the provider's usage limits;
- protecting personal data;
- not double-counting anything if a sync is interrupted;
- telling the owner honestly when data is missing.

For EVERY node, add (or overwrite) a field "plain": a string of 1–3 short sentences in VERY simple, friendly English, written for someone who has never seen this code and isn't technical:
- Start with where we are in the journey and why this step is there for the business (e.g. "To forecast cash we first need to know who owes the business money, so…").
- What happens at this step, in everyday words.
- Why it's needed, in context: link it to the previous and next step. E.g. "Now that we know which bank accounts the business has, we fetch each account's transactions so we can see where money came in and went out." Or "This table is where we keep each invoice once it's been cleaned up, so the forecast can later work out who owes the business money."
- No jargon. If a technical word is unavoidable, explain it in a few words (e.g. "an API, the door FreeAgent lets us use to read the books").
- No code identifiers, no file paths, no column names unless explained.
- Be accurate: never claim more than the node's details say. If something is a known issue or gap in the details, say so plainly (e.g. "Right now this also keeps temporary download links it doesn't need. This is being fixed.").
- British English. Stay friendly but not cute.

Also add to each chapter object a field "plain": 2–3 very simple sentences explaining what this whole chapter achieves and why it comes at this point in the journey.

Self-check:
- both files parse;
- every node and every chapter has a non-empty "plain";
- each node is at most ~60 words.
Print the counts and three example nodes per provider.
