# 24 — Session Handoff (2026-09-25) — v1.4.0 shipped (private-CA support, two scanner bugs), GitLab mirror credential needs renewal

`main` is `0df5222` on GitHub. On GitLab it is level with GitHub content-wise
(`gitlab/main...main` is 0/0) but was pushed manually this session, not by
CI — see "GitLab mirror" below, this is the one thing that needs your hands.
Tag `v1.4.0` pushed to both remotes. GitHub Release built and uploaded
(`app-release.apk`, `app-release.aab`). CI green throughout. No open PR,
no feature branch — this repo's `main`-only convention held.

Supersedes the "OPEN" section of `23-handoff.md`; everything else in 23
still stands (downloads-location / PR #33 should already be resolved by
now — if not, that handoff has the full context).

---

## Shipped this session — four commits, closes #36 and #37

**`60024a5` fix(login): say why the connection probe failed.** The "test
connection" button on the login screen showed only a red `!` for every
failure — unreachable host, timeout, and untrusted certificate all looked
identical. `AuthService.testConnection` now returns `(ok, reason)` instead
of a bare `bool`; the login screen renders the reason under the URL field
and clears it when the URL is edited. Also fixed in the same commit: an
`ArgumentError` (not `DioException`) that used to escape uncaught when the
URL field held its default `https://` — now pre-validated before a `Dio`
instance is even built.

**`57d4a29` feat(android): trust user-installed CA certificates — closes
#36.** Two external users reported that installing their private CA's root
certificate on the device had no effect — the app kept rejecting the
connection. Root cause: Dart's `HttpClient` reads Android's *system* CA
store only, never the user-installed one (open upstream since 2022:
dart-lang/sdk#50435). Fix reads `AndroidCAStore` `user:*` aliases via a new
Kotlin plugin and feeds them into a `SecurityContext` installed through
`HttpOverrides.global` before `runApp` — one hook that covers `dio` *and*
`cached_network_image`/`flutter_cache_manager` (thumbnails bypass `dio`
entirely and would otherwise still fail). Full mechanism, the two upstream
alternatives that were rejected and why (Play-Services-only `cronet_http`,
Flutter-version-gated `flutter_user_certificates_android`), and the dio
`badCertificate`-vs-`HandshakeException` gotcha are in
`project_user_ca_trust_store.md`. **Verified on a real Pixel** against a
throwaway Caddy `tls internal` proxy standing in for a private-CA server —
both the negative case (before installing the CA: full error text, not
"Connection failed (unknown)") and the positive case (after installing:
login succeeds, thumbnails load — proving the `HttpOverrides` approach
actually reaches the thumbnail path, not just `dio`). Issue closed with a
comment to both reporters; the second reporter's actual ask ("add an
ignore-certificate-errors toggle") was explicitly declined as a MITM
footgun, with TOFU pinning named as the only acceptable shape if that's
ever revisited.

**`b61f5b4` fix(scanner): never drop a scanned page from the PDF in
silence.** Found by triaging an abandoned bug queue on a stale `origin/
master` branch before deleting it (see below) — 18 of its 19 archived bugs
were already fixed on `main`; this was the one still live. `_buildPdf`
silently `continue`d past any image it couldn't decode, so a 5-photo scan
could upload as a 4-page PDF with no indication anything was wrong — the
preview screen made this worse by rendering the *source* images and a
counter reading `imagePaths.length`, so it showed "5 / 5" right up to the
point of upload. Now collects failed page numbers and throws
`PdfPageDecodeException` before any bytes are written; all three callers
surface the specific message (a generic `friendlyApiMessage` fallback
would otherwise have swallowed it, since it only maps `DioException`).
Also closes a real false-positive risk found during review: a page whose
enhancement failed can ride through as a raw camera JPEG under a
batch-wide `preProcessed: true` flag, and the fast header-only decoder
isn't built to handle every legal JPEG marker layout — so a page is only
declared truly unreadable when *both* the fast path and a full
`img.decodeImage` reject it.

**`3d827c1` fix(scanner): match PDF page shape to the rotation the
renderer applies — closes #37.** Filed and fixed in the same session.
The bug above's fast path assumed enhance-pipeline output is always
already EXIF-baked and skipped `bakeOrientation` — true for normal output,
false for the raw-camera-JPEG-under-`preProcessed:true` case the previous
fix just made reachable-without-crashing. Net effect: a portrait photo
that fell back to its raw file got a landscape PDF page, upright image
letterboxed into a centre strip. **First implementation attempt was wrong
and got caught by review**: it hand-rolled its own EXIF parser, but the
`pdf` package has its *own*, separate EXIF reader (`pdf/lib/src/pdf/
exif.dart`) that actually decides what gets drawn — two independent
parsers could disagree and leave the bug silently live for exactly the
malformed-ish inputs where hand-rolled parsers diverge. Redesigned to call
`PdfJpegInfo` — the *same* class `pw.MemoryImage` already constructs
internally — so the fast-path gate agrees with the renderer by
construction, not by coincidence. This also deleted ~75 lines instead of
adding them. Full writeup, including why `PdfJpegInfo` is cheap (~113µs,
header-only, not a pixel decode) and a canary test guarding a currently-true
`image`-package assumption (that re-encoding clears the orientation tag),
is in `project_scanner_pdf_pipeline.md`.

All four commits: independently reviewed (code-reviewer, plus
security-reviewer for the CA work), CI green on Flutter 3.41.3, and this
machine's local suite at 450/463 (the 13 failures are the long-standing
golden/font baseline, unrelated, present on a clean `main` too).

## Housekeeping this session

- **`origin/master` deleted.** Unrelated-history orphan branch, last
  commit Feb 2026, 149 files vs `main`'s 475+. Every one of its 19 archived
  `debug/queue/*.md` bug reports was read and checked against current
  `main` before deletion: 18 already fixed, 1 became `b61f5b4` above. No
  `.dart` file unique to it. Tip was `863b126` if ever needed from
  reflog/GitHub's dangling-commit search.
- 10 merged-PR remote branches pruned (`feat/downloads-location` and
  friends — all already merged, PR #33 from handoff 23 included).
- Throwaway private-CA test proxy on the `.23` demo box torn down after
  use (container + the volume holding its CA private key both removed).

## GitLab mirror — needs your hands, filed as #40

The `mirror-tag-to-gitlab` job in the `Release` workflow **failed on this
release** with `fatal: Authentication failed for 'https://gitlab.com/
selector4560/paperless-go.git/'` — every release back through v1.2.0
succeeded, so this is a new credential problem, not a flake. Almost
certainly an expired GitLab personal access token stored as a GitHub
secret.

**Not blocking right now** — `main` and the `v1.4.0` tag were pushed to
GitLab manually this session, so the mirror is correct and F-Droid (which
builds from GitLab, `AutoUpdateMode: Version`) will pick this release up
normally. **Will silently block the next one** if not fixed first: GitHub
releases will keep succeeding since `build-apk` is a separate job, so
nothing will look broken until someone notices F-Droid is stuck on
v1.4.0.

Fix (needs GitLab account access, not something I can do): generate a new
GitLab PAT for `selector4560` with `write_repository` scope, update the
GitHub Actions secret the mirror step reads. Tracked as **#40**.

## Remaining open issues (unchanged)

- **#13** — Submit to Google Play Console. Still nothing to code; blocked
  on the Ventoux org account + manual Console work. Checked this session:
  the public demo server reviewers would use
  (`https://paperless-demo.ventouxlabs.com`) is up and its cert is valid
  through Nov 17 2026, so nothing there is stale if you get to this.
- **#4** — Epic: Release & distribution follow-through. Parent of #13.
- **#40** — GitLab mirror credential, new this session, see above.
