# State Management: Tome AI

## Decision: Riverpod
- **Why:** Robust compile-time safety, no `BuildContext` dependency for logic, excellent testability, and built-in support for async data (`AsyncValue`).
- **Implementation:** `flutter_riverpod` + `riverpod_annotation` (for code generation).

---

## 1. State Diagram

### A. Global Scope (Root ProviderContainer)
*Alive for the entire app lifecycle.*

| Provider Name | Type | Responsibility | Source of Truth |
| :--- | :--- | :--- | :--- |
| `userProvider` | `AsyncNotifier<User>` | User ID, RevenueCat `CustomerInfo`, Entitlement Status (`isPremium`), Onboarding Flags (`role`, `goal`). | RevenueCat SDK + SharedPreferences |
| `libraryProvider` | `AsyncNotifier<List<Presentation>>` | List of recent presentations (metadata only). Sorts by `updatedAt`. | `Storage` (Local JSON) |
| `themeProvider` | `Notifier<ThemeMode>` | Light/Dark mode preference. | SharedPreferences |

### B. Feature Scope (AutoDispose)
*Alive only when the specific feature is active.*

| Provider Name | Type | Responsibility | Source of Truth |
| :--- | :--- | :--- | :--- |
| `wizardProvider` | `Notifier<WizardState>` | Transient state for creation flow (`topic`, `style`, `slideCount`, `stepIndex`). | Memory (Input Form) |
| `editorProvider(id)` | `FamilyAsyncNotifier<Presentation>` | The full presentation being edited. Handles `slides`, `text`, `images`. | `Storage` (Full Load) |
| `saveStatusProvider(id)` | `Provider<SaveStatus>` | derived from `editorProvider`: `saved`, `saving`, `error`. | Memory |

---

## 2. Data Flow Map

### Scenario 1: App Launch & Onboarding
1.  **App Start:** `ProviderScope` initializes.
2.  `userProvider` hydrates:
    - Calls `Purchases.getCustomerInfo()`.
    - Reads `onboarding_done` from Prefs.
3.  **Router:** Listens to `userProvider`.
    - If `onboarding_done == false` -> Redirect to `/welcome`.
    - If `onboarding_done == true` -> Redirect to `/library`.

### Scenario 2: Creating a Tome (Wizard)
1.  **User Input:** Updates `wizardProvider` (Style -> Topic -> Count).
2.  **Gate Check:** `wizardProvider` reads `userProvider.value.isPremium`.
    - If `false`: Trigger Paywall.
    - If `true`: Proceed.
3.  **Generation:**
    - `wizardProvider` calls Engine (`_generateOutline`).
    - **Result:** A new `Presentation` object.
4.  **Handoff:**
    - `wizardProvider` saves the new `Presentation` via `libraryProvider.add()`.
    - Router navigates to `/editor/:id`.
    - `wizardProvider` is disposed (state cleared).

### Scenario 3: Editing & Autosave
1.  **Editor Launch:** `editorProvider(id)` loads full JSON from `Storage`.
2.  **Modification:** User edits text or generates image.
    - `editorProvider` updates its internal state (immutable copy).
3.  **Autosave (Debounced):**
    - `editorProvider` listens to its own changes.
    - After 600ms silence, writes to `Storage`.
    - Updates `libraryProvider` (to refresh the "Last Updated" timestamp in the list).

### Scenario 4: Purchasing Premium
1.  **Paywall:** User completes purchase via RevenueCat UI.
2.  **Listener:** `Purchases` SDK emits update.
3.  `userProvider` invalidates/refreshes self.
4.  **UI:** Any active "Lock" icons or Paywall overlays reactively dismiss/unlock.

---

## 3. Rules & Constraints
- **No `setState` for Business Logic:** UI widgets (Consumers) only watch providers. They do not hold logical state.
- **No Duplicated State:**
    - The `Presentation` object in `libraryProvider` is a *summary* (metadata).
    - The `Presentation` object in `editorProvider` is the *full* data.
    - When `editorProvider` saves, it explicitly notifies `libraryProvider` to update the summary, ensuring consistency.
- **Async Handling:** All I/O (Network, Disk) must be wrapped in `AsyncValue` to handle Loading/Error states gracefully in the UI.
