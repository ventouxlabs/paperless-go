# 26 — Session Handoff (2026-10-01) — v1.5.1 shipped (readable viewer title)

`main` is `efeeff8` (`chore: release v1.5.1`) on GitHub **and** GitLab, plus
this handoff commit on GitHub only. The next release mirrors it. Tag `v1.5.1`
is on both. The Release workflow was green:
- `build-apk` produced the APK and AAB on the GitHub release.
- `mirror-tag-to-gitlab` pushed `main` and the tag.

F-Droid (`AutoUpdateMode: Version`) should pick it up on its own. There is no
open PR or feature branch.

This supersedes the "Open" section of `25-handoff.md`. Everything else in 25
(demo server, GitLab token, device-testing rules) still stands.

---

## Shipped in v1.5.1

**The document viewer's title was unreadable** ("Page 1 of 1" / "Preview",
near-black on the black bar). Fixed in `f76819e`, together with the same bug
on the scanner's **Crop** screen.

- **Cause:** `AppTheme`'s `appBarTheme.titleTextStyle` is
  `textTheme.titleLarge`, which carries `tokens.ink`. Material's `AppBar` uses
  a theme title style as is and applies `foregroundColor` only to its own
  default style. So `foregroundColor: Colors.white` turned the icons white
  and left the title ink. In the dark theme ink is near-white, which hid the
  bug there.
- **Fix:** both forced-dark AppBars now set
  `titleTextStyle: Theme.of(context).appBarTheme.titleTextStyle?.copyWith(color: Colors.white)`.
  Annotate already passed an explicit white `TextStyle`, so it was not affected.
- **Rule for the future:** any new black AppBar must do the same.
  Memory: `project_forced_dark_appbar_title.md`.
- **Test:** `test/widget/forced_dark_app_bar_title_test.dart` covers the
  preview and crop screens in the light and dark themes. All 4 cases failed
  before the fix and pass after it. Add any new forced-dark screens to it.
- **Device:** checked in the `.debug` app on the Pixel against the demo. The
  viewer title is white. The Crop screen needs a camera scan, so it was
  checked only by the test.

## Local test-suite note

On this machine (Flutter 3.47), `flutter test` reports **13 golden failures**
(`test/widget/goldens/`). They fail the same way on unmodified `main`. CI uses
Flutter 3.41.3 and is green. Don't chase them locally.

Running `flutter test`, `flutter analyze` or `flutter build` rewrites
`analysis_options.yaml`. It also makes `git stash pop` abort, which happened
once this session with no loss. Run `git checkout -- analysis_options.yaml`
before any stash or commit.

## Release APK on the phone

The GitHub v1.5.1 `app-release.apk` has signer SHA-256 `a25ed068…dd58e81`,
which is the same key as `~/keys/paperless-go/paperless-go-release.jks`. So
`adb install -r` of the CI-built APK updates the release app in place and
keeps the login. You don't need to rebuild locally to put a release on the
phone.

## Open

- **Leftover cache files:** temp downloads under a previous extension linger
  if a document is later archived. This is cache-only, and was left as is.
- **`deleted_at` for the Trash date:** needs a `Document` model field, and so
  `build_runner`, which is broken on this machine. For now it uses `modified`.
- **Personal-looking doc on the reviewer demo:** `bryn car tax 2026` (#5) is
  still there. Carried over from 25.
- **GitLab mirror token expiry:** set a reminder. Carried over from 25.
- **#13** Play Console submission (blocked on the Ventoux org account); **#4**
  its epic.
