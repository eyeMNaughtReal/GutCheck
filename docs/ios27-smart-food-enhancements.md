# iOS 27 Smart Food Enhancements Plan

**Status:** Proposed / Forward-looking
**Target OS:** iOS 27 (Fall 2026), deployment target raised to 26.0+ for smart features (with graceful fallback on 15.0–25.x)
**Owner:** GutCheck team
**Last updated:** July 2026

---

## 1. Vision

Turn GutCheck's food logging from a manual search-and-tap flow into a **smart, conversational capture experience**. A user should be able to:

1. **Snap a photo of a plate** → the app identifies each food, estimates portions, and computes nutrition.
2. **Snap a photo of a can/label/box** → the app reads the nutrition panel and brand directly.
3. **Speak or type natural language** — "Publix Reduced Sodium Black Beans" or "Turkey sandwich with mayo and a slice of cheddar" — and get a structured, accurate meal.
4. Be **asked clarifying questions** whenever confidence is low or a nutrition-relevant attribute is missing — "Were those reduced-sodium black beans?", "What kind of bread?", "What brand of cheese?"

The differentiator is the **clarification loop**: the app never silently guesses on details that materially change nutrition (sodium, added sugar, fat, portion). It asks, learns, and remembers.

---

## 2. Where we are today (baseline)

| Capability | Current implementation | Gap |
|---|---|---|
| Photo food recognition | `Services/ML/FoodRecognitionService.swift` — generic **Inceptionv3** classifier via Vision, returns top-3 labels | Not food-specialized; no portions; no multi-item plates; no nutrition link |
| AI nutrition analysis | `Services/AIAnalysisService.swift` — mostly `TODO`; heuristic branded-food estimator (`estimateNutritionForBrandedFood`) | No real reasoning, no clarifying questions, no NL parsing |
| Food search | `Services/FoodSearchService.swift` — concurrent **USDA FoodData Central** + **OpenFoodFacts**, merged/deduped | Text-only; no conversational refinement |
| Label / barcode | `OpenFoodFactsService` (barcode-friendly data) | No on-device label OCR or barcode scanner UI wired to capture |
| Portion estimation | Comment in `FoodRecognitionService` mentions "LiDAR workflow" | Not implemented |
| Conversational AI | None | No LLM integration anywhere in the codebase |

**Takeaway:** the data-source plumbing (USDA + OpenFoodFacts + branded estimation) is solid. The recognition and reasoning layers are the greenfield work.

---

## 3. iOS 27 platform capabilities to leverage

> These build on APIs Apple introduced in iOS 26 (2025) and are expected to mature in iOS 27. Treat exact API shapes as provisional until the iOS 27 SDK ships; validate at WWDC 2026.

- **Foundation Models framework** — Apple's on-device LLM. Use for the clarifying-question dialog, natural-language meal parsing, and structured extraction. Private (data never leaves device), free (no per-call cost), works offline. Use **guided generation / `@Generable` structured output** to decode directly into our `FoodItem` / `NutritionInfo` models.
- **Visual Intelligence / Vision framework** — improved image classification and the newer food-aware requests; multiple-object detection for multi-item plates.
- **VisionKit `DataScannerViewController`** — live camera OCR + barcode in one component. Drives both label reading and barcode capture.
- **LiDAR depth + ARKit** — real-world portion/volume estimation on Pro devices; graceful fallback to reference-object sizing (utensil, hand, plate) on non-LiDAR devices.
- **App Intents / Visual Intelligence entry points** — "log a meal" from the camera/lock-screen without opening the app.
- **Speech framework (`SpeechAnalyzer`)** — on-device dictation for spoken food entries.

**Cloud fallback:** for reasoning the on-device model can't handle (dense nutrition panels, obscure branded items, low-confidence multi-item plates), fall back to a cloud LLM (Claude) behind a user-consent, privacy-gated path. On-device first, cloud only when needed and permitted.

---

## 4. Target architecture

A new **Smart Food** subsystem layered on top of existing services. Proposed location: `Services/SmartFood/`.

```
┌─────────────────────────────────────────────────────────────┐
│                     Capture Layer                            │
│  Plate photo · Label/can photo · Barcode · Voice · Text      │
│  (VisionKit DataScanner, ARKit/LiDAR, SpeechAnalyzer)        │
└───────────────┬─────────────────────────────────────────────┘
                │
┌───────────────▼─────────────────────────────────────────────┐
│                  Recognition Layer                           │
│  FoodRecognitionService (food-specialized model)             │
│  PortionEstimationService (LiDAR/reference object)           │
│  LabelReaderService (OCR → nutrition panel parse)            │
│  → emits Candidate(s) with confidence + missing attributes   │
└───────────────┬─────────────────────────────────────────────┘
                │
┌───────────────▼─────────────────────────────────────────────┐
│              Reasoning / Conversation Layer                  │
│  SmartFoodReasoner (Foundation Models, cloud fallback)       │
│  • NL meal parsing  • clarifying-question generation         │
│  • structured extraction → FoodItem/NutritionInfo            │
│  ClarificationEngine (dialog state machine)                  │
└───────────────┬─────────────────────────────────────────────┘
                │
┌───────────────▼─────────────────────────────────────────────┐
│               Nutrition Resolution Layer                     │
│  FoodSearchService (USDA + OpenFoodFacts) · barcode lookup   │
│  AIAnalysisService (branded estimation, reconciliation)      │
│  → final FoodItem with provenance + confidence               │
└──────────────────────────────────────────────────────────────┘
```

### Key new components

- **`SmartFoodCandidate`** — intermediate model: recognized name, confidence (0–1), estimated portion (+ method: LiDAR / reference / default), source (photo/label/voice/text), and a list of `MissingAttribute`s (e.g. `.sodiumVariant`, `.brand`, `.breadType`, `.cheeseType`).
- **`ClarificationEngine`** — decides *when* to ask. Rule: if a missing attribute would shift a tracked metric (sodium, added sugar, fat, calories, portion) beyond a threshold, generate a question. Prioritizes questions by nutritional impact; caps at N questions per item to avoid fatigue.
- **`SmartFoodReasoner`** — wraps Foundation Models with a strict schema so output always decodes into our models; owns the cloud-fallback decision and consent gating.
- **Provenance & confidence on `FoodItem`** — extend `Models/FoodItem.swift` (and `Models/Nutrition/`) with `source`, `confidence`, `estimationMethod`, and `userConfirmed` so the UI can show "AI estimated" vs "from label" vs "you confirmed".

---

## 5. Feature workstreams

### 5.1 Plate photo → multi-item recognition + portions
- Replace generic Inceptionv3 with a **food-specialized classifier** (Core ML) + Vision object detection for multiple items on one plate.
- Add **`PortionEstimationService`**: LiDAR depth → volume → grams using density priors per food category; reference-object fallback (fork/plate/hand) when no LiDAR.
- Output one `SmartFoodCandidate` per detected item; low-confidence items flow to the clarification loop.

### 5.2 Label / can photo → nutrition panel read
- **`LabelReaderService`** using VisionKit OCR: detect and parse the Nutrition Facts panel (serving size, calories, macros, sodium, sugars) and brand/product name.
- Reconcile parsed values against OpenFoodFacts/USDA by barcode when present; prefer the label when they disagree, flag the discrepancy.

### 5.3 Barcode scanning
- Wire **`DataScannerViewController`** barcode mode → existing `OpenFoodFactsService` lookup (already barcode-oriented). Fast path that skips reasoning entirely on a confident hit.

### 5.4 Natural-language single item — "Publix Reduced Sodium Black Beans"
- `SmartFoodReasoner` parses brand + product + variant → structured query → `FoodSearchService`.
- If the variant (reduced-sodium) isn't matched in the data source, `ClarificationEngine` confirms rather than substituting a regular-sodium entry.

### 5.5 Natural-language composite meal — "Turkey sandwich with mayo and a slice of cheddar"
- Decompose into components (bread, turkey, mayo, cheddar) as separate `SmartFoodCandidate`s.
- Generate targeted clarifying questions per component: *"What kind of bread?"*, *"What brand of cheese?"*, *"Regular or light mayo?"*
- Assemble into a single `Meal` (reuse `MealBuilderService` / `MealBuilderView`).

### 5.6 Clarifying-question UX
- Lightweight, chat-like confirmation sheet surfaced from `MealBuilderView` / `FoodSearchView`.
- Each question offers quick-tap options + free text; answers update the candidate and re-resolve nutrition live.
- **Memory:** persist user answers ("you usually use whole-wheat bread") to pre-fill future questions and reduce repeat prompts.

### 5.7 Voice entry
- `SpeechAnalyzer` dictation → same NL pipeline as 5.4/5.5.

---

## 6. Data & privacy

- Aligns with the app's **privacy-first** posture (see `docs/compliance.md`). On-device Foundation Models keep food photos and text local by default.
- **Cloud LLM fallback is opt-in**, gated behind explicit consent, with a clear indicator when a request leaves the device. No health/symptom context is sent — only the minimal food string/image needed for resolution.
- New provenance fields make it auditable which values were AI-estimated vs. user-confirmed vs. label-sourced — relevant for the HIPAA-ready framing.
- Update `privacy_policy.txt` and `docs/compliance.md` to cover photo processing and any cloud fallback.

---

## 7. Phased delivery

| Phase | Scope | Depends on |
|---|---|---|
| **0 — Foundations** | Add `Services/SmartFood/`, `SmartFoodCandidate`, provenance/confidence fields on `FoodItem`, feature flags, availability gating (`if #available(iOS 27)`) | — |
| **1 — Reasoning core** | `SmartFoodReasoner` (Foundation Models + structured output), NL single-item parsing (5.4), consent + cloud fallback scaffolding | Phase 0 |
| **2 — Clarification loop** | `ClarificationEngine`, question UX in MealBuilder, answer memory (5.6), composite meal parsing (5.5) | Phase 1 |
| **3 — Label & barcode** | `LabelReaderService` OCR (5.2), DataScanner barcode (5.3) | Phase 0 |
| **4 — Vision & portions** | Food-specialized model, multi-item plate detection, `PortionEstimationService` LiDAR + fallback (5.1) | Phase 0 |
| **5 — Voice & polish** | Voice entry (5.7), App Intents entry points, accuracy tuning, analytics on clarification acceptance | Phases 1–4 |

Phases 1–2 (reasoning + clarification) and 3 (label/barcode) can proceed in parallel; both are independent of the heavier Vision/LiDAR work in Phase 4.

---

## 8. Success metrics

- **Logging speed:** median time to log a meal via photo/voice vs. current manual search.
- **Nutrition accuracy:** estimated vs. label-verified values on a benchmark set (target within ±15% on calories/sodium/sugar).
- **Clarification quality:** % of questions the user accepts vs. overrides; average questions per item (keep low).
- **Recognition:** top-1 food-identification accuracy on a plate-photo test set; multi-item detection recall.
- **Privacy:** % of requests served fully on-device (target: majority).

---

## 9. Open questions / risks

- **iOS 27 API stability** — Foundation Models APIs may change at WWDC 2026; keep the reasoner behind our own protocol so we can swap implementations.
- **On-device model limits** — small on-device LLMs may struggle with dense panels or obscure brands; the cloud fallback must be robust and clearly consented.
- **Device fragmentation** — LiDAR is Pro-only; non-LiDAR portion estimation accuracy needs validation.
- **Deployment target** — smart features gate on iOS 26/27; the app must degrade gracefully to the current manual flow on iOS 15–25.
- **Food-model sourcing** — decide between a licensed food classifier, a custom-trained Core ML model, or Apple's built-in food recognition once its coverage is known.
- **Cost governance** — rate-limit and budget the cloud fallback (reuse `Services/RateLimiting/`).

---

## 10. Immediate next steps (pre-iOS 27)

Work that de-risks the above and is valuable today, before the iOS 27 SDK lands:

1. Define `SmartFoodCandidate` + provenance/confidence fields and thread them through `FoodItem` / `MealBuilderService` (no OS dependency).
2. Extract a `SmartFoodReasoner` **protocol** now, backed by the existing heuristic `AIAnalysisService`, so the Foundation Models implementation is a drop-in later.
3. Wire `DataScannerViewController` barcode scanning to `OpenFoodFactsService` — shippable on current iOS.
4. Prototype the clarifying-question UX with static rules (no LLM) to validate the interaction before wiring real reasoning.
