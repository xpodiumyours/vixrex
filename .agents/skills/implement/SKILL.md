---
name: implement
description: "Implement a piece of work based on a spec or set of tickets."
disable-model-invocation: true
---

Implement the work described by the user in the spec or ticket.

## Scope

- Work on one issue/PR only. A new issue starts in a clean session.
- Use the risk selected by `vixrex-router`; high-risk signals override task labels and diff size.
- Keep fixes for the current PR on its existing branch. Do not open a second PR only to validate CI.

## Skill budget

- If the route requires `tdd`, use it at pre-agreed seams before production behavior.
- If `tdd` or `code-review` already completed for the same diff, count it as complete; do not call the same skill twice.
- Run `code-review` once only when the selected route requires it.
- If review causes a material diff change, a second review is reserved for high-risk work or a serious review finding.

## Test budget

1. While working, run only the smallest relevant test.
2. At completion, run the affected surface's typecheck, lint, analyze, or equivalent gate.
3. Before the PR, run the affected surface's full suite at most once.
4. After a green full suite, rerun only tests affected by later code changes. A high-risk or shared-infrastructure change may justify one full rerun.
5. Format only files changed by the task.

Commit to the current branch only when the user has authorized publishing. Report every skipped or unavailable check.
