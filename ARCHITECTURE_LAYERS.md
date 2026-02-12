# Architecture Layers: AI Presentation

## Layer Mapping

### A) Core Engine Layer (Generation, Data, Export)
- **Files:**
    - `lib/utility/apikey.dart`: Configuration (OpenAI Key, Model, Headers).
    - `lib/utility/models.dart`: Data Models (`Presentation`, `Slide`, `RecentPresentation`).
    - `lib/utility/storage.dart`: Persistence Logic (`SharedPreferences`, JSON Serialization).
    - `lib/ui/ai_generate.dart` (PARTIAL):
        - `_generateOutline`: HTTP Call to OpenAI (`v1/responses`), JSON Parsing.
        - `_generateImageWithRetries`: HTTP Call to OpenAI (`v1/images/generations`), Image Parsing, Retry Logic.
        - `_exportToPptx`: PPTX Generation using `dart_pptx`, File I/O.
- **Dependencies:** `dart:convert`, `dart:io`, `package:http` (transitive), `dart_pptx`, `open_filex`, `path_provider`.

### B) Monetization Layer (Revenue, Entitlements, Gating)
- **Files:**
    - `lib/src/store_config.dart`: Store Selection Logic (Apple/Google/Amazon).
    - `lib/src/constant.dart`: API Keys, Entitlement IDs (`slides`), `checkPremiumStatus` Logic.
    - `lib/src/paywall.dart`: RevenueCat Paywall UI (`PaywallScreen`, `_PaywallScreenState`).
    - `lib/src/upsell.dart`: Subscription Options UI (`UpsellScreen`, `_UpsellScreenState`).
    - `lib/src/initial.dart`: Purchase Listener Logic (`Purchases.addReadyForPromotedProductPurchaseListener`).
    - `lib/ui/ai_generate.dart` (PARTIAL):
        - `_readPremiumStatus`: Calls `Purchases.getCustomerInfo`, Caches to `SharedPreferences`.
        - `_showUpgradeSnack`: Navigation to Settings/Paywall.
- **Dependencies:** `purchases_flutter`, `purchases_ui_flutter`.

### C) Experience Layer (UI, Navigation, Flow)
- **Files:**
    - `lib/main.dart`: App Entry Point, Theme, Routing, `_LaunchGate` (State Management).
    - `lib/opening/`: Splash Screen, Onboarding Flow.
    - `lib/ui/homepage.dart`: Home Screen (Presentation List).
    - `lib/ui/editor.dart`: Manual Editor (Legacy/Alternative).
    - `lib/ui/setting.dart`: Settings Screen (`MorePage`).
    - `lib/ui/template.dart`: Template Selection Screen.
    - `lib/ui/ai_generate.dart` (PARTIAL):
        - `build`: Main UI Structure (Stack, Scaffold, Sidebar, Canvas).
        - `_AIGeneratePageState`: State Management (`_selectedIndex`, `_busy`, `_exporting`).
        - `_GlassLoader`, `_LogoSpinner`: Custom Animations.
        - `_PresenterView`: Presentation Mode UI.
- **Dependencies:** `flutter`, `google_fonts`, `flutter_animate`, `image_picker`.

---

## Dependencies Between Layers

1.  **Experience -> Core Engine:**
    - `HomePage` uses `Storage` to load `RecentPresentation` lists.
    - `AIGeneratePage` uses `models.dart` to structure data.
    - `AIGeneratePage` calls `_generateOutline` (Engine logic embedded in UI file).

2.  **Experience -> Monetization:**
    - `InitialScreen` (Experience/Monetization Hybrid) directs flow based on `CustomerInfo`.
    - `AIGeneratePage` calls `_readPremiumStatus` before executing actions.
    - `Settings` (implied) links to `PaywallScreen`.

3.  **Core Engine -> Monetization (Coupled Logic):**
    - The `_aiGenerateOutline` function (Engine) explicitly checks premium status (Monetization) before proceeding.
    - This coupling is currently implemented *inside* the UI layer (`AIGeneratePage`), creating a triangular dependency.

---

## Coupling Risk List

1.  **Monolithic UI Controller (`AIGeneratePage`):**
    - **Risk:** High.
    - **Description:** The `_AIGeneratePageState` class manages UI state, executes raw HTTP requests for AI, handles file I/O for export, and manages subscription checks.
    - **Impact:** Hard to test engine logic in isolation. UI changes risk breaking generation logic.

2.  **Scattered Configuration:**
    - **Risk:** Medium.
    - **Description:** API Keys are in `lib/utility/apikey.dart` (OpenAI) and `lib/src/constant.dart` (RevenueCat), but access patterns vary. `AIConfig` uses `String.fromEnvironment`, while `constant.dart` has placeholders/hardcoded strings.

3.  **Engine Logic in UI Widgets:**
    - **Risk:** High.
    - **Description:** `_generateImageWithRetries` contains complex retry logic with `Future.delayed` directly inside a State class.
    - **Impact:** Logic is bound to the Widget lifecycle. If the widget is disposed during generation, it may cause unhandled exceptions or state errors.

4.  **Implicit Monetization Fallback:**
    - **Risk:** Medium.
    - **Description:** `_readPremiumStatus` caches to `SharedPreferences` locally within the UI method.
    - **Impact:** Inconsistent premium status source of truth if other parts of the app access RevenueCat directly without checking this specific cache key.

5.  **Hardcoded Strings & Prompts:**
    - **Risk:** Low-Medium.
    - **Description:** Prompt templates and JSON schemas are hardcoded strings inside `_generateOutline`.
    - **Impact:** Difficult to modify prompts or support multiple languages without modifying the UI file.
