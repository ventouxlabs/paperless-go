# 19 — Session Handoff (2026-08-18) — PRs #25 and #28 merged, retention stopped deleting, drain restructured

> **SUPERSEDED by `20-handoff.md` (2026-08-22).** The state below is stale in the way
> that matters most: it says the queue work is unreleased and `main` is at `9b65be0`.
> v1.1.9, v1.2.0 and v1.2.1 have all shipped since. Read 20 first.

Everything from `18-handoff.md` is now on `main`, plus a second PR. `main` is `9b65be0`,
277 Dart tests, `flutter analyze` clean, verified locally after each merge.

**Still not released.** Live is v1.1.8 and contains **none** of this — including the fixes
where a shared document could be silently destroyed. Shipping needs a version bump and a
release build. That is the next decision, and it is bigger than any remaining queue work.

**Use the pinned SDK**: `/home/user/Documents/vibe-code/sdk/flutter/bin/flutter` (3.41.3).
Note its `dart format` wants to reflow the whole repo to the new tall style — that noise is
not yours; back it out rather than committing it.

---

## What merged

### PR #25 — share intent + upload queue (21 commits, rebase-merged)

The work described in `18-handoff.md`, plus this session's fixes to it:

- **Retention never ran when signed out.** The drain returned at the
  `paperlessApiProvider` guard before it ever fetched the queue, so a signed-out launch
  swept nothing. The sweep is now its own pass ahead of API resolution, with a per-row
  fault boundary.
- **Retention no longer deletes anything** — see the decision below.
- Outcome is recorded before bytes are released, the only ordering that converges.

### PR #28 — upload-pass fault boundaries (issue #26, partial)

- **Per-row fault boundary** on the upload pass. Three throws escaped it before: the retry
  bookkeeping (raised from *inside* the pass's own catch), the missing-file write (outside
  the try entirely), and anything the send raised after its catch.
- **Sealed `UploadDecision`** (`upload_decision.dart`) replacing four sequential guard
  clauses whose ORDER carried correctness. A new outcome is a compile error now — verified
  by adding a fourth subclass and getting `non_exhaustive_switch_statement`.
- **`getPendingUploads()` orders by `id`.** It had no `ORDER BY` at all, so which upload
  got retried first was whatever SQLite returned. Ordered by `id`, not `queuedAt`, because
  `queuedAt` comes from `DateTime.now()` and can move backwards.
- Unreadable `tagsJson` is terminal rather than burning five retries.

---

## THE DECISION THAT MATTERS: retention does not delete

Expiry after 30 days records the outcome and **keeps the file**. Reversed deliberately.

`DateTime.now()` is not monotonic, and retention compared two wall-clock samples up to 30
days apart with no sanity check on either. A clock jump expires rows that are days old; a
`queuedAt` stamped while the clock ran ahead makes the difference negative, so that row
never expires and its file was held forever — the bound did not bound. A plausibility
heuristic cannot fix the forward direction: a 45-day jump is indistinguishable from 45 days
elapsed against a 30-day window, so any threshold narrows the hole without closing it.

With no queue UI, deleting on a timer that can be wrong meant silently destroying the
user's only copy of a document.

**The cost, and it is real:** app-documents storage is not evictable, so abandoned files
now accumulate until the user clears app data. **"Storage grows" is expected behaviour
today, not a bug.** This is the wrong way round long-term. The queue UI is what makes
releasing the file defensible again — that is now the strongest argument for building it,
and it is the third time this queue has traded storage for not-losing-documents.

---

## OPEN

### 1. Not released — decide before more queue work

v1.1.8 is live without any of this. Related: #13 (Play Console submission), epic #4.
No Play review has happened yet, so the demo server `paperless-demo.ventouxlabs.com`
**stays up** — the handoffs' "tear down after Play review" is not overdue, and it should
stop being re-raised as a pending chore until review actually happens.

### 2. Queue UI (unblocks the retention trade)

Failed rows, `lastError`, wrong-profile rows and legacy rows are all invisible, and files
now accumulate silently. Minimal version: a "stuck uploads" list with retry and delete.

### 3. #26 remainder

`getPendingUploads()` materializes every row in one eager `.get()` outside any boundary, so
a row that fails to *deserialize* still takes down the pass. Needs a repository return-shape
change. Also: no deserialization-failure test, and the sweep's dropped-row `debugPrint` is
assert-guarded so it leaves no trace in release.

### 4. #27 — `edit_queue_service.dart:16` orders queued edits by `queuedAt`

Same root cause as the retention clock finding: a backwards clock jump applies edits out of
order. The upload queue fixed its instance by ordering on `id`; this one hasn't.

---

## Process notes worth keeping

**Outside review earned its keep, twice more.** Two independent agents reviewed the
retention work: zero overlap in findings, and the one that changed the design (the clock
analysis) came from the adversarial pass, not the checklist pass. Then `/codex review`
caught a P2 on #28 that neither self-review nor the earlier agents did.

**The recurring failure was vacuous tests, not wrong code.** Three separate fault-boundary
tests passed with the boundary removed. Causes: undefined row order (no `ORDER BY`), a fake
that failed only on its first *call* while the service drains on `build()` as well as on
demand, and failing the last row (or the only row), where a broken loop strands nothing.
Fixed once in the retention sweep, then repeated an hour later in the upload-pass tests —
the lesson did not carry across. Written up in
`.omc/skills/queue-drain-test-falsifiability-expertise.md` (note `.omc/` is gitignored, so
that file is local to one machine).

**Rule that came out of it:** a green "it survived the failure" test is not evidence.
Neutralize the mechanism, run it, confirm red — as part of writing the test.
