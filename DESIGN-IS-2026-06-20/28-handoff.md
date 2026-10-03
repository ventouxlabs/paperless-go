# 28 — Session Handoff (2026-10-03) — v1.5.2 released (real Trash date, cache cleanup), goldens green locally, CI off Node 20

Supersedes the "Next" and "Open" sections of `27-handoff.md`. Everything else
in 25–27 (demo server, GitLab token, device-testing rules, forced-dark AppBar
rule, the build_runner recipe) still stands.

**Release state:** latest release is **v1.5.2** (`f5d7cf5`, tag lightweight
like v1.5.1). GitHub Release has the APK + AAB; the release workflow's
signature gate passed and the downloaded APK carries the release key
(`a25ed068…`, versionCode 22). `mirror-tag-to-gitlab` pushed `main` and the
tag, so F-Droid can see it.

**Push state:** everything up to `f5d7cf5` is on GitHub **and** GitLab. This
handoff commit is **local only**.

---

## Shipped in v1.5.2

- **Real Trash deletion date (`b7d468d`).** `Document.deletedAt` maps
  Paperless-ngx's read-only `deleted_at` (checked on the demo's ngx 3.2.1: in
  `DocumentSerializer`, present under `version=9`, null on live docs; the trash
  GET uses that serializer and the app sends no `fields=`). The Trash subtitle
  is `(deletedAt ?? modified)?.toLocal()`. Generated files came from the
  3.41.3 recipe. Reviewed (no CRITICAL/HIGH); one LOW accepted: no test pins
  `.toLocal()` (would need a `TZ=` run).
- **Stale cached downloads cleaned up (`906fc49`)**, from handoff 26.

## Not user-visible, also on `main`

- **Goldens green locally (`69ddd85`).** `test/widget/goldens/flutter_test_config.dart`:
  off CI a golden passes at ≤1% pixel diff; with `CI=true` it is exact.
  Proven both ways (no CI → 16/16; `CI=true` → the same 13 fail; tolerance at
  0.1% → exactly the 5 goldens above 0.1% fail). **Local baseline is now 0
  failures (511/511)** with the sqlite shim. A local golden pass is
  approximate; `CI=true flutter test test/widget/goldens/` gives the exact
  result. README in that dir explains it.
- **CI off Node 20 (`469245e`).** `actions/checkout` v4→**v5**,
  `actions/setup-java` v4→**v5**, `softprops/action-gh-release` v2→**v3**.
  Deliberately not checkout v6+/v7 (moves persisted credentials, keeps
  annotated tags on fetch) or setup-java v6 (Temurin version-parsing fix
  #1279 unreleased as of 2026-10-03). **All three are now proven** by the
  v1.5.2 release run. Node 20 warning gone from CI.

## On-device check (Pixel 10 Pro Fold, read-only, user-approved)

- The release app was found **on the login screen** before the update
  (user: "not sure" whether it was logged in). Not a regression: after the
  user logged in, both **new→new reinstall** and **CI v1.5.1 APK → new build**
  kept the login (checked by `uiautomator dump`, no input).
- Document preview rendered (exercises `downloadDocumentTyped` and the new
  cleanup on real storage); no crash.
- **The new Trash date was not seen on device:** the user's trash is empty.
  Covered by the server contract check and unit tests only.
- The phone runs the **local pre-release build** (identical code, but labelled
  `1.5.1`/versionCode 21). Installing the published v1.5.2 APK with
  `adb install -r` would make the label match; not done without asking.

## Environment notes (this machine)

- **`~/.gitconfig` GitHub credential helper is broken:** it points to
  `/home/linuxbrew/.linuxbrew/bin/gh`, which no longer exists (`gh` is now
  `/usr/bin/gh`). HTTPS pushes to GitHub fail with "could not read Username".
  Fix: `gh auth setup-git` (user's call — global config). Workaround used:
  `git -c credential.https://github.com.helper= -c "credential.https://github.com.helper=!/usr/bin/gh auth git-credential" push …`.
  GitLab pushes use SSH and are unaffected.
- **GitLab now shares GitHub's history**; `git push gitlab main` is a plain
  fast-forward. The old "unrelated histories / tree-overlay" memory was
  updated.
- `debug-info/` is **not** in `.gitignore`; this session sent local
  `--split-debug-info` output to the scratchpad instead.

## Next

1. **Push this handoff** when the user says so.
2. **`ubuntu-latest` → Ubuntu 26 from 2026-10-19.** Watch the first CI and
   release runs after that date, or pin `ubuntu-24.04` beforehand.
3. **setup-java v6** once a release with #1279 ships (optional).
4. Optionally update the Pixel to the published v1.5.2 APK.

## Open (carried over)

- **Personal-looking doc on the reviewer demo:** `bryn car tax 2026` (#5).
- **GitLab mirror token expiry:** set a reminder.
- **#13** Play Console submission (blocked on the Ventoux org account); **#4**
  its epic.
