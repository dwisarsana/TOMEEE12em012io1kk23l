# Tome AI — Motion & Animation System

**Philosophy**: Motion in "Tome AI" is not decoration; it is communication. It guides the eye, confirms actions, and masks latency with premium fluidity.

---

## 1. Motion Principles

*   **Subtle & Premium**: Animations should feel like "physics", not cartoons. Use springs and ease-out curves.
*   **Guide, Don't Distract**: Motion should originate from the user's touch and lead to the result.
*   **iOS Standard**: Respect platform conventions (swipe-to-back, overscroll stretch) but elevate them with custom micro-interactions.

---

## 2. Animation Map

### A. Screen Transitions

| Transition Type | Implementation | Context |
| :--- | :--- | :--- |
| **Standard Navigation** | `CupertinoPageRoute` | List -> Detail (e.g., Home -> Settings). |
| **Modal Presentation** | `showModalBottomSheet` | Create -> AI Input, Home -> Create Menu. |
| **Hero Expansion** | `Hero` widget | Slide Thumbnail (Home) -> Editor Canvas. The card expands to fill the screen. |
| **Fade Through** | `PageTransitionSwitcher` | Switching between Editor Tabs (if any) or Onboarding steps. |

### B. Micro-Interactions & Feedback

| Interaction | Animation | Haptic | Duration | Curve |
| :--- | :--- | :--- | :--- | :--- |
| **Button Tap (Primary)** | Scale down to 96% | `lightImpact` | 100ms | `easeInOut` |
| **Card Tap** | Scale down to 98% | `selectionClick` | 100ms | `easeInOut` |
| **Toggle Switch** | Smooth color fill + knob slide | `selectionClick` | 200ms | `easeOutCubic` |
| **Drag & Drop** | Lift (Scale 105% + Shadow) | `mediumImpact` (Start), `heavy` (Drop) | 200ms | `spring` |
| **Error Shake** | Horizontal shake (x-axis) | `heavyImpact` | 400ms | `elasticIn` |

### C. Loading & AI States

| State | Visual | Loop Duration |
| :--- | :--- | :--- |
| **AI Generating** | **Breathing Gradient**: A soft, blurred multi-color gradient mesh that slowly rotates and pulses behind a glass panel. | 3000ms (Slow) |
| **Image Loading** | **Shimmer Skeleton**: A diagonal light sweep across a gray placeholder. | 1500ms |
| **List Loading** | **Staggered Fade-In**: Items slide up (10px) and fade in, with a 50ms delay per item. | 300ms (Per item) |

---

## 3. Timing & Easing Guidelines

### Durations
*   **Instant (Feedback)**: `100ms` — Buttons, Toggles.
*   **Fast (UI Adjustments)**: `200ms` — expanding cards, showing toasts.
*   **Normal (Transitions)**: `350ms` — Navigation, Modals (matches iOS default).
*   **Slow (Atmosphere)**: `600ms+` — Background loops, AI "thinking" states.

### Curves
*   **Entrance**: `Curves.easeOutCubic` — Starts fast, lands soft. Use for Modals, Toasts.
*   **Exit**: `Curves.easeInCubic` — Starts slow, accelerates out. Use for dismissing dialogs.
*   **Natural**: `SpringSimulation` — For anything touch-driven (dragging slides).

---

## 4. Implementation Notes for "Tome AI"

*   **Package**: Use `flutter_animate` for declarative, chainable animations (already in `pubspec.yaml`).
*   **Performance**: Avoid animating `width/height` or `padding`. Animate `Transform.scale`, `Opacity`, and `Transform.translate` for 60fps performance on iOS.
*   **Respect Settings**: Check `MediaQuery.disableAnimations` to respect users who prefer reduced motion.

---
