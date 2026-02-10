# Project Analysis: AI Presentation -> Tome AI

## 1. Core Features (Must-Keep for Project "Tome AI")

*   **Presentation Creation**: Manual slide creation and editing.
*   **AI Generation**: AI-powered outline and slide generation (text + image).
*   **Presentation Editor**: Rich text editing, image attachment, slide reordering/deletion.
*   **Export**: Export to PPTX (PowerPoint) and PDF.
*   **Templates**: Pre-defined slide templates (currently static).
*   **My Presentations (Home)**: List of recent/saved presentations with local persistence.
*   **Preview/Presenter Mode**: In-app slideshow viewer.
*   **Authentication**: Sign in with Apple (iOS only).
*   **Premium/IAP**: RevenueCat integration for subscription gating (AI features).

## 2. Screen List & Purpose

| Screen | File | Purpose |
| :--- | :--- | :--- |
| **SplashScreen** | `lib/opening/splash.dart` | Initial launch screen, checks onboarding status. |
| **OnboardingChatScreen** | `lib/opening/onboards.dart` | Interactive chat to collect user preferences (data currently discarded). |
| **HomePage** | `lib/ui/homepage.dart` | Main dashboard. Lists recent presentations, templates, and search. |
| **EditorPage** | `lib/ui/editor.dart` | Manual presentation editor. Handles slide manipulation and saving. |
| **AIGeneratePage** | `lib/ui/ai_generate.dart` | AI-focused editor. Handles AI outline generation, image generation, and editing. |
| **TemplatesPage** | `lib/ui/template.dart` | Gallery of available templates (currently hardcoded). |
| **MorePage (Settings)** | `lib/ui/setting.dart` | User profile, premium status, legal links, restore purchase. |
| **_PreviewScreen** | `lib/ui/editor.dart` | Internal widget for presenting slides from the manual editor. |
| **_PresenterView** | `lib/ui/ai_generate.dart` | Internal widget for presenting slides from the AI editor. |
| **_HomeSearchDelegate** | `lib/ui/homepage.dart` | Search interface for presentations. |

## 3. Navigation & Routing Structure

*   **Entry Point**: `lib/main.dart` -> `AIPresentationApp`.
*   **Route Management**: `MaterialApp` with named routes:
    *   `/`: `_LaunchGate` (Stateful logic to switch between Splash, Onboarding, and Home).
    *   `/home`: `HomePage` (Implicitly handled by `_LaunchGate`).
    *   `/editor`: `EditorPage`.
    *   `/templates`: `TemplatesPage`.
    *   `/settings`: `MorePage`.
    *   `/ai`: `AIGeneratePage`.
*   **Navigation Method**: `Navigator.pushNamed` is primarily used. `Navigator.push` with `MaterialPageRoute` is used for internal screens like Preview.
*   **Tab/Bottom Nav**: `HomePage` uses a `BottomNavigationBar` but navigation to other sections (AI, Templates, Settings) pushes new routes rather than switching tabs in place.

## 4. State Management & Data Flow

*   **State Management**: Purely `setState` within `StatefulWidget`s. No global state management library (Provider, Bloc, etc.) is used.
*   **Data Persistence**:
    *   **Presentations**: Serialized to JSON and stored in `SharedPreferences` (Key: `presentation_<id>`).
    *   **List of IDs**: Stored in `SharedPreferences` (Key: `presentation_ids`).
    *   **User Preferences**: `onboarding_done` (bool), `is_logged_in` (bool), `user_email` (String) in `SharedPreferences`.
    *   **Premium Status**: `is_premium` (bool) in `SharedPreferences` (cached from RevenueCat).
*   **Data Flow**:
    *   Data is loaded from `SharedPreferences` in `initState` or via `FutureBuilder`.
    *   Updates are written back to `SharedPreferences` immediately or debounced (e.g., autosave).
    *   Images are stored in-memory (`Map<String, Uint8List>`) within the editor widgets and are **NOT persisted** to disk.

## 5. External Dependencies & SDKs

*   **UI/Animation**: `flutter_animate`, `google_fonts`, `flutter_lints`.
*   **Storage/Data**: `shared_preferences`, `path_provider`.
*   **Networking/API**: `http` (for OpenAI).
*   **Export**: `dart_pptx` (PPTX generation), `pdf` (PDF generation), `open_filex` (file opening).
*   **Media**: `image_picker` (gallery access).
*   **Auth/IAP**: `sign_in_with_apple`, `purchases_flutter` (RevenueCat), `purchases_ui_flutter`.
*   **Utils**: `share_plus` (sharing files), `url_launcher`, `in_app_review`.

## 6. "AI Presentation" Assumptions Baked into Code

*   **App Name**: "AI Presentation" is hardcoded in `lib/main.dart` (`title`), `lib/opening/splash.dart` (Title text), `lib/opening/onboards.dart` (Welcome message), and `lib/ui/setting.dart` ("Brand palette — AI Presentation", "Thanks for supporting AI Presentation!").
*   **Package Name**: `aipresentation` is used in `pubspec.yaml` and as the package import prefix (`package:aipresentation/...`).
*   **Bundle Identifier**:
    *   Android: `com.example.aipresentation` (in `build.gradle` and `AndroidManifest.xml`).
    *   iOS: `com.ai.slides.presentation.ppt.pptx` (in `project.pbxproj`), though `Info.plist` references `$(PRODUCT_BUNDLE_IDENTIFIER)`.
*   **Display Name**: "AI Slides" (in `Info.plist`), "AI Presentation" (in `AndroidManifest.xml`).
*   **Export Author**: `pres.author = 'Presentation AI'` in `lib/ui/ai_generate.dart`.
*   **Assets**: `assets/splash.png` (likely branded).

## 7. Hidden Coupling or Fragile Logic

*   **Image Persistence**: Images added to slides are stored in `_slideImages` map in memory. If the app is killed or the user navigates back without exporting, **all images are lost**.
*   **Dual Editors**: `EditorPage` and `AIGeneratePage` share significant logic (slide rendering, saving, renaming) but are separate, duplicated files. Changes to one might not reflect in the other.
*   **Premium Check**: Logic for checking premium status is duplicated in `lib/src/constant.dart`, `lib/ui/ai_generate.dart`, and `lib/ui/setting.dart`.
*   **API Key**: OpenAI API key is hardcoded in `lib/utility/apikey.dart` and directly used in `lib/ui/ai_generate.dart`.
*   **Hardcoded Templates**: Templates in `lib/ui/template.dart` are hardcoded widgets, not loaded from data.

## 8. Security Posture

*   **API Keys**:
    *   **OpenAI Key**: **CRITICAL**. Hardcoded in `lib/utility/apikey.dart`. Exposed in codebase and binary.
    *   **RevenueCat Keys**: Public keys are visible in `lib/src/constant.dart`.
*   **Authentication**:
    *   Relies on `is_logged_in` boolean in `SharedPreferences`. Easily manipulated on rooted/jailbroken devices.
    *   No backend validation of the user session.
*   **Data Storage**:
    *   Presentations and user data are stored in `SharedPreferences` (XML/Plist), which is readable on rooted devices.
    *   Sensitive data (email) is stored in plain text.
*   **Network**:
    *   `kNetworkLog = true` in `lib/ui/ai_generate.dart` logs full request/response bodies (including potential PII or content) to the console in release mode if not stripped.
    *   No certificate pinning.
