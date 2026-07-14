# Testing Anti-Patterns

Read this when adding mocks, fakes, or test utilities. These pitfalls make tests pass while proving nothing.

## 1. Testing the mock, not the code

The test exercises the mock's configured behavior instead of the real unit.

<Bad>
```typescript
const db = { getUser: jest.fn().mockReturnValue({ id: 1, name: 'Ann' }) };
test('getUser returns a user', () => {
  expect(db.getUser(1)).toEqual({ id: 1, name: 'Ann' });   // tests jest, not your code
});
```
</Bad>

<Good>
```typescript
test('UserService.format builds a display name', () => {
  const svc = new UserService({ getUser: () => ({ id: 1, first: 'Ann', last: 'Lee' }) });
  expect(svc.displayName(1)).toBe('Ann Lee');   // asserts YOUR logic
});
```
</Good>

**Rule:** assert on the output of the code under test, never on what the mock was told to return.

## 2. Test-only methods on production classes

Adding `resetForTest()`, `_setState()`, or public getters that exist only so a test can peek.

**Why bad:** production surface grows for test convenience; the test couples to internals, not behavior.

**Fix:** test through the public API. If you can't, the design is too coupled — inject the dependency instead.

## 3. Mocking without understanding the dependency

Stubbing a call with a shape that the real dependency never returns (wrong nullability, missing fields, wrong error type). The test is green; production throws.

**Fix:** base the fake on the real contract. Prefer a thin real implementation (in-memory repo, local temp file) over a hand-written mock when feasible.

## 4. Over-mocking (mock everything)

If a unit needs five mocks to test, it has five responsibilities. The test setup becomes larger than the code.

**Fix:** split the unit, or use dependency injection so collaborators are real-but-cheap. Huge setup = design smell, not a test smell.

## 5. Asserting on implementation, not behavior

`expect(spy).toHaveBeenCalledWith(...)` as the *only* assertion. Refactoring the internals — same behavior — breaks the test.

**Fix:** assert the observable result (return value, persisted state, emitted event). Interaction assertions are a supplement, not the point.

## 6. Non-deterministic tests

Real clock, real network, `Math.random`, ordering by hash. Flaky green/red destroys trust in the suite.

**Fix:** inject clock/random; use fixed seeds; stub the network boundary (not your own logic). A test that fails intermittently is worse than no test.

## Quick heuristic

> If the test would still pass after you delete the body of the function under test, the test is wrong.
