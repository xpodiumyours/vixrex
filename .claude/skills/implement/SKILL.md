---
name: implement
description: "Implement a piece of work based on a spec or set of tickets."
disable-model-invocation: true
---

Implement the work described by the user in the spec or ticket.

## Scope

- Implement only the scope requested by the user or the explicitly named ticket.
- Preserve unrelated user changes and existing working behavior.
- Keep fixes for the current PR on its existing branch. Do not open a second PR only to validate CI.

## Test budget

1. While working, run only the smallest relevant test.
2. At completion, run the affected surface's typecheck, lint, analyze, or equivalent gate.
3. Before the PR, run the affected surface's full suite at most once.
4. After a green full suite, rerun only tests affected by later code changes. A high-risk or shared-infrastructure change may justify one full rerun.
5. Format only files changed by the task.

Commit, push, PR, merge, deploy, migration and live-system operations require the user's explicit scope. Report every skipped or unavailable check.
