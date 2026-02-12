# Engine Contract: AI Presentation

## 1. Slide Generation Pipeline
- **Trigger:** User input (Topic, Style, Slide Count 1-15).
- **Prerequisites:** `AIConfig.openAIKey` must be set, Premium status active (RevenueCat entitlement).
- **Outline Phase:**
  - Calls OpenAI API (`v1/responses` - *Note: Non-standard endpoint in code*) to generate structured JSON outline.
  - JSON Schema: `PresentationOutline` (title, subtitle, cover_image_prompt, slides[]).
  - Each slide contains: title, bullets (max 6), image_prompt.
- **Slide Instantiation:**
  - Converts JSON to `Presentation` object with `Slide` list.
  - Populates text content immediately.
- **Image Generation Phase:**
  - Iterates through slides sequentially.
  - Calls OpenAI API (`v1/images/generations`) for each slide's prompt.
  - Downloads image (Base64 or URL) and caches in memory (`Uint8List`).
  - Autosaves progress.

## 2. Prompt Processing Flow
- **Outline Prompt:**
  - Template: "Create a professional presentation outline about: '{topic}'. Number of slides: {slides}. Style: {style}. Include a cover... Return strictly as JSON..."
  - Uses `json_schema` for strict output formatting.
- **Image Prompt:**
  - Input: Short visual description from outline (e.g., "A modern office building").
  - Augmentation: Appends theme descriptor based on selected color palette.
  - Format: "{prompt}, {theme_descriptor}, professional, minimal, clean branding, high resolution".
  - Theme Descriptors: "soft indigo palette", "clean sky-blue palette", etc.

## 3. AI Call Structure
- **Outline Generation:**
  - **URL:** `https://api.openai.com/v1/responses`
  - **Method:** POST
  - **Headers:** `Authorization: Bearer <KEY>`, `Content-Type: application/json`
  - **Body:**
    ```json
    {
      "model": "gpt-4o-mini",
      "input": "...",
      "store": false,
      "text": { "format": { "type": "json_schema", ... } }
    }
    ```
- **Image Generation:**
  - **URL:** `https://api.openai.com/v1/images/generations`
  - **Method:** POST
  - **Body:**
    ```json
    {
      "model": "gpt-image-1",
      "prompt": "...",
      "size": "1024x1024",
      "n": 1
    }
    ```

## 4. Data Model of Slides
- **Slide:**
  - `id`: String (timestamp-based)
  - `title`: String
  - `body`: String (nullable, newline-separated bullets)
  - `image`: Transient `Uint8List` in memory (not in model class, managed by `_AIGeneratePageState`).
- **Presentation:**
  - `id`: String
  - `title`: String
  - `slides`: List<Slide>
  - `updatedAt`: DateTime
- **Persistence:**
  - JSON serialization via `dart:convert`.
  - Stored in `SharedPreferences` with key `presentation_{id}`.

## 5. Export Mechanism
- **Format:** PowerPoint (.pptx)
- **Library:** `dart_pptx`
- **Content:**
  - Title Slide: Presentation Title + "Generated with AI" (Author).
  - Content Slides: Title + Bullets.
- **Limitation:** Text-only export. Images and backgrounds are explicitly excluded in current implementation.
- **Output:** Saved to `ApplicationDocumentsDirectory`, opened via `open_filex`.

## 6. Error Handling Logic
- **API Errors:**
  - Checks HTTP status codes.
  - Parses OpenAI error body (`error` or `message` fields).
  - Throws exceptions with descriptive messages.
- **User Feedback:**
  - `SnackBar` displays error messages.
- **Validation:**
  - Checks for empty API key.
  - Checks Premium status via `Purchases.getCustomerInfo`.

## 7. Retry Logic
- **Image Generation Only:**
  - 3 max attempts.
  - Exponential backoff: `700 * attempt + random(400)` ms delay.
  - Retries on any exception (network or API error).

## 8. Async Behavior
- **Main Flow:** `async` method `_aiGenerateOutline`.
- **UI State:** `_busy` flag blocks interactions and shows `_GlassLoader` overlay.
- **Image Loading:** Sequential `await` inside loop (not parallel).
- **Autosave:** Debounced (600ms) using `Timer`.

## 9. Dependencies Used
- **Core:** `flutter`, `dart:convert`, `dart:async`, `dart:io`.
- **Network:** `http` (via `import`, transitive or missing in pubspec).
- **AI/Logic:** `openai` (direct REST calls).
- **UI:** `google_fonts`, `flutter_animate` (implied by animations), `image_picker`.
- **Persistence/File:** `shared_preferences`, `path_provider`, `open_filex`.
- **Monetization:** `purchases_flutter`.
- **Export:** `dart_pptx`.
