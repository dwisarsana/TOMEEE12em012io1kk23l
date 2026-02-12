# Flow Architecture V2: Tome AI

## 1. App Structure

### Root Shell (`TomeShell`)
- **Type:** Stateful Shell Route (Persistent `Scaffold`).
- **Navigation:** Bottom Navigation Bar.
- **Tabs:**
  1.  **Library (Home):** Recent presentations, sorted by `updatedAt`.
  2.  **Create (FAB):** Central Floating Action Button. Triggers the *Creation Wizard*.
  3.  **Archive (Settings):** Subscription status, preferences, legal.

---

## 2. Onboarding Flow (Intent-First)

### A. Welcome Screen (`WelcomePage`)
- **Visual:** Branding animation (Book opening).
- **Action:** "Start Your Journey".
- **Check:** If `onboarding_done` is false -> Go to *Role Selection*. Else -> *Library*.

### B. Role Selection (`RolePage`)
- **Question:** "What brings you to Tome?"
- **Options:**
  - "Professional" (Pitch decks, reports).
  - "Student" (Assignments, research).
  - "Creative" (Stories, mood boards).
- **Persistence:** Save to `SharedPreferences` (used to seed *Creation Wizard* defaults).

---

## 3. Creation Wizard (`WizardFlow`)
*Replaces the single-page `AIGeneratePage` form.*

### Step 1: Intent (Style Mapping)
- **UI:** Card selection.
- **Data Mapping:**
  - "Pitch Deck" -> Engine `style="persuasive business"`.
  - "Lecture" -> Engine `style="educational and clear"`.
  - "Story" -> Engine `style="vivid narrative"`.

### Step 2: Subject (Topic Input)
- **UI:** Large, centered text field.
- **Prompt:** "What is the subject of your tome?"
- **Validation:** Minimum 3 characters.

### Step 3: Depth (Slide Count)
- **UI:** Segmented Control or Slider.
- **Data Mapping:**
  - "Brief" -> Engine `slides=6`.
  - "Standard" -> Engine `slides=10`.
  - "Comprehensive" -> Engine `slides=15`.

### Step 4: The Gate (Premium Check)
- **UI:** "Reveal Outline" Button.
- **Logic:**
  1.  Call `Purchases.getCustomerInfo`.
  2.  If `entitlements.all['slides']?.isActive`:
      - Show Loading Overlay (`_GlassLoader`).
      - Call Engine: `_generateOutline(topic, slides, style)`.
      - Navigate to *Unified Editor*.
  3.  Else:
      - Show **Premium Paywall Overlay** (intercepts the flow).
      - If purchase successful -> Resume generation automatically.

---

## 4. Unified Editor Experience (`TomeEditor`)
*Combines viewing, editing, and image generation.*

### A. The Canvas
- **View:** Scrollable vertical list of slides.
- **State:**
  - **Text:** Pre-filled from Engine JSON.
  - **Images:** Initially empty or placeholder patterns.

### B. Smart Action: "Visualize" (Image Generation)
- **Trigger:** Floating "Wand" Button or per-slide "Generate Image" button.
- **Context:**
  - If user is Premium -> Call Engine `_generateImageWithRetries` for visible slides.
  - If user is Free -> Show Paywall (Strategic friction).
- **Feedback:** Images fade in (opacity animation) as they download.

### C. Export
- **Trigger:** "Share" Icon in AppBar.
- **Action:** Call Engine `_exportToPptx`.
- **Note:** Available to all users (Free/Premium), but content quality depends on the previous steps.

---

## 5. Monetization Integration Points

### A. The "Creation Gate"
- **Location:** End of *Creation Wizard*.
- **Philosophy:** Allow users to invest effort (selecting intent, typing topic) *before* asking for payment. The value proposition ("We are about to generate your work") is highest here.

### B. The "Visualization Gate"
- **Location:** *Unified Editor* -> "Visualize" button.
- **Philosophy:** Text is valuable, but visuals are the "wow" factor. Segregating them allows a second up-sell opportunity if the first was bypassed (e.g., if we allow free text generation in future).

### C. The "Archive" (Settings)
- **Location:** *Archive* Tab.
- **Content:**
  - "Manage Subscription" (RevenueCat UI).
  - "Restore Purchases".

---

## 6. Engine Compatibility Check
- **Pipeline Preservation:**
  - The *Creation Wizard* gathers `topic`, `slides`, and `style` exactly as the legacy `AIGeneratePage` did.
  - The *Unified Editor* uses the exact same `Presentation` and `Slide` data models.
  - The `_generateOutline` and `_generateImageWithRetries` functions are called with identical parameters, ensuring `ENGINE_CONTRACT.md` is respected.
