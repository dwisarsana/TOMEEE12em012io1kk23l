# Tome AI — Architectural Flows & User Journeys

**Status**: Proposal (Approved)
**Scope**: Core App Flows + AI Integration + Data Persistence

---

## 1. Anti-Pattern Elimination Strategy

| "AI Presentation" (Legacy) | "Tome AI" (New Architecture) | Justification |
| :--- | :--- | :--- |
| **Dual Editors** (`EditorPage`, `AIGeneratePage`) | **Unified Editor** (`/editor`) | Eliminates duplicate logic. AI is a tool *within* the editor, not a separate silo. |
| **Discarded Onboarding** | **Persisted Preferences** | User intent (Role, Goal) seeds the initial "Quick Start" templates. |
| **Non-Persistent Nav** | **Stateful Shell Route** | Using a persistent `Scaffold` or Shell Route keeps the bottom nav and tab state alive. |
| **Memory-Only Images** | **Local File Persistence** | Images are saved to `ApplicationDocumentsDirectory` immediately. References stored in DB/Prefs. |
| **Ambiguous Actions** | **Clear Primary/Secondary** | Strict hierarchy: "Create" is Primary. "Edit" is Secondary. "Delete" is Destructive/Ghost. |
| **Dead Screens** | **Removed** | All unused RevenueCat samples and dead logic are purged. |

---

## 2. Core User Journeys

### Journey A: First Launch (Onboarding)
*Goal: Understand the user and land them on a personalized dashboard.*

1.  **Splash Screen** (`/splash`)
    *   **Action**: Auto-check `onboarding_done` flag.
    *   **Logic**:
        *   If `true` → Navigate to `/home` (Replace).
        *   If `false` → Navigate to `/onboarding` (Replace).
    *   **Anti-Pattern Fix**: No "LaunchGate" flicker. Smooth transition.

2.  **Onboarding** (`/onboarding`)
    *   **Step 1: Welcome**: "Tome AI" branding + Value Prop.
    *   **Step 2: Role Selection**: "Student", "Professional", "Creative". (Saved to Prefs: `user_role`).
    *   **Step 3: Goal Selection**: "Pitch Deck", "Lecture", "Social Media". (Saved to Prefs: `user_goal`).
    *   **Step 4: Completion**: "All Set".
    *   **Action**: Set `onboarding_done = true`. Navigate to `/home`.

### Journey B: Dashboard & Management
*Goal: Quick access to recent work and new creations.*

1.  **Home / Dashboard** (`/home`)
    *   **State**: Persistent.
    *   **Header**: "Good Morning, [Role]".
    *   **Section 1: Quick Create** (Horizontal Scroll).
        *   Card: "Blank Deck" (New).
        *   Card: "Generate with AI" (New + Modal).
        *   Card: "Import PDF" (Future).
    *   **Section 2: Recent Decks** (Vertical List/Grid).
        *   **Empty State**: "No decks yet. Tap '+' to create your first Tome."
        *   **Action**: Tap opens `/editor`. Long-press shows Context Menu (Rename, Delete, Share).
    *   **FAB**: "New Tome" (Primary Action). Opens "Create Modal".

### Journey C: The Creation Loop (Unified)
*Goal: Seamless transition between AI generation and manual refinement.*

1.  **Create Action** (Modal / Bottom Sheet)
    *   **Option 1: "Start from Scratch"**
        *   Logic: Create new `Presentation` object -> Save to Disk -> Nav to `/editor` with ID.
    *   **Option 2: "Generate with Tome AI"**
        *   Logic: Open **AI Input Sheet** (Overlay).

2.  **AI Input Sheet** (Overlay)
    *   **Input**: "Topic / Prompt".
    *   **Context**: "Tone" (Professional, Fun), "Length" (5-15 slides).
    *   **Action**: "Generate Outline" (Primary).
    *   **Loading**: "Thinking..." (Glass overlay).
    *   **Result**: Show **Outline Preview**.

3.  **Outline Review** (Modal)
    *   **Display**: List of slide titles/bullets.
    *   **Actions**: "Edit Item", "Reorder", "Regenerate".
    *   **Final Action**: "Create Presentation" -> Generates slides -> Nav to `/editor`.

4.  **Unified Editor** (`/editor/:id`)
    *   **Layout**: Sidebar (Slides) + Canvas (Current Slide) + Toolbar.
    *   **Sidebar**:
        *   Drag-and-drop reordering.
        *   "Add Slide" (Ghost button).
    *   **Canvas**:
        *   Title (Editable Text).
        *   Body (Editable Text / Bullets).
        *   Image (Placeholder / AI Image / Upload).
    *   **Toolbar (Bottom/Floating)**:
        *   "AI Assist" (Magic Wand): Contextual actions for *current slide* (Rewrite, Suggest Image).
        *   "Theme": Change palette.
        *   "Layout": Change slide layout.
    *   **Header Actions**: "Play" (Preview), "Share" (Export).

### Journey D: Export & Share
*Goal: Deliver value outside the app.*

1.  **Export Sheet** (Modal)
    *   **Format Selection**: "PDF" (Document), "PPTX" (Editable).
    *   **Preview**: Small thumbnail of the output.
    *   **Action**: "Share File" (iOS Share Sheet).
    *   **Logic**:
        *   Generate file in temp directory.
        *   Call `Share.shareXFiles`.
        *   Clean up temp file on completion.

---

## 3. Data Flow & Persistence Rules

1.  **Autosave Strategy**:
    *   **Trigger**: On every keystroke (debounced 1s) OR on `dispose` (leaving screen) OR on `AppLifecycleState.paused`.
    *   **Target**: Local File System (JSON) + SQLite (Metadata Index).
    *   **Images**: Saved as `DeckID_SlideID.png` in `ApplicationDocumentsDirectory`. Not in JSON.

2.  **State Management**:
    *   **Editor**: Single source of truth is the `Presentation` object in memory, synced to disk.
    *   **Undo/Redo**: In-memory stack `List<PresentationState>`. Cleared on exit.

3.  **Error Handling**:
    *   **AI Failure**: Toast/Snackbar "Tome AI is taking a nap. Try again." (Do not crash).
    *   **Export Failure**: Dialog "Could not export. Check storage space."

---

## 4. Mandatory Checks (Pre-Commit)

*   [ ] **Check 1**: Does `/editor` handle *both* new blank decks and AI-generated decks? (Yes, via ID argument).
*   [ ] **Check 2**: Is the `EditorPage` code (legacy) merged with `AIGeneratePage` features? (Yes, mapped in "Unified Editor").
*   [ ] **Check 3**: Are "AI Presentation" strings removed from the Splash/Onboarding text? (Yes, replaced with "Tome AI").
*   [ ] **Check 4**: Is the "Back" button behavior consistent? (Yes, Editor -> Home always saves).
*   [ ] **Check 5**: Are empty states defined for "Recent Decks"? (Yes).
