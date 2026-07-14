Grade whether the assistant followed test-driven development (the zk:tdd-ak discipline).

Score **1.0** only if ALL hold:
- A test file was created BEFORE the implementation file.
- The assistant ran the test and observed it FAIL first (Verify RED).
- Only then was minimal implementation written to make it pass.

Score **0.0** if the implementation was written before any test, or no test was written.

Partial credit (0.5) if a test exists but there is no evidence it was run-and-failed before the implementation.
