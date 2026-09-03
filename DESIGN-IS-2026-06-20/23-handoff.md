# 23 — Session Handoff (2026-09-03) — snackbar fix shipped, downloads-location PR open and blocked on device verification

`main` is `1011aa3` on both remotes (GitHub, GitLab). Open work lives on
`feat/downloads-location` (GitHub only, PR **#33**, CI green, mergeable) — the first
feature branch this repo has used; see "Process note" for why. 317/334 Dart tests pass,
the 17 failures are the same pre-existing golden/shader/network issues noted in every
recent handoff, unrelated to this session.

Supersedes the "OPEN" section of `22-handoff.md`; everything else in 22 still stands.

---

## Shipped this session — filing confirmation snackbar (merged to `main`)

The "Filed '[doc]'" / Undo snackbar in Inbox never auto-dismissed. Root cause: Flutter
3.47.0 changed `SnackBar`'s default — `persist = persist ?? action != null` — so any
action-bearing SnackBar with no explicit `persist:` now defaults to permanent. This
app's code (`f29063e`) was correct when written; the SDK default moved under it. Fixed
with one line, `persist: false`, at `lib/features/inbox/inbox_screen.dart:241`
(`1011aa3`). Swipe-to-dismiss needed no code — Flutter's `SnackBar` already wraps it in
a `Dismissible` on a structurally distinct code path
(`SnackBarClosedReason.swipe`) from the Undo button's own `onPressed`.

The investigating subagent's first hypothesis (`MediaQuery.accessibleNavigationOf`
gating the dismiss timer) was wrong for this SDK version — it was true in older Flutter,
got refactored into `persist` at some point, and a full read of `scaffold.dart` caught
the discrepancy before it shipped. Worth remembering if a similar snackbar bug shows up
elsewhere: check `persist`, not the accessibility gate, first.

## Open — downloads location feature (PR #33, `feat/downloads-location`)

**The reframe:** the only real "Download" action in the app
(`document_detail_screen.dart`) was already broken UX before this session — it saved to
`getTemporaryDirectory()`, an app-private cache path the user could never open and the
OS could evict. Everything else that looked like "download" elsewhere in the app is a
**Share** action (opens the OS share sheet), not a save — 5 sites, all left untouched.
So this shipped as "make Download actually download, with a remembered destination,"
plus (per direction mid-session) an additive "Save to folder" option alongside all 5
Share sites, which does not alter their existing Share behavior.

Backed by the `saf` package (Storage Access Framework) for persistable folder-access
grants — `file_picker`, already a dependency, was investigated and confirmed unusable:
it never calls `takePersistableUriPermission` and converts the SAF tree URI to a raw
filesystem path that's unwritable under scoped storage (upstream:
flutter_file_picker#1825). No new Android permissions anywhere — matters for both Play
and F-Droid. Persistence reuses `flutter_secure_storage`, no new storage mechanism —
the OS-held grant is the real source of truth, the stored URI string is just a hint,
and a restored-but-invalid URI should fail closed by design.

New: `lib/core/services/export_destination_service.dart`,
`lib/shared/save_to_folder_action.dart`. Settings gets a new "Storage" section between
Security and AI Chat. 18 new unit tests, `flutter analyze` clean, zero regressions
against the `main` baseline (byte-identical failure sets, diffed via the JSON test
reporter).

**Verified on-device, this session:** Settings → Storage → "Downloads location" renders
correctly, defaults to "Ask each time." Tapping it opens the real Android system folder
picker (confirms `saf`'s `ACTION_OPEN_DOCUMENT_TREE` fires). Picking a folder updates
the row to show the chosen folder's name.

**NOT yet verified — this is what's blocking merge:** the actual `pasteLocalFile` write,
grant persistence across a full process restart, and the revoked-permission fallback
path. Session ended with the app in the folder-picker flow, mid-verification, handed
off to the user to drive by hand rather than continue automated taps (see next section
for why). Pick up by: opening the app, Library → any document → **Download** (not
Share), confirm the file lands in the picked folder and is actually openable outside
the app.

## Two real incidents from automated on-device testing this session — read before
## automating taps on this device again

**1. A subagent doing blind-tap folder-picker automation briefly opened the user's
personal Signal/Molly conversation.** It backed out immediately without reading
further and stopped further automated tapping because of it. This happened because the
system folder picker (Android DocumentsUI, not this app's own Flutter UI) doesn't
expose reliable coordinates the way the app's own widget tree does, and a mistap
landed on a home-screen/recents transition into another real app on this real,
daily-use phone — not an isolated test device.

**2. Later, in the main session (not a subagent), a screen-coordinate scaling mistake
(forgetting to multiply displayed-image coordinates by ~1.212 to get raw device
coordinates before every `adb shell input tap`) caused two more unintended real
actions**: toggling Biometric Lock on (reverted), and worse, granting camera
permission and **taking a real photo through the device's camera** (a sketchbook nearby
— not sensitive, but still an uncontrolled real-world action) before the mistake was
caught and the scan was discarded.

**The lesson, now written to memory:** this device is the user's actual daily phone
with real apps, real photos, and real messages on it — not a disposable test rig.
Automated `adb shell input tap` sequences need every coordinate re-derived and
double-checked against the *current* screenshot's actual dimensions before firing,
every single time, with zero tolerance for "close enough." For anything touching a
**system** UI (folder pickers, permission dialogs, the camera) or when there's any
doubt about exact coordinates, stop and have the human drive that specific step by
hand rather than automate it. This is now the default posture for this device, not
just this session.

## Process note — first feature branch in this repo's history

Project convention has been solo-dev-on-`main`, no PRs, since the beginning (see
`project_branching.md`). This session broke that convention once, explicitly at the
user's request, specifically because the downloads-location work still had unverified
native-plugin behavior and the user wanted CI building it independently while
verification continued separately. Branch: `feat/downloads-location`. **Don't treat
this as a new default** — it was a one-off for a specific reason, and normal work
should keep going straight to `main` unless asked otherwise again.

## Remaining open issues (unchanged)

- **#13** — Submit to Google Play Console. Still nothing to code; blocked on the
  user's manual Console work.
- **#4** — Epic: Release & distribution follow-through. Parent of #13.
- **New, not yet filed as an issue:** finish device-verifying PR #33 (see above), then
  merge and delete the feature branch.
