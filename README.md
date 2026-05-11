# Bookshelf

A Kindle-inspired PDF reader for Android, built with Flutter. Import any PDF from your device and read it with highlights, bookmarks, themes, and instant page insights — all stored locally, no account or internet required.

---

## Features

| | Feature | Description |
|---|---|---|
| 📚 | **Library** | Grid view of all imported books with cover thumbnails and reading progress |
| 📖 | **Reader** | Smooth page-by-page PDF viewing with pinch-to-zoom |
| 🖊️ | **Highlights** | Long-press to select text, pick from 8 highlight colours, view all highlights per book |
| 🔖 | **Bookmarks** | One-tap bookmark any page, jump back instantly |
| 🎨 | **Themes** | Light, Dark, and Sepia reading modes |
| 🔍 | **Search** | Full-text search within the current PDF |
| 📑 | **Table of Contents** | Jump to any chapter via the PDF's built-in TOC |
| 📊 | **Page Insights** | Instant stats and summary for the current page — word count, reading time, difficulty level, extractive summary, key points, and contextual find |
| ⚡ | **Zero dependencies** | No AI API, no cloud, no account — everything runs on-device |

---

## Page Insights

The **Insights** panel analyses each page using pure Dart NLP — no model downloads, no API calls, no internet.

- **Word count & sentence count**
- **Reading time** estimate (230 WPM baseline)
- **Difficulty** rating: Easy / Moderate / Challenging / Advanced (scored by avg word length + avg sentence length)
- **Extractive summary** — top 4 sentences by TF-IDF frequency scoring
- **Key points** — top 5 most information-dense sentences
- **Contextual find** — type any question or phrase, get the 3 most relevant sentences from the page

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.x (Dart) |
| PDF rendering | [Syncfusion Flutter PDF Viewer](https://pub.dev/packages/syncfusion_flutter_pdfviewer) |
| PDF text extraction | [Syncfusion Flutter PDF](https://pub.dev/packages/syncfusion_flutter_pdf) |
| Local database | SQLite via [sqflite](https://pub.dev/packages/sqflite) |
| State management | [Provider](https://pub.dev/packages/provider) |
| Animations | [flutter_animate](https://pub.dev/packages/flutter_animate) |
| Fonts | [Google Fonts](https://pub.dev/packages/google_fonts) |
| NLP | Pure Dart (no packages) |

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install/windows/mobile) (stable channel)
- [Android Studio](https://developer.android.com/studio) with Android SDK Platform 33+
- An Android device (API 21+) or emulator

### Build & Run

```bash
# Clone the repo
git clone https://github.com/YOUR_USERNAME/bookshelf.git
cd bookshelf

# Install dependencies
flutter pub get

# Run on a connected device or emulator
flutter run

# Build a release APK
flutter build apk --release
# → build/app/outputs/flutter-apk/app-release.apk
```

### First Use

1. Open the app — you'll land on the empty library screen.
2. Tap the **+** button and pick any PDF from your device.
3. Tap the book to start reading.
4. Swipe left/right to turn pages, long-press text to highlight, tap the toolbar icons for bookmarks and insights.

---

## Project Structure

```
bookshelf/
├── lib/
│   ├── main.dart
│   ├── theme/
│   │   └── app_theme.dart          # Light / Dark / Sepia themes + colour palette
│   ├── models/
│   │   ├── book.dart
│   │   ├── highlight.dart
│   │   └── bookmark.dart
│   ├── services/
│   │   ├── database_service.dart   # SQLite — books, highlights, bookmarks, cache
│   │   ├── storage_service.dart    # File system — copy / delete PDFs
│   │   └── insights_service.dart   # Pure-Dart NLP — summary, key points, difficulty
│   ├── providers/
│   │   └── library_provider.dart   # App-wide state via Provider
│   └── screens/
│       ├── splash_screen.dart
│       ├── library_screen.dart     # Book grid + import flow
│       └── reader_screen.dart      # Full reader — toolbar, panels, highlights
└── android/
    └── app/src/main/
        └── AndroidManifest.xml     # Storage permissions
```

---

## PDF Compatibility

Powered by Syncfusion Flutter PDF Viewer, the app handles:

- PDF 1.0 – 2.0
- Scanned (image-based) PDFs
- Embedded fonts, CJK fonts, complex typography
- Password-protected PDFs
- Multi-column layouts, academic papers, e-books

> **Syncfusion free licence:** free for individual developers and small businesses with revenue under $1M/year. No licence key required — works out of the box.

---

## Permissions

| Permission | Why |
|---|---|
| `READ_EXTERNAL_STORAGE` | Pick PDFs from device storage (Android 12 and below) |
| `READ_MEDIA_IMAGES` | Required on Android 13+ alongside storage access |

No network, camera, microphone, contacts, or location permissions are requested.

---

## Contributing

Pull requests are welcome. For major changes, please open an issue first.

---

## License

[MIT](LICENSE)
