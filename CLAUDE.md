# GutCheck — Working Instructions

## Branching and release flow

Two long-lived branches:

- **`development`** — where normal work lands
- **`main`** — release branch, kept in sync with `development` on request

Both are protected: changes arrive via pull request, force-push and deletion are blocked. A direct `git push` to either will be rejected, so always open a PR.

### Normal work

**Every issue gets its own branch.** Never commit fixes directly to `development` or `main`.

Branch naming follows the existing convention:

```
fix/<short-description>        bug fixes
feat/<short-description>       new functionality
design/<short-description>     UI/UX work
chore/<short-description>      tooling, config, dependencies
```

Branch from `development`, and target the PR at `development`. Hold the PR open until told to merge — see the commands below.

### Critical issues

A critical issue **bypasses `development` and targets `main` directly.**

Treat as critical only when the problem is live and harmful: a crash, data loss or corruption, a security or privacy exposure, or something blocking release. Performance, cleanup, refactors and UI work are not critical. If it is arguable, ask rather than assume — routing a non-critical fix to `main` defeats the point of having two branches.

After a critical fix merges to `main`, **`development` is now behind** and must be reconciled before any further work lands. Do not leave that for later; it is exactly how the branches silently diverge.

## Commands

### "push to dev"

Merge the open feature branches into `development`.

1. Confirm CI is green on each PR — never merge past a red check
2. Merge them
3. Report what landed

### "push dev to main"

Sync `main` with `development`. **Check for divergence first — this is the point of the command.**

1. Compare both directions:
   ```bash
   git fetch origin
   git log origin/main..origin/development --oneline   # dev ahead
   git log origin/development..origin/main --oneline   # main ahead — the danger case
   ```
2. **If `main` has commits `development` lacks** — typically a critical fix that bypassed dev — say so before doing anything, and reconcile so nothing is lost. Never resolve this by force-pushing over either branch.
3. If `development` is strictly ahead, open a PR `development` → `main` and merge it.
4. **Afterwards, verify the two actually match.** GitHub often creates a merge commit rather than fast-forwarding, which leaves `main` one commit ahead — the branches are out of sync again the moment you finish. Fast-forward `development` back to `main` and confirm both point at the same SHA.

Finishing "push dev to main" means both branches report the same commit, not merely that the PR merged.

## Verification

- **Build before every commit.** `xcodebuild build -project GutCheck.xcodeproj -scheme GutCheck -destination 'platform=iOS Simulator,name=iPhone 16 Pro'` from `GutCheck/`.
- **CI runs no tests.** `Build and Test` only builds — the test files never execute. Do not describe something as "tested" when it has only compiled.
- **Verify UI changes on the simulator**, in both light and dark. A compile proves nothing about layout, and dark mode has already caught bugs light mode hid.

## Project specifics

- **Dependencies:** exactly one direct Swift package — `firebase-ios-sdk`. Everything else in `Package.resolved` is transitive, with versions decided by Firebase's manifest. Editing those entries does nothing; SPM overwrites them on the next resolve. CI enforces this via `-onlyUsePackageVersionsFromResolvedFile`, so lockfile drift fails the build.
- **Secrets:** `Secrets.swift` and `GoogleService-Info.plist` are gitignored; CI generates mock versions. Never commit real credentials, and never use a placeholder that matches a real key format — a dummy shaped like `AIza…` will trip secret scanning and cost time.
- **Design tokens** live in `ColorTheme.swift` and `Typography.swift`. Use them rather than raw `Color.red` or `.font(.headline)`. There is no `docs/design.md` yet.
- **Backgrounds:** every root view needs `.background(ColorTheme.background)`, and `List`/`Form` also need `.scrollContentBackground(.hidden)` or they paint the system background over it and render black.

## Working style

- **Verify issue claims against current code before acting.** Roughly 40% of the #299–#318 audit batch turned out stale or misdescribed — some already fixed, one prescribing the wrong remedy. Check first, then fix.
- **Say what was actually verified.** Distinguish "compiles", "verified on simulator" and "verified on device". Do not imply more than was done.
- **Flag decisions rather than burying them.** If a fix involves a trade-off, or an issue's suggested approach is wrong, say so and explain why.
