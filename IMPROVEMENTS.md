# Tome AI — Product Improvements (No Bloat)

**Goal**: Polish "Tome AI" with smart defaults and micro-interactions without changing the core feature set.

---

## 1. Smart Defaults & Predictive UI

| Improvement | "Tome AI" Benefit | Implementation Detail | Risk |
| :--- | :--- | :--- | :--- |
| **Smart Title Autofill** | Reduces manual typing. If a user pastes text into the body, the first sentence becomes the title if empty. | `TextEditingController` listener on Body. If `Title.isEmpty` & `Body.hasText`, promote first 6 words. | **Low**. Might annoy if user wants custom title (Mitigation: Only trigger once). |
| **Predictive Export Name** | Eliminates generic "Untitled.pdf" files. | Default filename = `"${SanitizedTitle}_${Date}.pdf"` instead of `presentation.pdf`. | **Low**. Safe default. |
| **"Continue" on Launch** | Gets user back to work instantly. Bypasses Home if app was killed recently. | Store `last_edited_id` in Prefs. On launch, show "Resume editing [Title]?" snackbar/toast. | **Medium**. Can be annoying if user wanted to start new. Make it a passive toast action. |
| **Auto-Theme by Tone** | Visuals match content context automatically. | If AI Prompt contains "Fun/Creative", select `Colorful` palette. If "Professional/Business", select `Blue/Slate`. | **Low**. Heuristic mapping. User can override. |

---

## 2. Micro-Features (Quality of Life)

| Improvement | "Tome AI" Benefit | Implementation Detail | Risk |
| :--- | :--- | :--- | :--- |
| **Auto-Save Indicator** | Replaces the intrusive "Saved!" snackbar with a subtle UI state. | Use a small cloud checkmark icon in the App Bar. State: `Saving...` (Spin), `Saved` (Check). | **Low**. Pure UI change. |
| **Slide Reorder Haptics** | tactile confirmation of structural changes. | `HapticFeedback.selectionClick` during drag, `heavyImpact` on drop. | **Low**. iOS standard. |
| **Skeleton Loading** | Perceived performance improvement over spinning loaders. | Replace `CircularProgressIndicator` with `Shimmer` effect on Slide Cards during AI generation. | **Low**. Visual polish only. |
| **Contextual Keyboard** | Faster text entry. | Use `textCapitalization: TextCapitalization.sentences` for Body, `.words` for Title. | **Zero**. Standard platform behavior. |
| **Image Placeholder Art** | Better than empty gray boxes. | Use abstract geometric SVG patterns (generated deterministically from Slide ID) as placeholders. | **Low**. aesthetic improvement. |

---

## 3. "AI Presentation" Helpers (Logic Fixes)

| Improvement | "Tome AI" Benefit | Implementation Detail | Risk |
| :--- | :--- | :--- | :--- |
| **Slide Undo/Redo** | Critical safety net for "Tome AI" creation. | `List<PresentationState>` stack. Cap at 20 steps. Snapshot on "Stop Typing" debounce. | **High**. Complex state management. Needs rigorous testing to avoid memory leaks. |
| **Clipboard Image Paste** | Desktop-class capability on mobile. | Listen to `Paste` intent. If clipboard has image data, insert into current slide. | **Medium**. Platform handling varies (iOS permissions). |
| **Offline Mode Detect** | Prevents AI frustration. | If `Connectivity().none`, disable AI buttons & show "Offline Mode" badge. | **Low**. Better UX than failing HTTP requests. |
| **Text Fit / Auto-Size** | Prevents overflow in "Tome AI" slides. | Use `AutoSizeText` for Slide Titles to scale down instead of clipping. | **Low**. Standard package usage. |

---

## 4. Risk Assessment Summary

*   **Low Risk**: Most visual polish items (Haptics, Skeletons, Filenames) are safe and high-value.
*   **Medium Risk**: "Resume" and "Clipboard" features touch platform-specific behaviors that need testing.
*   **High Risk**: **Undo/Redo**. This is a significant logic addition. It is "Allowed" as a helper/safety net but requires careful implementation to not bloat the `Editor` class further. *Recommendation: Implement a simplified version (Undo Delete Slide only) first.*
