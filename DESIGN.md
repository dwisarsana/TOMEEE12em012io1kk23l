# Tome AI — Design System

## 1. Design Direction
**Philosophy**: Modern, fluid, intelligent. "Tome AI" is not just a tool; it's a creative partner.
**Visual Style**: iOS 17+ inspired. Heavy use of soft depth (glassmorphism/blur), large typography, and subtle gradients.
**Interaction**: Gestural, fluid transitions, haptic feedback.
**Mode**: Light/Dark adaptive (defaulting to a calm "Daylight" mode for the MVP).

---

## 2. Color System

### Primary Palette (Calm Premium)
| Token | Hex | Usage |
| :--- | :--- | :--- |
| `primary` | `#4F46E5` (Indigo 600) | Primary actions, active states, key brand elements. |
| `onPrimary` | `#FFFFFF` | Text on primary backgrounds. |
| `secondary` | `#818CF8` (Indigo 400) | Accents, secondary actions. |
| `tertiary` | `#A5B4FC` (Indigo 200) | Subtle highlights, focus rings. |

### Neutral / Surface Palette (Soft & Glass)
| Token | Hex | Usage |
| :--- | :--- | :--- |
| `surfaceGlass` | `#FFFFFF` (Opacity 80%) | Glass panels, cards, bottom sheets (blur: 20px). |
| `background` | `#F8FAFC` (Slate 50) | Main app background. |
| `surface` | `#FFFFFF` | Solid cards, inputs, dialogs. |
| `border` | `#E2E8F0` (Slate 200) | Subtle dividers, input borders. |

### Text / Content
| Token | Hex | Usage |
| :--- | :--- | :--- |
| `textPrimary` | `#0F172A` (Slate 900) | Headings, main body text. |
| `textSecondary` | `#64748B` (Slate 500) | Subtitles, captions, metadata. |
| `textTertiary` | `#94A3B8` (Slate 400) | Placeholders, disabled text. |

### Semantic
| Token | Hex | Usage |
| :--- | :--- | :--- |
| `error` | `#EF4444` (Red 500) | Critical errors, destructive actions. |
| `success` | `#10B981` (Emerald 500) | Success states, safe actions. |
| `warning` | `#F59E0B` (Amber 500) | Warnings, premium features (gold accent). |

---

## 3. Typography Scale (SF Pro / System)

| Role | Weight | Size | Line Height | Usage |
| :--- | :--- | :--- | :--- | :--- |
| `Display` | Bold (700) | 34pt | 40pt | Large screen titles (e.g., "Good Morning"). |
| `H1` | Semibold (600) | 28pt | 34pt | Section headers, slide titles. |
| `H2` | Semibold (600) | 22pt | 28pt | Card titles, modal headers. |
| `H3` | Medium (500) | 20pt | 24pt | Sub-sections. |
| `BodyLarge` | Regular (400) | 17pt | 24pt | Main content, reading text. |
| `Body` | Regular (400) | 15pt | 22pt | Standard UI text, list items. |
| `Caption` | Medium (500) | 13pt | 18pt | Metadata, labels, footnotes. |
| `Small` | Medium (500) | 11pt | 14pt | Tags, timestamps. |

---

## 4. Component System

### Buttons
*   **Primary Button**:
    *   Background: `primary` gradient (Indigo 600 -> Indigo 500).
    *   Radius: `16px` (Continuous curve).
    *   Height: `56px`.
    *   Text: `Body` (Semibold), White.
    *   Shadow: `0px 4px 12px rgba(79, 70, 229, 0.3)`.
*   **Secondary Button**:
    *   Background: `surface` or `surfaceGlass`.
    *   Border: `1px solid border`.
    *   Text: `textPrimary`.
*   **Ghost Button**:
    *   Background: Transparent.
    *   Text: `primary` or `textSecondary`.

### Cards & Surfaces
*   **Glass Card**:
    *   Background: `rgba(255, 255, 255, 0.7)`.
    *   Blur: `BackdropFilter(sigmaX: 16, sigmaY: 16)`.
    *   Border: `1px solid rgba(255, 255, 255, 0.5)`.
    *   Shadow: `0px 8px 32px rgba(0, 0, 0, 0.04)`.
    *   Radius: `24px`.
*   **Solid Card**:
    *   Background: `#FFFFFF`.
    *   Shadow: `0px 2px 8px rgba(0, 0, 0, 0.04)`.
    *   Radius: `20px`.

### Inputs
*   **Text Field**:
    *   Background: `#F1F5F9` (Slate 100).
    *   Radius: `12px`.
    *   Border: None (Focus: `2px solid primary`).
    *   Padding: `16px`.
    *   Placeholder: `textTertiary`.

---

## 5. Spacing & Rhythm
*   **Base Unit**: `4px`.
*   **Margins**: `24px` (Screen edges).
*   **Gutters**: `16px`.
*   **Stacking**: `8px`, `16px`, `24px`, `32px`.

---

## 6. Screen Layouts

### 1. Splash Screen
*   **Layout**: Minimalist center logo.
*   **Visual**: Animated gradient orb (Indigo/Violet) breathing in the center.
*   **Logo**: "Tome AI" in modern sans-serif, fading in.
*   **Transition**: Orb expands to fill screen -> Home.

### 2. Onboarding (Chat -> Preferences)
*   **Layout**: "Conversation" style but cleaner.
*   **Header**: "Welcome to Tome".
*   **Body**: A single, focused question card in the center (e.g., "What's your role?").
*   **Input**: Multiple-choice chips or text input at the bottom.
*   **Progress**: Subtle pill indicator at top.
*   **Glass Effect**: Background is a blurred version of the Splash gradient.

### 3. Home (Dashboard)
*   **Header**:
    *   "Good Morning, [Name]" (Display typography).
    *   Avatar (Profile/Settings) on right.
*   **Quick Action**: "Create New" floating card (Glass).
    *   Two prominent options: "AI Generation" (Sparkle icon) vs "Blank Deck" (Plus icon).
*   **Recent Work**:
    *   Horizontal scroll of large preview cards (Aspect ratio 16:9).
    *   Each card has a snapshot of the first slide.
*   **Templates**:
    *   "Start from Template" section.
    *   Grid of clean, modern thumbnail covers.
*   **Bottom Nav**: Removed. Replaced by a floating "Command Bar" or simple top-level navigation if needed.

### 4. Editor (Unified Workspace)
*   **Layout**: Top Bar + Sidebar (Slides) + Canvas + Inspector.
*   **Top Bar**:
    *   Back (Chevron).
    *   Title (Editable).
    *   Actions: Play, Share, Export (Icons).
*   **Sidebar (Left)**:
    *   Vertical scroll of slide thumbnails.
    *   Reorderable.
    *   "Add Slide" button at bottom.
*   **Canvas (Center)**:
    *   The slide content.
    *   Pinch to zoom.
*   **Inspector (Bottom/Sheet)**:
    *   Context-aware tools (Text style, Image replace, AI Regen).
    *   Appears when an object is selected.
*   **AI FAB**:
    *   Floating Action Button (Sparkles) in bottom-right.
    *   Opens AI Assistant sheet.

### 5. AI Assistant (Overlay)
*   **Type**: Modal Bottom Sheet (Glass).
*   **Input**: Large text area "Describe your slide...".
*   **Suggestions**: Horizontal scroll of chips ("Add image", "Summarize", "Change tone").
*   **Result**: Live preview of the change before applying.

### 6. Settings (Profile)
*   **Layout**: Inset Grouped List (iOS style).
*   **Header**: Large profile picture + Name + Plan status ("Tome Pro").
*   **Sections**:
    *   Account (Email, Sync).
    *   Subscription (Manage Plan - RevenueCat).
    *   App Icon / Theme.
    *   Help & Support.

---
