# Navigation Blueprint: Tome AI

## 1. Route Structure (GoRouter)

### A. Top-Level Routes
These routes exist at the root level, outside the main application shell.

- `/splash`: **Initial Route**. Checks onboarding status.
- `/welcome`: **Onboarding Start**. (Transition: Fade).
- `/role`: **Onboarding Step 2**. (Transition: Slide Right).
- `/paywall`: **Global Modal**. Can be pushed from anywhere. (Transition: BottomSheet/FullscreenDialog).

### B. Shell Route (`/`)
Stateful Shell (`TomeShell`) containing the persistent Bottom Navigation Bar.

- **Tab 1: Library** (`/library`)
  - Displays list of recent presentations.
  - **Sub-route:** `/library/editor/:id` (Pushes *Unified Editor* on top of Shell).

- **Tab 2: Create** (Functional Tab)
  - The middle "FAB" button does *not* navigate to a tab.
  - **Action:** Opens `/wizard` (Modal FullScreen).

- **Tab 3: Archive** (`/archive`)
  - Displays settings and subscription management.

### C. Creation Wizard Flow (`/wizard`)
A nested navigation stack (or a linear flow controller) presented as a full-screen modal.

- `/wizard/intent`: Step 1 (Style).
- `/wizard/subject`: Step 2 (Topic).
- `/wizard/depth`: Step 3 (Slide Count).
- `/wizard/gate`: Step 4 (Premium Check -> Loading).
- **Exit:**
  - *Cancel:* Returns to `/library`.
  - *Success:* Replaces `/wizard` stack with `/library/editor/:new_id`.

---

## 2. Navigation Model details

### Stack vs Tab
- **Main App:** Uses **Tab-based** navigation for distinct contexts (Library vs Archive).
- **Editor:** Uses **Stack-based** navigation (pushed *over* the shell). The Editor requires maximum screen real estate; the bottom nav should be hidden.
- **Wizard:** Uses **Modal Stack**. It is a temporary, focused task.

### Nested Navigation
- The **Wizard** should likely use a sub-navigator or a `PageController` within a single modal route to manage the linear progression (Next/Back) without polluting the global history stack.
- The **Editor** is a terminal node; it does not have deep internal navigation (single page scroll).

---

## 3. Back Behavior Logic

### A. Wizard Flow
- **Hardware Back / Top-Left Back:**
  - If in Step > 1: Go to previous step.
  - If in Step 1: Show "Discard Draft?" Dialog.
    - *Confirm:* Close Wizard, return to `/library`.
    - *Cancel:* Stay in Wizard.

### B. Unified Editor
- **Hardware Back / Top-Left Back:**
  - Check `_isDirty` (unsaved changes).
  - If Dirty: Autosave is triggered (Engine contract mentions autosave, so explicit "Save?" dialog might be redundant, but a visual "Saving..." indicator is needed before pop).
  - **Action:** Pop to `/library`.

### C. Onboarding
- **Role Selection:**
  - **Back:** Returns to Welcome.
- **Welcome:**
  - **Back:** Exits App (System default).

### D. Paywall Overlay
- **Dismiss/Back:**
  - Returns to the context that triggered it (e.g., Wizard Gate or Editor Visualize button).
  - Does *not* grant access.

---

## 4. Deep Linking Strategy (Future Proofing)
- `tome://library`: Opens Home.
- `tome://create`: Opens Wizard immediately.
- `tome://editor?id=123`: Opens specific presentation.
- `tome://settings`: Opens Archive.

## 5. Transition Standards
- **Tabs:** No animation (Instant switch).
- **Wizard:** `ModalBottomSheet` style (Slide up from bottom) or `CupertinoFullscreenDialog` (Slide up).
- **Wizard Steps:** Horizontal Slide (Right to Left for Next, Left to Right for Back).
- **Editor:** `CupertinoPageRoute` (Slide from right) or Zoom/Fade for "Opening a book" feel.
