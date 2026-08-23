# 21 — Session Handoff (2026-08-22) — repo moved to ventouxlabs, F-Droid unstranded

`main` is `e5043ba` on **both** remotes. 326 Dart tests, `flutter analyze` clean, no open PRs.
Latest release **v1.2.1**; 4 commits on `main` are unreleased (docs + the F-Droid lockfile fix).

Supersedes the "OPEN" section of `20-handoff.md`; everything else in 20 still stands.

---

## The repo moved: `bearyjd/paperless-go` → `ventouxlabs/paperless-go`

GitHub redirects git and API traffic, so nothing broke loudly. Two things do not redirect:

1. **GitHub Pages.** `bearyjd.github.io/paperless-go/privacy-policy.html` now **404s**;
   Pages rebuilt at `ventouxlabs.github.io`. That is the URL `PRIVACY_POLICY.md` nominates
   for the Play Console privacy-policy field, and Google verifies it resolves — **#13 would
   have been rejected on it**, for a reason that looks unrelated to the move.
2. **Anything hardcoded.** README badges/clone URL, `PLAY_STORE_LISTING.md`,
   `PRIVACY_POLICY.md` — all updated. Handoffs and the April F-Droid plan were left as
   written; they record what was true then, but note the plan contains copy-pasteable
   metadata with dead URLs.

**Actions secrets survived the transfer** — `KEYSTORE_BASE64`, `KEY_ALIAS`, `KEY_PASSWORD`,
`STORE_PASSWORD` all present, so releases still build and the fingerprint gate still fires.
Worth re-checking after any future transfer; a repo move can drop them.

**Still pointing at the old owner:** the upstream fdroiddata metadata
(`AuthorName: bearyjd`, `IssueTracker: github.com/bearyjd/…`). `Repo:` is correct, so
builds are unaffected — needs an MR eventually, not urgently.

---

## F-Droid: users were stranded on 1.1.7, now unstranded

**Read this before touching anything F-Droid.** I got it wrong this session and it cost two
bad commits.

### Three application ids, none interchangeable

| id | what it is |
|---|---|
| `com.ventouxlabs.paperlessgo.nogoogle` | **the published F-Droid build** — no ML Kit, Dart deskew fallback, no OCR suggestions |
| `com.ventouxlabs.paperlessgo` | the GitHub Releases / Play build |
| `com.ventoux.paperlessgo` | burned on Play, never reusable; survives only as the Kotlin `namespace` |

Querying the F-Droid API for either of the last two returns `NOT_FOUND`. That reads as
"not published" and is **wrong** — which is exactly the mistake I made.

### F-Droid builds from the GitLab mirror, not GitHub

```
Repo: https://gitlab.com/selector4560/paperless-go.git
```

`UpdateCheckMode: Tags` scans **that** remote. The mirror was **53 commits and 4 tags
behind**: v1.1.8, v1.1.9, v1.2.0 and v1.2.1 existed only on GitHub, so F-Droid could not
see them. F-Droid users sat on **1.1.7** — without the share-intent fixes, the upload-queue
durability work, the queue screen, or any of the data-loss fixes.

Handoff 16 records this same failure at v1.1.5. **It has now happened twice.**

**Fixed this session:** `main` and all four tags pushed to the mirror (fast-forward, no
history rewrite). Both remotes are at `e5043ba`.

### The lockfile that would have failed the build anyway

The upstream recipe runs `flutter pub get --enforce-lockfile` against `pubspec.lock.fdroid`.
That file still pinned `receive_sharing_intent`, which `cade169` replaced with the native
ContentResolver plugin. An entry that no longer resolves is a hard failure — so F-Droid's
build of the tags just pushed would have failed.

Regenerated (`e5043ba`) with the documented recipe: strip `google_mlkit` and
`cunning_document_scanner` from `pubspec.yaml`, `pub get` in place over the fdroid lock,
restore. Verified the result is exactly the real lockfile minus the 9 intended packages —
**175 vs 184, no extras, no version mismatches**.

`pubspec.lock.fdroid` is referenced nowhere in this repo, only upstream. It looks vestigial.
It is not. Do not delete it.

### The recipe is not in this repo

It lives in `fdroiddata` as `metadata/com.ventouxlabs.paperlessgo.nogoogle.yml`. A stale
copy used to sit at `metadata/com.ventoux.paperlessgo.yml`, pinned at 1.1.2 under an id
that was never published — I mistook it for authoritative and "updated" it. Deleted;
`metadata/README.md` now explains all of the above so the next person does not repeat it.

What *is* live in `metadata/` is `en-US/` — the listing text and per-ABI changelogs F-Droid
reads from the app repo, named `versionCode * 10 + abi` (armeabi-v7a=1, arm64-v8a=2,
x86_64=3), so versionCode 16 means `161/162/163.txt`.

---

## OPEN — start here

### 1. Cut v1.2.2 so F-Droid has a buildable tag

The lockfile fix is on `main` but **not in any tag**. F-Droid's autoupdate will pick up
v1.2.1, whose tree still has the broken lockfile, and fail. A patch release puts the fix in
a tag. Nothing else needs to change.

**Push every future tag to the mirror**, or this recurs a third time. Better: add a step to
`release.yml` that pushes the tag to GitLab, so the two channels cannot drift.

### 2. Retention: the decision is due

`upload_queue_service.dart` states its own precondition — deletion becomes defensible once
the queue is visible, which shipped in v1.2.0. Either retention deletes again after 30 days,
or storage grows unbounded forever and that becomes permanent by default. Product call.

### 3. Play Console (#13) — one-way door

The app signing key **must** be the existing `paperless-go-release.jks`, not one Google
generates. Full runbook and the fingerprint to verify are a comment on #13, and it is now
the first acceptance criterion. The privacy-policy URL it depends on is fixed (above).

### 4. Smaller

- The AAB is not signature-checked in CI (`apksigner` does APKs; bundles need jarsigner).
- The v1.2.1 copy fix was never seen on hardware — both phones were unplugged.
- `.omc/skills/` is gitignored, so this session's learned skills are local to one machine.

---

## Process note

Three times this session a confident conclusion was wrong, and each was caught only by
looking at raw output instead of a summary: dates rendering as year 58603 (my seed data was
milliseconds), an emulator upgrade chain that "proved" a signing-key rotation
(`INSUFFICIENT_STORAGE`), and **"the app is not on F-Droid"** — from checking two ids and
not reading handoff 17, which recorded the merged MR.

The F-Droid one is the instructive failure: absence of evidence across two guesses got
reported as evidence of absence, and I then edited files and repointed README badges on the
strength of it. **Check the handoffs before asserting a fact about distribution.**
