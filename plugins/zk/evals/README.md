# evals

Eval cases for the `zk` plugin, run with `claude plugin eval zk`.

> **Status: starter / unverified.** `claude plugin eval` is in **early access** as of 2026-07, so these cases have not yet been executed end-to-end. Treat them as scaffolding: verify and adjust the format once the command reaches GA.

## Cases

- `writes-test-first/prompt.md` — asks for a new function; graded on whether the model wrote a failing test first.
- `graders/test-first-behavior.md` — the rubric.

## Run (when GA)

```bash
claude plugin eval zk --allow-tools Write Edit Bash
```
