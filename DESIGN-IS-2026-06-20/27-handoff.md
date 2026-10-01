# 27 — Session Handoff (2026-10-02) — build_runner fixed (via Flutter 3.41.3), cache cleanup committed, no release held

Supersedes the "Open" section of `26-handoff.md`. Everything else in 25/26
(demo server, GitLab token, device-testing rules, forced-dark AppBar rule)
still stands.

**Release state:** latest release is **v1.5.1** (`efeeff8`, on GitHub and
GitLab, installed on the Pixel). `main` has **unreleased** work on top of it.
The user chose to hold the next release until there is more to ship.

**Push state:** `906fc49` and `1f36456` (cache cleanup + handoff 26 update) are
pushed. The commits made this session — the regenerated `.g.dart` files and
this handoff — are **local only, not pushed**. Nothing was pushed without an
instruction.

---

## Unreleased on `main`

**Stale cached downloads are cleaned up (`906fc49`).** `downloadDocumentTyped`
caches `<stem>.<ext>` with the extension the server sends. When a document's
type changed (a `.txt` original later archived as a PDF) the old copy lingered.
After a successful download it now deletes same-stem siblings whose suffix is
one `downloadExtension` could have produced (`deleteOtherTypeVariants` in
`lib/core/api/download_file_type.dart`). A failed delete is logged and skipped;
a failed download keeps the old copy. Independent review: no CRITICAL/HIGH.
One accepted risk: two downloads of the same document in flight at once, across
a server-side type change, could delete each other's file. Not locked. Not
checked on the phone (needs the server to archive a document).

**Provider hashes regenerated.** Six `*.g.dart` files changed by one line each
(`app`, `auth_provider`, `document_detail_notifier`, `documents_notifier`,
`upload_notifier`, `trash_notifier`). They are `@riverpod` source hashes that
had gone stale because providers were edited while codegen was broken. No
runtime effect.

## build_runner: fixed

The "broken and destructive" note was right for the machine's **Flutter 3.47 /
Dart 3.13** (pinned `analyzer` 7.6.0 can't parse dot-shorthand syntax). It runs
cleanly under **Flutter 3.41.3** (CI's version): exit 0 in **28 s** on the
unchanged lockfile, 50 generated files intact.

Recipe (also in memory `project_toolchain_codegen_broken.md`):
1. 3.41.3 is installed side by side at `~/flutter-sdks/3.41.3`. Your normal
   `flutter` is untouched.
2. Work in the throwaway worktree `~/flutter-sdks/codegen-wt`: move it to the
   current `main` (`git -C … checkout --detach <sha>`; `git worktree prune`
   and re-add if it vanished), then
   `PATH=$HOME/flutter-sdks/3.41.3/bin:$PATH flutter pub get` and
   `timeout 420 dart run build_runner build --delete-conflicting-outputs`.
3. Copy back only the changed `*.g.dart` / `*.freezed.dart`. **Never copy
   `pubspec.lock`**: 3.41.3 re-pins 4 SDK-bound test packages to older versions.

Gotchas: the first `pub get` on 3.41.3 is slow (~60 s font download; once a
transient DNS failure). A 30-minute background run was killed with no output;
use a short `timeout` and log to a file.

**Consequence:** `@riverpod` and `@freezed` are usable again, so the hand-written
provider workaround is no longer required. That unblocks the Trash
`deleted_at` field (needs a `Document` model change + codegen). Upgrading
`analyzer`/`build_runner` for Dart 3.13 was not attempted and isn't needed
while the recipe works.

## Local test run: two quirks

Baseline on this machine is **13 failures, all goldens** (Flutter 3.47 vs CI's
3.41.3). Verified this session: **495 pass, 13 fail, 0 others** (with the
quirk below worked around).

- **`libsqlite3.so` is missing** (only `libsqlite3.so.0` exists), which fails
  ~73 Drift-backed tests (upload/edit queue, template, document-lock) and
  shows as "86 failures". It passed with only the goldens failing on
  2026-10-01; what changed is **not investigated**. Workaround, no system change:
  `ln -sf /usr/lib64/libsqlite3.so.0 ~/flutter-sdks/sqlite-shim/libsqlite3.so`,
  then `LD_LIBRARY_PATH=$HOME/flutter-sdks/sqlite-shim flutter test`.
  Memory: `project_local_test_sqlite_shim.md`.
- `flutter test/analyze/build` rewrites `analysis_options.yaml`;
  `git checkout -- analysis_options.yaml` before any stash or commit.

## Next

1. **Push** the local commits when the user says so.
2. **Real Trash deletion date:** add `deleted_at` to the `Document` model and
   regenerate via the recipe above (now unblocked). The screen uses `modified`.
3. **Local goldens:** pin Flutter 3.41.3 locally or skip goldens off CI, so a
   local run isn't always red.
4. **Release v1.5.2** when there's more than the cache cleanup to ship.

## Open (carried over)

- **Personal-looking doc on the reviewer demo:** `bryn car tax 2026` (#5) is
  still there.
- **GitLab mirror token expiry:** set a reminder.
- **#13** Play Console submission (blocked on the Ventoux org account); **#4**
  its epic.
