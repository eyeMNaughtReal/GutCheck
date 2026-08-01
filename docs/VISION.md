# Vision — GutCheck

> Captured by the Product Planner skill. This file is the source of truth for
> generating product-vision.md, prd.md, and product-roadmap.md. Edit it directly
> and re-run the Product Planner to regenerate downstream documents.

**Created:** 2026-07-25
**Updated:** 2026-07-25

## Founder

- **Name:** Redacted
- **Expertise:** Quality assurance background in transportation projects
- **Background:** GutCheck was inspired by the founder's own long-running digestive issues and the difficulty of getting clear answers from conventional testing and specialist visits. The app is intended to help people identify triggers, understand reaction timing, and bring structured symptom data to their doctor.

## Purpose

- **Who you help:** Anyone with chronic, hard-to-pin-down GI symptoms who needs a food/symptom journal to bring to their doctor.
- **Problem you solve:** Food becomes the enemy — people avoid entire food categories out of fear and uncertainty. At the same time, doctors can't diagnose what patients can't document: standard panels come back negative, and there's no next step because the patient's only evidence is a vague memory, not structured, dated data.
- **Desired transformation:** From blanket avoidance to targeted confidence — eating everything except the specific foods proven by their own data to be a trigger. From reactive to proactive — having a personal trigger map (which foods, how much, how long it takes) so decisions happen before the reaction, not after.
- **Why you:** Lived it, not imagined it. The founder is building the tool they were missing while dealing with long-term unexplained digestive issues, rather than guessing at what users need.

## Product

- **Name:** GutCheck
- **One-liner:** GutCheck helps people with unexplained digestive symptoms find their food triggers by logging meals and symptoms together and surfacing the pattern between them.
- **How it works:** A user logs a meal (photo recognition, barcode scan, or manual entry) and later logs a symptom (Bristol stool scale, pain level, urgency, notes). The app timestamps both and correlates them. The dashboard shows a daily health score; Calendar and Insights surface patterns over time; data can be exported to share with a doctor.
- **Key capabilities:**
  - Meal logging via photo recognition, barcode scanning, and manual entry
  - Symptom tracking with medical-grade scales (Bristol Stool Type, pain level, urgency)
  - Medication tracking via HealthKit integration
  - AI-driven health scoring and food-symptom pattern insights
  - Data export for healthcare providers
- **Platform:** mobile
- **Market differentiation:** Unlike generic calorie trackers (MyFitnessPal, Cronometer), GutCheck isn't optimized for weight or macros — it's built to correlate what you ate hours ago with a symptom now, because the whole point is finding the trigger, not counting calories.
- **Magic moment:** The user logs a symptom, and Insights immediately flags: "This has happened 4 of the last 5 times you ate dairy within 3 hours" — the first time the pattern becomes visible instead of just felt.

## Audience

- **Primary user:** The diagnostic-limbo patient — someone who's done the "right" things (seen a specialist, gotten tested) and still has no answer. They've stopped trusting their gut, literally, to tell them what's safe, and they're one more unhelpful appointment away from giving up on getting a real diagnosis.
- **Secondary users:**
  - GI doctors and dietitians receiving the exported data — ties directly to the in-development Healthcare Provider Portal
  - Caregivers and family members tracking symptoms on behalf of someone else
- **Current alternatives:** Dedicated food/symptom tracker apps — mySymptoms Food Diary, MyIBS, Bowelle, Cara, and Food Diary: Symptom Tracker (which markets a competing "Correlation Engine" feature).
- **Frustrations:** Double data entry. Users already log workouts and sleep in Apple Health and have to manually re-enter that same data in these apps because there's no HealthKit sync — confirmed via mySymptoms' own reviews — a gap GutCheck's existing HealthKit integration already closes.

## Business

- **Revenue model:** freemium
- **90-day goal:** Get it in real hands — submit to TestFlight, recruit 10–20 beta testers from relevant communities (Alpha-gal/IBS forums, Facebook groups), and gather structured feedback on whether the meal/symptom correlation actually surfaces something useful.
- **6-month vision:** Freemium is real — both paid tiers live, a modest but real base of paying subscribers (a few dozen), with reviews specifically calling out the trigger-identification feature as what makes GutCheck different from mySymptoms and similar apps.
- **Constraints:** Time — this is a nights-and-weekends project. A full-time QA job means development, testing, and marketing all happen on personal time, pacing the path from pre-launch to public release.
- **Go-to-market:** Community-first — engage directly in existing patient communities (Reddit's r/ibs and r/AlphaGalSyndrome, Alpha-gal Facebook groups, food-intolerance forums), sharing the founder's experience and offering TestFlight access.

## Brand Voice

- **Personality:** The quiet detective — methodical, curious, a little dry. Treats every logged meal and symptom as a clue in an ongoing case, and finds satisfaction in the pattern-finding itself rather than false cheerfulness about a genuinely hard situation — a natural fit for a QA background.
- **Tone of voice:** Dry-witted observer — the same methodical core, with a touch of dry humor to stay human rather than cold. Example error: "Hmm, that timestamp doesn't add up — mind double-checking?" Example success: "Well, well — looks like dairy's been the culprit all along."

> Visual identity (mood, anti-patterns, design tokens) is deliberately not
> captured here — it lives in docs/design.md, generated by the Design System
> skill from image references.

## Tech Stack

- **App type:** mobile
- **Frontend:** SwiftUI — native iOS, tight integration with HealthKit and Apple frameworks, already built
- **Backend:** Firebase (Auth + Storage only) — mature mobile SDKs already in use for authentication and photo/blob storage
- **Database:** CloudKit — structured cloud data (meals, symptoms, medications) holding references to the Firebase Storage assets; native Apple sync with no added vendor cost; paired with CoreData for local storage
- **Auth:** Firebase Auth — already in use, mature, generous free tier
- **Payments:** None — deferred. Revenue model is freemium but the tier structure and pricing aren't finalized yet; revisit before launch.
- **Analytics:** Firebase Analytics — already an available Firebase product, no new vendor needed
- **Email:** None — Firebase Auth handles password reset/verification natively; no marketing or lifecycle email need identified
- **Error tracking:** Firebase Crashlytics — already an available Firebase product, no new vendor needed

## Tooling

- **Coding agent:** Claude Code
