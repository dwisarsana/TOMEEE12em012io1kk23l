# Regression Report: Tome AI V2 Migration

## 1. Engine Integrity
**Status: PASSED**
- **Verification:** Compared `lib/core/engine/ai_engine.dart` with `ENGINE_CONTRACT.md`.
- **Findings:**
  - OpenAI API endpoints (`v1/responses`, `v1/images/generations`) are identical.
  - JSON Schema definition for Outline generation is preserved exactly.
  - Image prompt augmentation logic is preserved.
  - Retry logic (Exponential backoff) is implemented verbatim.
  - Export mechanism (`dart_pptx` text-only) matches the contract.

## 2. Premium Access (Monetization)
**Status: PASSED**
- **Verification:** Compared `lib/core/monetization/revenue_cat_service.dart` with `MONETIZATION_CONTRACT.md`.
- **Findings:**
  - Entitlement ID `slides` is used.
  - RevenueCat API Keys are migrated.
  - `isPremium` check includes the required `SharedPreferences` cache fallback.
  - UI Gating:
    - **Creation:** `WizardScreen` checks premium before calling `generateOutline`.
    - **Visualization:** `EditorScreen` checks premium before calling `generateImage`.
    - **Management:** `ArchiveScreen` provides Restore/Upgrade options.

## 3. Free User Limitations
**Status: PASSED**
- **Findings:**
  - Free users cannot generate outlines (Gate in Wizard).
  - Free users cannot generate images (Gate in Editor).
  - Free users **can** view libraries, edit text manually, and export (as per contract).

## 4. Flow Architecture
**Status: PASSED**
- **Verification:** Traced `app_router.dart` and `providers.dart`.
- **Findings:**
  - **Onboarding:** Redirects correctly based on `onboarding_done` flag.
  - **Navigation:**
    - `TomeShell` correctly manages Tabs (Library, Archive) and FAB (Wizard).
    - Wizard opens as a full-screen modal.
    - Editor pushes onto the stack, hiding the bottom nav.
  - **State:** `Riverpod` providers correctly manage User state, Library data, and transient Wizard state.

## 5. Technical Debt / Risks
- **Hardcoded Keys:** API keys are currently in `revenue_cat_service.dart`. This preserves legacy behavior but should be moved to `.env` in a future refactor (outside this scope).
- **HTTP Client:** The engine uses `http` directly. Ensure `http` package version compatibility is monitored.

## Conclusion
The V2 migration successfully implements the new "Magical Realism" design and "Intent-First" flow while strictly adhering to the Engine and Monetization contracts. No regressions in core business logic were found.
