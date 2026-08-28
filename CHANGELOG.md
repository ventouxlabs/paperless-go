# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- An upload stuck in the queue for over 30 days without reaching the server now has its file removed from this device, freeing the storage it was holding. This only happens once the queue screen (Settings > Upload queue) can show you it happened, and only after two independent checks a day apart agree the upload is genuinely that old — a single clock hiccup on the device cannot delete anything. Previously the file was kept forever, growing unbounded

## [1.2.2] - 2026-08-25

### Fixed
- **F-Droid builds work again.** The dependency lockfile the F-Droid build is pinned to still listed a package this app stopped using in 1.1.8, which makes F-Droid's build fail outright rather than degrade. Every F-Droid tag since then would have failed to build, leaving F-Droid users stranded on 1.1.7 — without the share-intent fixes, the upload queue, or any of the data-loss fixes released since. There is no change to the app itself in this release

### Changed
- Release tags are now pushed to the GitLab mirror automatically. F-Droid watches the mirror for new tags, and the mirror had twice fallen far enough behind GitHub that F-Droid could not see releases that existed

## [1.2.1] - 2026-08-22

### Fixed
- An upload the app has given up on no longer explains itself twice. The reason under the document said one thing and the "Details" line underneath restated it in slightly different words; Details now appears only when there is a real error to show

### Changed
- A release build made without the signing keystore is now **unsigned** rather than being signed with Android's public debug key. This only affects people building from source: the resulting APK must be signed before it can be installed, which is what building from source should require. A debug-signed build looked like a normal release but could never be upgraded by a real one, and could be replaced in place by any other debug-signed APK

## [1.2.0] - 2026-08-19

### Added
- **Upload queue screen.** Documents waiting to reach your server were completely invisible until now. Settings > Upload queue shows everything queued, what state it is in, and why an upload failed, with Retry and Delete on each one. A banner appears on the Inbox when an upload has stopped trying, so you find out without going looking

### Fixed
- Retry now works on an upload the app had given up on after 30 days. It previously cleared the failure and then did nothing at all, on exactly the uploads most in need of rescuing
- Deleting a queued upload no longer risks it being uploaded anyway a moment later
- A single damaged queue entry no longer hides the entire queue. One unreadable row used to make every other queued document invisible and unsendable, permanently; damaged entries are now skipped and reported
- Edits you make offline (title, correspondent, document type, storage path) are applied in the order you made them, even if the device clock changes between them. A clock moving backwards could previously leave a document with a value you had already replaced
- A queued upload no longer burns its retry budget on tags it cannot read

### Changed
- Deleting all failed uploads now tells you when some of them belong to a different server profile, and which

## [1.1.9] - 2026-08-18

### Fixed
- Sharing a file into Paperless Go now works reliably. Four separate faults could each lose a share: the app resolved the *previous* share instead of the new one, a share that arrived before the app was listening was dropped entirely, relaunching a killed app from Recents re-imported the same file again, and a shared file could flash "Page not found" while your session was still being restored
- An upload that cannot reach the server is no longer lost. Being offline, having no server configured yet, or a server name that does not resolve now queue the document and retry it later — on reconnect, on sign-in, and on app launch, not only when the network happens to blip
- Queued documents are no longer stored where Android can delete them under storage pressure. They are copied into the app's private storage and released only once the upload succeeds
- Signing out, or switching server profiles, no longer deletes everything waiting in the upload queue
- A queued upload is now bound to the server it was queued for, so switching profiles cannot send a document to the wrong account
- Being offline no longer burns the retry budget. Five launches without signal used to terminally fail a perfectly good upload, and it was then never retried

### Changed
- A queued upload that has not reached the server for 30 days is marked as failed but its file is **kept**, not deleted. The queue has no screen yet, so nothing can warn you before a document is discarded — and the 30-day timer relies on the device clock, which can jump. Keeping the file means a clock change costs storage rather than the document itself. Files for abandoned uploads will accumulate until a queue screen exists to manage them

## [1.1.8] - 2026-08-11

### Changed
- Document detail screen now has one primary action button with the rest grouped into an overflow menu
- Bulk edit (tags, correspondent, document type) now goes through a single consistent picker sheet

### Fixed
- Remove "Password Protect & Share" — it re-encoded the PDF and silently ignored the password without ever encrypting the file, giving a false sense of protection. No encryption library the app can legally bundle (Syncfusion is proprietary, incompatible with AGPL-3.0; the bundled `pdf` package only exposes an abstract encryption extension point, not an implementation) makes this honest to keep without a from-scratch cryptographic implementation, which needs dedicated security review rather than a quick fix. "Compress & Share" is unaffected.

## [1.1.5] - 2026-07-06

### Changed
- Bundle Inter as a variable font asset — the app no longer fetches fonts from Google's CDN at runtime

## [1.1.3] - 2026-06-19

### Fixed
- Route shared images through the scan → PDF pipeline (single and multi-page) instead of uploading the raw image
- Fix accessibility issues and a hardcoded version string

### Added
- Screen-reader semantic labels on interactive elements

### Changed
- Warmer empty states, locale-aware dates, and refined text theme weights
- Introduce design tokens for spacing and border radius

## [1.1.2] - 2026-04-24

### Changed
- Per-architecture APKs (arm, arm64, x86_64) for smaller download size on F-Droid

## [1.1.1] - 2026-04-24

### Fixed
- Fix login failing on servers behind reverse proxies (HTTP 302)
- Fix "Connection failed: null" error message on login failure
- Fix circular dependency crash when logging in

## [1.1.0] - 2026-03-29

### Added
- Add annotate action to document detail with drawing canvas, tools, and page navigation
- Add annotation model with undo/redo support
- Add workflow caching for offline mode with complete cache coverage
- Add shimmer skeleton loaders for dashboard and workflows screens
- Add shared EmptyState widget standardized across screens
- Add compress, share, and password protect actions to document detail
- Add PDF compress and password protect service
- Add native PDF page renderer via platform channel
- Add rotate and split PDF tools to document detail popup menu
- Add page range parser with validation for split operations
- Add custom fields management screen with create, rename, and delete operations
- Add custom field data type helpers and CRUD API methods
- Add workflows list screen with toggle and workflow detail screen
- Add workflow helper functions for type and source label lookups
- Add DashboardScreen with pull-to-refresh stat card grid
- Add DashboardStatistics model and provider
- Add long-press chip management for saved view delete and rename
- Add save-as-view button and dialog for filter-based saved views
- Add createSavedView, deleteSavedView, updateSavedView API methods
- Add AI edit trail section in document detail showing OCR-suggested metadata
- Add scan date shortcut below created date in document detail
- Add fastlane metadata for F-Droid
- Add OCR metadata suggestions for image file picker uploads
- Add Share button to bulk document selection bar
- Add long-press context menu with Share action on document cards
- Add offline edit queue with coalescing and auto-sync on reconnect
- Add Android home screen widget with document count and quick scan/upload buttons
- Add document templates with Drift storage, management UI, and upload integration
- Add per-document biometric lock with Drift storage
- Add annotation compositing export service
- Add batch OCR re-run to bulk action bar

### Changed
- Wire DashboardScreen as home tab and move Inbox to /inbox
- Standardize error states with icon, message, and retry button across all screens
- Replace hardcoded colors with theme-aware alternatives for dark mode
- Show fast preview on preset change for single-page scans
- Read crop screen image bytes once instead of twice
- Wire annotation compositing into save/share flow

### Fixed
- Fix DropdownButtonFormField value and remove controller disposal
- Fix empty select options guard in forms
- Fix typed maps in filters bar and detail screen
- Fix scrollable dashboard layout and loading state
- Fix document tag rule type limitation
- Fix paginated workflows provider and keepAlive behavior
- Fix RefreshIndicator placement and error detail display
- Fix related_document field handling as int or string from API
- Fix expose documentId in UploadState after successful upload
- Fix custom field select picker using extraData options
- Fix re-enforce minimum crop size after edge clamping
- Fix prevent double-tap race in scan page rotation
- Fix delete old temp files after rotate and crop in scan review
- Fix share context.mounted guard and clear selection after bulk share
- Fix case-sensitive exact match behavior
- Fix Android VIEW intent URI handling in router redirect
- Fix auth guard application after VIEW intent redirect
- Fix atomic edit queue coalescing, secure biometric gate default, efficient hasPending, and widget dark mode

## [1.0.3] - 2026-03-08

### Added
- Extract ML Kit into swappable modules for F-Droid FOSS builds
- Add speed optimizations for image filters: separable box blur, fast 3×3 sharpen, inline binarize

### Changed
- Unify preset pipeline and remove duplicate filter logic

### Fixed
- Fix upload state, share intent, image cache, regex matcher, and polling auth bugs
- Fix CSRF race condition and retry interceptor silent hang
- Fix F-Droid build recipe and disable dependency metadata

## [1.0.2] - 2026-03-08

### Added
- Add crop/rotate tools for document images
- Add batch scan feature
- Add OCR metadata suggestions
- Add VIEW intent filter and expand share support for all document types

### Changed
- Speed up image filters with detailed processing progress UI
- Optimize enhance pipeline

### Fixed
- Fix nullable created date field handling
- Fix bulk trash operations
- Fix upload retry cap
- Fix documents disappearing after re-login
- Fix PDF rendering speed
- Fix adaptive contrast artifacts
- Fix tag picker keyboard behavior

## [1.0.1] - 2026-03-08

### Added
- Add ML Kit deskew for document image enhancement
- Add ProGuard rules for ML Kit release builds
- Enable login autofill on authentication screen
- Parallelize image enhancement pipeline

### Changed
- Rename package to com.ventoux.paperlessgo
- Improve AppBar button styling and contrast
- Auto-orient EXIF images in scanner to match device orientation

### Fixed
- Fix CSRF 403 error on bulk edit operations
- Fix scanner UX issues with image orientation

## [1.0.0] - 2026-02-26

### Added
- Add offline cache with Drift/SQLite storage
- Add storage paths management
- Add speed dial FAB for quick actions
- Add bulk operations support
- Add document-specific AI chat with SSE streaming
- Add biometric authentication
- Add app icon, feature graphic, and Play Store listing
- Add privacy policy and F-Droid metadata

### Fixed
- Fix AI chat authentication and race conditions
- Fix settings dialog crashes
- Fix note adding functionality
- Fix delete operation to use REST endpoint
- Fix bulk action count display
- Resolve 60+ bugs from multiple codebase audits

### Security
- License under AGPL-3.0
