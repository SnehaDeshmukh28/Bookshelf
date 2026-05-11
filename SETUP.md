# BookShelf — Setup Guide

## Prerequisites

Install the following tools before building:

### 1. Flutter SDK
- Download from https://docs.flutter.dev/get-started/install/windows/mobile
- Choose **Windows → Android** path
- Run `flutter doctor` and fix any issues shown

### 2. Android Studio
- Download from https://developer.android.com/studio
- During setup install: Android SDK, Android SDK Platform-Tools, Android Emulator
- Recommended API level: **API 33 (Android 13)** or higher

### 3. Java / JDK
- Android Studio bundles a JDK — no separate install needed.

---

## Build & Run

```bash
# 1. Go to the project folder
cd bookshelf

# 2. Get all packages
flutter pub get

# 3. Connect your Android phone via USB  (enable Developer Options + USB Debugging)
#    OR launch an emulator from Android Studio

# 4. Run the app
flutter run

# 5. Build a release APK to install directly
flutter build apk --release
# Output: build\app\outputs\flutter-apk\app-release.apk
```

---

## Features

| Feature | How to use |
|---|---|
| **Import PDF** | Tap "Add Book" FAB → pick any PDF from your phone |
| **Read** | Swipe left/right to turn pages (Kindle-style) |
| **Zoom** | Pinch to zoom in/out on any page |
| **Highlight** | Long-press to select text → tap Highlight → pick color |
| **Bookmarks** | Tap the Bookmark icon in the bottom toolbar |
| **View Highlights** | Bottom toolbar → Highlights panel |
| **View Bookmarks** | Bottom toolbar → Bookmarks panel |
| **Jump to page** | Tap the page number at bottom-right, or drag the slider |
| **Search** | Toolbar top-right search icon |
| **Table of Contents** | Toolbar bookmarks icon (if PDF has TOC) |
| **Reading mode** | Bottom toolbar → Mode (Light / Dark / Sepia) |
| **Rename book** | Long-press a book card → ⋮ → Rename |
| **Delete book** | Long-press a book card → ⋮ → Delete |

---

## PDF Format Support

The app uses **Syncfusion Flutter PDF Viewer** which handles:
- PDF versions 1.0 through 2.0
- Scanned PDFs (image-based pages)
- PDFs with embedded fonts, CJK fonts, complex typography
- Password-protected PDFs (prompts for password)
- Multi-column layouts, academic papers, e-books

### Free community license
Syncfusion packages are free for individual developers and small businesses
(revenue < $1M USD / year). No API key needed — works out of the box.

---

## Project Structure

```
bookshelf/
├── lib/
│   ├── main.dart               # App entry point
│   ├── theme/app_theme.dart    # Light / Dark / Sepia themes
│   ├── models/
│   │   ├── book.dart           # Book data model
│   │   ├── highlight.dart      # Highlight model + color palette
│   │   └── bookmark.dart       # Bookmark model
│   ├── services/
│   │   ├── database_service.dart   # SQLite (books, highlights, bookmarks)
│   │   ├── storage_service.dart    # File system (copy/delete PDFs)
│   │   └── insights_service.dart   # Pure-Dart extractive NLP (no API)
│   ├── providers/
│   │   └── library_provider.dart   # State management
│   └── screens/
│       ├── splash_screen.dart
│       ├── library_screen.dart     # Book grid
│       └── reader_screen.dart      # Full PDF reader
└── android/
    └── app/src/main/
        └── AndroidManifest.xml     # Storage permissions
```

---

## Troubleshooting

**`flutter doctor` shows Android SDK not found**
→ Open Android Studio → SDK Manager → install Android SDK Platform 33+

**App crashes on PDF open**
→ The PDF may need more memory. Check `android:largeHeap="true"` is in AndroidManifest.xml (already set).

**Text selection not working on scanned PDFs**
→ Scanned PDFs are images — there is no selectable text. Use a PDF with real text layers (OCR'd PDFs work fine).

**Build fails with `minSdk` error**
→ Ensure `minSdk 21` is in `android/app/build.gradle` (already set).
