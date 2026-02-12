# Design System: Tome AI

## Philosophy: "Magical Realism"
A fusion of clean productivity software with the tactile warmth of a high-end sketchbook. It feels grounded but capable of magic.
- **Keywords:** Ethereal, Tactile, Focused, Fluid.
- **Reference:** iOS 17 (Glass), Notion (Cleanliness), Arc Browser (Fluidity).

---

## 1. Color System

### Primary (The Magic)
- **Mystic Indigo:** `#4F46E5` (Primary Action, Brand)
- **Ethereal Purple:** `#818CF8` (Gradient Start)
- **Cyan Light:** `#22D3EE` (Gradient End - "Magic" accents)

### Neutral (The Paper)
- **Ink Black:** `#0F172A` (Primary Text)
- **Slate Grey:** `#64748B` (Secondary Text, Icons)
- **Wash White:** `#F8FAFC` (App Background - slightly cool off-white)
- **Pure White:** `#FFFFFF` (Card Surfaces)

### Semantic
- **Error:** `#EF4444` (Soft Red)
- **Success:** `#10B981` (Emerald)
- **Warning:** `#F59E0B` (Amber)

---

## 2. Typography Scale

### Font Family
- **Headings (Serif):** `Fraunces` or `Playfair Display`. Adds a "Storybook" feel.
- **UI & Body (Sans):** `Plus Jakarta Sans` or `Inter`. Clean, geometric, legible.

### Scale
- **Display 1:** 32sp, Serif, Bold (Welcome Screens)
- **Heading 2:** 24sp, Serif, SemiBold (Section Headers)
- **Heading 3:** 20sp, Sans, Bold (Card Titles)
- **Body Large:** 17sp, Sans, Regular (Input Fields, Main Text)
- **Body Medium:** 15sp, Sans, Medium (Buttons, Labels)
- **Caption:** 12sp, Sans, Regular (Metadata)

---

## 3. Spacing Rules
- **Base Unit:** 4pt.
- **Grid:** 8pt soft grid.
- **Margins:** 20pt (Standard iOS side padding).
- **Gutter:** 12pt.

### Common Spacers
- `xs`: 4pt
- `s`: 8pt
- `m`: 16pt
- `l`: 24pt
- `xl`: 32pt
- `xxl`: 48pt (Section breaks)

---

## 4. Component System

### Cards ("Pages")
- **Shape:** Rounded Rect `BorderRadius.circular(20)`.
- **Surface:** Pure White.
- **Border:** `Border.all(color: Colors.black.withOpacity(0.06))`.
- **Interaction:** Scale down to 98% on press (`Transform.scale`).

### Buttons
- **Primary (FAB/Action):**
  - Shape: Stadium (`Radius.circular(100)`).
  - Background: Mystic Indigo.
  - Shadow: Soft colored shadow (Indigo with opacity 0.4).
- **Secondary (Ghost):**
  - No background.
  - Text: Slate Grey.

### Inputs
- **Style:** "Invisible" until focused, or soft gray fill.
- **Focus:** No harsh outlines. Soft indigo glow or bottom border.
- **Text:** Large, confident typography (17sp+).

### Glassmorphism (Overlays)
- **Usage:** Paywalls, Loading States, Navigation Bar.
- **Blur:** `ImageFilter.blur(sigmaX: 16, sigmaY: 16)`.
- **Opacity:** White with 0.7 opacity.
- **Border:** White with 0.2 opacity.

---

## 5. Elevation Model (Shadows)
Instead of standard Material elevation, use "Diffuse Light".

- **Level 1 (Cards):**
  - `BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4))`
- **Level 2 (Floating/FAB):**
  - `BoxShadow(color: Color(0x254F46E5), blurRadius: 20, offset: Offset(0, 8))`
  - *Note: Colored shadow matches the element.*
- **Level 3 (Modals/Paywall):**
  - `BoxShadow(color: Color(0x1F000000), blurRadius: 40, offset: Offset(0, 20))`

---

## 6. Dark Mode Behavior
*Inverts the "Paper" metaphor to "Night Sky".*

- **Background:** `#020617` (Deepest Slate).
- **Surface:** `#1E293B` (Dark Slate).
- **Text:** `#F1F5F9` (Off-white).
- **Primary:** Remains `#4F46E5` (Glows more in dark).
- **Glass:** Black with 0.6 opacity.
