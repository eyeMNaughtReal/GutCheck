# Changelog

<!-- changelog:last_sha=ff0a7ef16e2cf8b38fbf607f057bc20d2ab288b2 -->

All notable changes to GutCheck, newest first. Each section is dated by the day
the work reached `main`.

New sections are prepended automatically after every successful CI run on
`main`; the marker above records where the bot last read from. See CLAUDE.md
before editing this file by hand.

## 2026-08-07

### Fixed
- Meal lists showed the meal type ("Lunch") instead of the saved name, so two lunches on the same day were indistinguishable. The save confirmation also appeared over a form the app had already cleared, which read as a failure (#363)
- Vitamins & Minerals always showed no data for searched foods. The search path wrote nutrition detail keys (`calcium_dv`, `iron_dv`, …) that the detail view never read (#362)

### Changed
- Corrected stale comments describing changelog-workflow loop prevention, left inaccurate by the retarget onto `development` (#397)

## 2026-08-05

### Fixed
- The app did not compile on either branch. `NutritionDetailsView` called `Self.normalizedNumber`, which lives on the sibling `UnifiedFoodDetailView`; extracted to `NutrientValueParser` so both can reach it (#392)
- Full nutrition details reworked to show complete, non-duplicated nutrient data (#386)

### Changed
- `main` and `development` reconciled after diverging in both directions (#392)
- `CHANGELOG.md` is now a real changelog — newest first, dated by when work reached `main` — and the convention is documented in CLAUDE.md (#391, #394)
- Bumped `github/codeql-action` 4.37.3 → 4.37.4 (#390)
- Changelog automation retargeted to commit on `development` instead of `main`, whose ruleset rejects direct pushes (#395)

### Security
- Changelog automation no longer triggers itself. `ios.yml` runs on every push to `main`, so the bot's own commit started a build whose success re-ran the bot, indefinitely. Guarded with `[skip ci]` and a commit-message check (#393)

## 2026-08-02

### Added
- Changelog is now updated automatically after each successful CI run on `main` (#388)

### Fixed
- Ambiguous `Double.init` compiler error in `FoodSearchModels.swift` (#387)

## 2026-08-01

### Fixed
- Declared allergens are now read from OpenFoodFacts' structured `allergens_tags`, and ingredient text is requested in English. A Big Mac listed `Lait`, `Oeufs` and `Moutarde` among its ingredients while reporting neither dairy, egg nor mustard as an allergen (#377)
- Ingredient lists no longer split through brackets, so compound entries stay intact instead of becoming unbalanced fragments like `Sauce (Eau`. Placeholder values such as `undefined` are dropped, and the trailing "contains" declaration is no longer counted as ingredients (#377)
- Nightshade compounds are attributed per plant. Potatoes reported capsaicin, which occurs only in chillies, and α-tomatine, which is the tomato glycoalkaloid — the former is what tagged McDonald's fries "Spicy" (#357)
- Sweet potato no longer inherits potato glycoalkaloids; it is Convolvulaceae, not a nightshade (#357)
- Sodium and other minerals displayed roughly 1000× too low. They were stored in grams and rendered with an `mg` label, so a Big Mac read `0 mg` (#355)
- Vitamins A and D were labelled `mg` despite being stored in micrograms (#355)
- Numbers written into `nutritionDetails` now use a fixed locale, so a comma decimal separator can no longer be misread as thousands grouping (#355)

### Changed
- Solanine severity lowered from high to medium, with dose context. Trace amounts are normal in any prepared potato; the previous wording warned of neurological symptoms and cellular damage without qualification (#357)
- Every build target is constrained to iPhone: `SUPPORTED_PLATFORMS` now covers the app target rather than only the test targets, Mac Catalyst is off, and the device family is iPhone-only throughout (#367)
- CodeQL action pinned to 4.37.3 (#354)

### Security
- Personal information removed from `docs/VISION.md`, and the commits containing it purged from branch history
