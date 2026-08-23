<p align="center">
  <img src="assets/feature-graphic.png" alt="Paperless Go" width="600" />
</p>

<p align="center">
  <strong>Your documents. Your server. Your pocket.</strong>
</p>

<p align="center">
  <a href="https://github.com/ventouxlabs/paperless-go/releases/latest"><img src="https://img.shields.io/github/v/release/ventouxlabs/paperless-go?style=flat-square&color=17A262" alt="GitHub Release" /></a>
  <a href="https://f-droid.org/packages/com.ventouxlabs.paperlessgo.nogoogle"><img src="https://img.shields.io/f-droid/v/com.ventouxlabs.paperlessgo.nogoogle?style=flat-square&color=17A262" alt="F-Droid" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/github/license/ventouxlabs/paperless-go?style=flat-square&color=17A262" alt="License: AGPL-3.0" /></a>
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.41-02569B?style=flat-square&logo=flutter" alt="Flutter" /></a>
</p>

---

A modern, open-source mobile client for [Paperless-ngx](https://github.com/paperless-ngx/paperless-ngx) — the self-hosted document management system. Browse, search, scan, upload, and manage your entire document library from your phone.

<p align="center">
  <img src="metadata/en-US/images/phoneScreenshots/1_document_list.png" width="180" alt="Document List" />
  &nbsp;&nbsp;
  <img src="metadata/en-US/images/phoneScreenshots/2_scan_upload.png" width="180" alt="Scan & Upload" />
  &nbsp;&nbsp;
  <img src="metadata/en-US/images/phoneScreenshots/3_ai_chat.png" width="180" alt="AI Chat" />
  &nbsp;&nbsp;
  <img src="metadata/en-US/images/phoneScreenshots/4_login.png" width="180" alt="Login" />
</p>

## Install

[<img src="https://fdroid.gitlab.io/artwork/badge/get-it-on.png" alt="Get it on F-Droid" height="60">](https://f-droid.org/packages/com.ventouxlabs.paperlessgo.nogoogle)
[<img src="https://raw.githubusercontent.com/nickmitchko/FileHost/master/artifacts/icons/get-it-on-github.png" alt="Get it on GitHub" height="60">](https://github.com/ventouxlabs/paperless-go/releases/latest)

> **F-Droid** — Free, built without Google ML Kit (pure-Dart deskew fallback)
> **GitHub Releases** — Includes ML Kit for better document deskew and OCR suggestions

## Features

### Core
- **Full-text search** with autocomplete across your entire library
- **Advanced filtering** by tags, correspondent, document type, date range
- **Saved views** — reusable filter and sort combinations
- **Similar documents** — find related documents by content
- **PDF viewer** with inline thumbnails and previews

### Capture
- **Camera scanner** with six image presets (Auto, Receipt, B&W, Color Doc, Photo)
- **File upload** from device storage
- **Share intent** — send files from any app directly to Paperless
- **Document templates** — save reusable upload presets

### Edit & Organize
- **Label management** — tags, correspondents, document types, storage paths
- **Metadata editing** with custom fields
- **PDF annotation** — draw, highlight, redact, export back to server
- **Bulk operations** — tag, re-tag, delete, batch OCR, merge
- **Inbox quick-assign** with swipe gestures
- **Document notes** and **share links** with expiration

### Intelligence
- **AI chat** — ask questions about your documents via [Paperless-AI](https://github.com/clusterpj/paperless-ai) integration
- **OCR metadata suggestions** — auto-suggest title, correspondent, tags from scanned text (ML Kit builds)

### Mobile-First
- **Offline caching** — SQLite-backed, browse without connection
- **Offline edit queue** — queue changes, auto-sync on reconnect
- **Biometric auth** — app-level and per-document fingerprint/face lock
- **Dark mode** — system-aware with manual override
- **Home screen widget** — document count + quick-launch scan/upload
- **Multi-server** — switch between Paperless-ngx instances
- **Trash management** — view and restore deleted documents

## Requirements

- [Paperless-ngx](https://github.com/paperless-ngx/paperless-ngx) v2.x+ (self-hosted)
- Android 6.0+ (API 23)

## Getting Started

1. Install from F-Droid, GitHub Releases, or build from source
2. Enter your server URL (e.g. `https://paperless.example.com`)
3. Log in with username/password or paste an API token
4. Start managing your documents

## Build from Source

```bash
git clone https://github.com/ventouxlabs/paperless-go.git
cd paperless-go
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

**Prerequisites:** [Flutter](https://docs.flutter.dev/get-started/install) stable (3.41+), Android SDK (API 23+)

Release build with obfuscation:
```bash
flutter build apk --release --obfuscate --split-debug-info=./debug-info/
```

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | [Flutter](https://flutter.dev) |
| State | [Riverpod](https://riverpod.dev) |
| HTTP | [Dio](https://pub.dev/packages/dio) |
| Navigation | [GoRouter](https://pub.dev/packages/go_router) |
| Database | [Drift](https://drift.simonbinder.eu) (SQLite) |
| Auth Storage | [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage) |
| PDF | [pdfx](https://pub.dev/packages/pdfx) |
| Scanner | [cunning_document_scanner](https://pub.dev/packages/cunning_document_scanner) |
| Biometrics | [local_auth](https://pub.dev/packages/local_auth) |
| Widget | [home_widget](https://pub.dev/packages/home_widget) |
| OCR | [google_mlkit_text_recognition](https://pub.dev/packages/google_mlkit_text_recognition) |

## Contributing

Contributions welcome! Please open an issue first to discuss what you'd like to change.

1. Fork the repo
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Commit your changes using [conventional commits](https://www.conventionalcommits.org/)
4. Push and open a PR

## Privacy

Paperless Go does not collect, store, or transmit any user data to the developer or any third party. All data stays between your device and your Paperless-ngx server. [Full privacy policy](PRIVACY_POLICY.md).

## License

[GNU Affero General Public License v3.0](LICENSE) — free to use, modify, and distribute. Source must remain open.

## Acknowledgments

- [Paperless-ngx](https://github.com/paperless-ngx/paperless-ngx) — the document management system
- [Paperless-AI](https://github.com/clusterpj/paperless-ai) — AI chat integration
