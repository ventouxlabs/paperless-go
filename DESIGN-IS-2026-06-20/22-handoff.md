# 22 — Session Handoff (2026-09-01) — "Open with" fixed for real (cold start + warm resume), v1.2.2 shipped

`main` is `bedcf7b` on **both** remotes (GitHub `ventouxlabs/paperless-go`, GitLab
`selector4560/paperless-go`), tags in sync through v1.2.2. 317/334 Dart tests pass — the 17
failures are pre-existing golden-image pixel diffs, a `shaders/ink_sparkle.frag` decode
error, and a network `Connection refused`, all in files this session never touched (verified
via `git diff --stat -- '*.dart'` across every commit below). `flutter analyze` clean. No
open PRs.

Supersedes the "OPEN" section of `21-handoff.md`; its F-Droid/repo-move narrative still
stands as history.

---

## What shipped between handoff 21 and this session (compressed)

- **v1.2.2 released** (`4baff2a`), closing the `pubspec.lock.fdroid` gap 21 flagged — F-Droid
  now has a buildable tag.
- **`581fa40`** — the retention decision from 21's OPEN #2 was made: a row the retention
  sweep gives up on (stuck 30+ days) now gets its file released rather than growing storage
  unbounded forever, gated on two independent clock samples 24h apart so a single bad
  `DateTime.now()` read can't delete anything by itself.

## This session — the `/inbox` detour, for real this time, plus a second bug it uncovered

Started from `/prp-plan`: *"it should not force me to be on inbox if i have unsorted papers
to work through. If i share something into paperless-go this should be the focus."* Traced to
a specific mechanism, confirmed with the user before building: for "Open with" (ACTION_VIEW,
picking Paperless Go from a file manager), `MainActivity` only ever stripped `Intent.data` for
SEND/SEND_MULTIPLE — VIEW's data was left alone because the `paperlessgo://` widget deep link
is also ACTION_VIEW and legitimately needs it. That left content/file VIEW intents exposed to
Flutter's own embedding, which reads `Intent.data` as an initial deep-link route, racing
`SharePlugin`'s real handling and forcing `GoRouter`'s `redirect()` through `/inbox` before the
share actually landed.

Four commits, TDD RED→GREEN, plus a `/devils-advocate` pass and full on-device verification:

1. **`653ab91`/`dde2b21`** — `MainActivity.getInitialRoute()` now suppresses Flutter's route
   derivation for content/file schemes via a new pure `shouldSuppressInitialRoute()` in
   `SharePlugin.kt`, without touching `Intent.data` itself (SharePlugin still needs to read it).
2. **`d54d231`** — three fixes from a devil's-advocate review: `getInitialRoute()` now filters
   *super's resolved route* by scheme instead of pre-empting `Intent.data` directly (so an
   explicit `EXTRA_INITIAL_ROUTE` never gets discarded just because a content/file URI is also
   present); `SHARE_URI_SCHEMES` extracted as the one place `selectSource` and
   `shouldSuppressInitialRoute` both read, closing the "updated one, forgot the other" drift
   this file has now hit **four** times (`10411c1`, `810f061`, `cade169`, and this session's own
   first pass); a comment added to `auth_redirect_test.dart` noting its `content://` case now
   covers `GoRouter`'s defensive fallback only, not the primary path.
3. **`bedcf7b`** — **a second, independent bug found only by testing on real hardware** (Pixel
   9 Pro Fold): warm-resume "Open with" (app already running, task switched back to via
   `onNewIntent`) resolved the file correctly — confirmed in `PaperlessShare` logcat — and
   `ShareIntentHandler._pushRoute`'s `context.push()` reported success (no exception, mounted
   context, a frame even fired) — but the navigation was **silently lost**, screen stayed on
   Inbox. Root cause: the push happened while `AppLifecycleState` was still `inactive`, before
   Flutter's render pipeline finished reattaching post-resume. **Confirmed pre-existing**, not
   a regression from #1/#2 above — reproduced identically on the pre-session commit `581fa40`.
   Fix reuses #24's exact queue-and-flush mechanism: `_pushRoute` queues instead of pushing
   when `WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed`, and
   `_PaperlessGoAppState.didChangeAppLifecycleState` flushes it on the next `resumed` callback.

**On-device verification matrix** (Pixel 9 Pro Fold, debug build, real MediaStore
`content://` URI with `--grant-read-uri-permission` since the file:// scheme fails
`ContentResolver` under scoped storage and a bare `am start` VIEW intent has no read grant):

| Path | Result |
|---|---|
| Cold-start "Open with" | Lands directly on Upload File, no `/inbox` frame |
| Warm-resume "Open with" | Fixed by `bedcf7b`; reliable across 4 consecutive repros |
| `paperlessgo://` widget deep link | Unaffected |
| ACTION_SEND (share sheet) | Code path untouched by either fix; not independently exercisable via `adb am start` (the CLI's `--grant-read-uri-permission` doesn't extend to `EXTRA_STREAM`-carried URIs the way a real sender's `ClipData` grant does — confirmed via `resolveIntent` logs correctly parsing the URI before the `SecurityException`, i.e. an adb limitation, not an app bug) |

**Foldable gotcha, new this session:** `adb shell screencap` without `-d <display-id>`
silently defaults to "the first display found" on this device and can capture the *inactive*
cover-screen buffer (solid black) while the real UI is on the other display. Get real display
IDs from `adb shell dumpsys SurfaceFlinger --display-id` and always pass `-d`. This nearly
produced a false "warm resume is still broken" conclusion before cross-checking both displays.

**Also confirmed, not fixed:** `test/unit/router/auth_redirect_test.dart`'s `content://`
case was seen failing once mid-session inside a full-suite run, then passed cleanly on two
isolated re-runs immediately after — looks like ordering/isolation flakiness unrelated to
anything touched this session, not chased further. Watch for it recurring.

## Remaining open issues (unchanged — still two)

- **#13** — Submit to Google Play Console. Nothing to code; blocked on the user's manual
  Console work (org identity verification, App Signing enrollment, submit). Runbook is a
  comment on the issue per handoff 21.
- **#4** — Epic: Release & distribution follow-through. Parent of #13, closes when it does.

No open PRs, no other backlog.

## Process note

The warm-resume bug would not have been found without insisting on real hardware over
`flutter test` alone — the widget-test suite for `ShareIntentHandler` mocks
`WidgetsBinding.instance.lifecycleState` implicitly to whatever the test binding defaults to
(`null`, not `resumed`), so it never exercised the actual race. The regression test added in
`bedcf7b` only catches this *because* it explicitly drives the binding through `inactive` →
`resumed` — a pattern worth reusing anywhere else `context.push()` might race an Android
lifecycle transition. Second: cross-checking the pre-fix commit before writing up the
warm-resume bug (rather than assuming the newest change caused it) was what turned "did I
just introduce a regression" into "confirmed pre-existing, independent bug" — five extra
minutes of `git worktree add` + rebuild, cheap insurance against a wrong handoff entry.
