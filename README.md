# AI Presentation

AI-powered presentation builder for iOS. Create, edit, and export slide decks using OpenAI — generate outlines, AI images, and export to PDF or PPTX.

## Features

- **AI Outline Generation** — Generate full presentation outlines from a topic prompt
- **AI Image Generation** — Create slide images with DALL-E
- **Slide Editor** — Add, edit, reorder, and delete slides with rich text
- **PDF & PPTX Export** — Share presentations in standard formats
- **Template Gallery** — Start from pre-built presentation templates
- **In-App Presenter** — Present slides directly from the app
- **Premium Subscription** — Monetized via RevenueCat (Apple IAP)
- **Sign In with Apple** — Authentication for sharing and sync

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.x (Dart ^3.8.1) |
| AI | OpenAI API (GPT-4o-mini, DALL-E) |
| IAP | RevenueCat (`purchases_flutter`) |
| Auth | Sign In with Apple |
| Storage | SharedPreferences (local) |
| Export | `dart_pptx`, `pdf` |
| Fonts | Google Fonts (Poppins) |

## Getting Started

### Prerequisites

- Flutter SDK ^3.8.1
- Xcode 15+ (for iOS)
- An OpenAI API key

### Setup

```bash
# Clone the repo
git clone https://github.com/YOUR_USERNAME/aipresentation.git
cd aipresentation

# Install dependencies
flutter pub get

# Run with your API key
flutter run --dart-define=OPENAI_API_KEY=sk-proj-your-key-here
```

> **Important:** Never hardcode API keys. Always pass them via `--dart-define` at build time.

### Build for Release

```bash
flutter build ios --dart-define=OPENAI_API_KEY=sk-proj-your-key-here
```

## Project Structure

```
lib/
├── main.dart                 # App entry + launch gate
├── opening/
│   ├── splash.dart           # Splash screen
│   └── onboards.dart         # Onboarding chat flow
├── src/
│   ├── constant.dart         # RevenueCat keys + premium check
│   ├── paywall.dart          # Paywall UI wrapper
│   └── store_config.dart     # Store configuration
├── ui/
│   ├── homepage.dart         # Home dashboard
│   ├── editor.dart           # Slide editor
│   ├── ai_generate.dart      # AI-powered editor
│   ├── setting.dart          # Settings / profile
│   └── template.dart         # Template gallery
└── utility/
    ├── apikey.dart           # AI config (uses --dart-define)
    ├── models.dart           # Data models
    └── storage.dart          # Local persistence
```

## Configuration

| Variable | How to Set | Required |
|----------|-----------|----------|
| `OPENAI_API_KEY` | `--dart-define=OPENAI_API_KEY=xxx` | ✅ Yes |
| RevenueCat API Key | Hardcoded in `lib/src/constant.dart` | Already set |

## License

All rights reserved.
