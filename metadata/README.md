# F-Droid metadata

**The build recipe is not in this repo.** It lives upstream in `fdroiddata`:

    metadata/com.ventouxlabs.paperlessgo.nogoogle.yml
    https://gitlab.com/fdroid/fdroiddata

A stale copy of that recipe used to sit here as `com.ventoux.paperlessgo.yml`,
pinned at 1.1.2 and filed under an id that was never published. It was mistaken
for the real thing and edited; deleted so there is one source of truth.

## Three application ids, none interchangeable

| id | what it is |
|---|---|
| `com.ventouxlabs.paperlessgo.nogoogle` | **the F-Droid build** — no ML Kit, Dart deskew fallback, no OCR suggestions |
| `com.ventouxlabs.paperlessgo` | the GitHub Releases / Play build |
| `com.ventoux.paperlessgo` | burned on Play, never reusable; survives only as the Kotlin `namespace` |

Checking F-Droid for either of the last two returns `NOT_FOUND`, which reads as
"not published" and is wrong.

## F-Droid builds from the GitLab mirror, not GitHub

    Repo: https://gitlab.com/selector4560/paperless-go.git

`UpdateCheckMode: Tags` scans **that** remote. A release tagged only on GitHub is
invisible to F-Droid — this has now stranded users twice (handoff 16, and again
at v1.1.8-v1.2.1). **After every release, push the tag to the mirror.**

## What in this directory IS live

- `en-US/` — fastlane-style listing text and per-version changelogs, read by
  F-Droid from the app repo. Changelog files are named by the per-ABI version
  code: `versionCode * 10 + abi`, where armeabi-v7a=1, arm64-v8a=2, x86_64=3.
  So versionCode 16 means `161.txt`, `162.txt`, `163.txt`.

## Do not delete `pubspec.lock.fdroid`

The upstream recipe does `cp pubspec.lock.fdroid pubspec.lock` before
`flutter pub get --enforce-lockfile`. It is a lockfile pre-resolved against the
stripped `pubspec.yaml` (no `google_mlkit_text_recognition`,
no `cunning_document_scanner`, and their orphaned transitive deps). Nothing in
this repo references it, so it looks vestigial. It is not.
