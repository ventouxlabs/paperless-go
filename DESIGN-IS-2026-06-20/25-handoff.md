# 25 — Session Handoff (2026-09-30) — v1.5.0 shipped (#39, #41, #42, #43), GitLab mirror token rotated, demo on Paperless-ngx 3.2.1

`main` is `c0912f3` (`chore: release v1.5.0`) on GitHub **and** GitLab. Tag
`v1.5.0` is on both. The Release workflow was green end to end:
- `build-apk` built and signature-checked the APK and AAB and published the GitHub release.
- `mirror-tag-to-gitlab` pushed with the **new** token.

F-Droid (`AutoUpdateMode: Version`) should pick v1.5.0 up on its own schedule.
No open PR, no feature branch.

Supersedes the "remaining open issues" section of `24-handoff.md`. #40
(mirror credential) is **closed**; see below.

---

## Shipped in v1.5.0

All of these have tests shown to fail against the old code, independent
code-reviewer passes, and CI green. Each was also checked on a real Pixel against the demo server.

**#39 — Move to trash failed on Paperless-ngx 3.x.** `trashDocuments` sent
bulk_edit method `trash`, which upstream has never accepted (400). Now sends
`delete`, which upstream soft-deletes into the trash. It is a *legacy*
bulk_edit method: accepted at API `version=9`, which the app sends, and
slated for removal when upstream drops v9.

**The whole Trash screen was wired to APIs that don't exist**, found while
fixing #39:
- `getTrashedDocuments` filtered `/api/documents/?is_in_trash=true`. That is
  not a real filter; DRF ignored it and listed *live* documents.
- `restoreFromTrash` sent `undo_delete`, which is invalid.
- `emptyTrash` sent bulk `delete`, which can't hard-delete a document that is
  already trashed.

All three now use `/api/trash/` (`GET`, and `POST {documents, action:
restore|empty}`). A restore now invalidates the Documents and Inbox lists.
Trash restore and delete failures now show the reason. A trashed row no longer
passes its *created* date off as the deletion date.

**#41 — bulk "Redo OCR" sent `redo_ocr`.** That is not a valid choice on
2.20 or 3.x. It now sends `reprocess` via `PaperlessApi.reprocessDocuments`.

**#42 — the scanner remembers the enhancement preset**, including None.
- `selectedPresetProvider` is now a hand-written `NotifierProvider`. The
  choice is stored in secure storage under `scanner_preset`.
- It saves first, then sets state. A failed save shows a snackbar and does
  not leave a choice on screen that would silently revert.
- The per-batch Adjust screen still only overrides that batch.
- Sign-out resets the preset along with the other preferences.

**#43 — non-PDF documents were saved, shared and viewed as PDFs.**
`/download/` and `/preview/` both serve the archived PDF only when one
exists. Otherwise they serve the original (text, CSV, an image…) with its
own Content-Type. The reporter believed `/preview/` is always a PDF; it
isn't, and they were told so on the issue.
- `downloadDocumentTyped` names the file from the response headers, in this
  order: Content-Disposition, then Content-Type, then original name, then `bin`.
  It is never an assumed `.pdf`, and only a `[a-z0-9]{1,8}` extension is taken
  from those untrusted headers.
- Save and share declare each file's own MIME type.
- The viewer shows a "No preview for .txt files" panel with a Share button.
- Annotate and Compress refuse non-PDFs with a plain message.
- The untyped `downloadDocument` was removed.
- `mime` is now a direct dependency, at the same locked 2.0.0.

## GitLab mirror (#40) — fixed and closed

- **New token:** a fine-grained GitLab token (Repository read+write, scoped to
  `selector4560/paperless-go`) is in the `GITLAB_MIRROR_TOKEN` secret, set
  2026-09-29.
- **New workflow:** `.github/workflows/mirror-gitlab.yml` (**Mirror main to
  GitLab**) is manual-only and fast-forwards GitLab `main` with no tag. Use it
  to test a rotated token without a release; that's how #40 was verified. The
  v1.5.0 release then mirrored with it too.
- **The token value appeared in a session transcript**, because it was pasted
  into chat. Rotating it is the user's call. If rotated, use
  `gh secret set GITLAB_MIRROR_TOKEN --repo ventouxlabs/paperless-go` (it
  prompts), then run the manual workflow.
- **Expiry:** set a reminder before the token expires. A dead token fails
  silently from F-Droid's point of view.

## Demo server (`.23`, https://paperless-demo.ventouxlabs.com)

- **Upgraded 2.20.15 → Paperless-ngx 3.2.1.** The pre-upgrade backup is
  `~/paperless-demo-backups/demo-2.20.15-20260928-021646.tgz`.
- **The nightly `reset.sh` never actually wiped anything.** The volumes are
  bind mounts to `/var/lib/paperless-go-demo-quota/*`, and `down -v` doesn't
  touch those. Under 3.x, which consumes duplicates, the reseed added 3
  duplicate samples every night.
  - The user chose to keep the data and stop the duplicates. `reset.sh` now
    passes existing `original_filename`s as `SKIP_SAMPLES` to
    `seed/make_samples.py`. Pre-edit copies are `*.bak-20260930-*`.
  - The 9 duplicates were removed. The demo is at documents 1, 2, 3, 5, 6 with
    an empty trash.
- **Personal-looking document still on the reviewer demo:**
  `bryn car tax 2026` (#5, added Sep 1) is still there. The user was told and
  hasn't acted on it.
- **`.23` sometimes drops off the LAN** (no ping or SSH) while the tunnel keeps
  serving. Retry later.
- **API-version gotcha:** when curl-testing 3.x by hand, send
  `Accept: application/json; version=9`. Without it, `/api/tasks/` returns
  the new paginated shape the app never sees. See memory
  `project_api_version_pin.md`: bumping the pin breaks upload polling and
  every bulk action at once.

## Device testing

- **Test in the debug build, not the release app.** Use the `.debug` package,
  token-signed into the demo. Signing the release app out would wipe its
  offline cache and the downloads-folder grant.
- **The debug app is still installed on the Pixel 10 Pro Fold,** signed into
  the demo.
- **The phone is the user's daily device.** Check `mCurrentFocus` before
  driving it. This session backed off twice when the phone was in use, and
  once when another session (Bascule) was using it.

## Open

- ~~**Document viewer title:** dark grey on black.~~ **Fixed in v1.5.1**
  (`f76819e`). The theme's AppBar `titleTextStyle` carries the ink colour and
  beats an AppBar's `foregroundColor`, so any forced-dark AppBar must also set
  `titleTextStyle`. The Crop screen had the same bug and was fixed too.
  Verified on the Pixel.
- **Leftover cache files:** temp downloads under a previous extension linger
  if a document is later archived. This is cache-only, and was left as is.
- **`deleted_at` for the Trash date:** needs a `Document` model field, and so
  `build_runner`, which is broken on this machine. For now it uses `modified`.
- **#13** Play Console submission (blocked on the Ventoux org account); **#4**
  its epic.
