# 20 — Session Handoff (2026-08-22) — three releases shipped, queue verified on hardware, release signing repaired

`main` is `50bd8a5`. **326 Dart tests**, `flutter analyze` clean, no open PRs.
**v1.2.1 is live** and `main` has nothing unreleased.

`19-handoff.md` is superseded — it still describes the queue work as unreleased.

**Use the pinned SDK**: `/home/user/Documents/vibe-code/sdk/flutter/bin/flutter` (3.41.3).
Its `dart format` wants to reflow the whole repo to the new tall style; that noise is not
yours, back it out rather than committing it.

---

## Released since handoff 19

| Version | Contents |
|---|---|
| **v1.1.9** | Share intent + upload queue durability (PR #25). Retention stopped deleting files. |
| **v1.2.0** | Upload queue screen (#29), drain fault boundaries + sealed outcomes (#28), per-row decode boundary + edit ordering (#30). Minor bump: new feature. |
| **v1.2.1** | Queue copy fix (#31), release signing repair (#32). |

Issues #26 and #27 closed. #13 and #4 remain, both distribution.

---

## Verified on hardware, not just in tests

Ran v1.2.0 on a **Pixel 9 Pro Fold** (signed in) and a **Pixel 10 Pro Fold**
(GrapheneOS, Android 17, signed out). What that proved, which tests could not:

- The Inbox banner counts only rows needing a decision — 3 of 7 seeded rows, with the
  three merely-waiting ones correctly ignored.
- All five row states render; the damaged-row notice fires for a corrupt `queued_at`.
- The bulk-delete dialog discloses cross-profile deletion, naming the other server.
- **Retry on a 31-day retention-expired row worked**: `Failed · Jul 19` became
  `Waiting · Aug 19` and actually attempted an upload. Pre-fix that row was re-failed
  without a single attempt. This is the P1 `/codex review` found on #29.
- On the signed-out Pixel 10, a seeded 31-day row came back `is_failed=1,
  "Gave up after 30 days…"` **with its file still present** — retention running while
  signed out (the first fix of the whole arc) and the keep-the-bytes policy, both
  confirmed on a real device.

### Device runbook (saves rediscovering it)

```bash
# The Folds have two displays; screencap without -d prepends a warning that
# corrupts the PNG. Get the id first, and target it every time.
adb -s <serial> shell dumpsys SurfaceFlinger --display-id
adb -s <serial> exec-out screencap -p -d <display-id> > shot.png

# Seed queue rows (debug build only — run-as needs a debuggable package).
adb -s <serial> shell am force-stop com.ventouxlabs.paperlessgo.debug
adb -s <serial> shell run-as com.ventouxlabs.paperlessgo.debug \
  cat /data/data/com.ventouxlabs.paperlessgo.debug/app_flutter/paperless_cache.sqlite > c.sqlite
# edit with sqlite3, push back via /data/local/tmp, then delete the -wal/-shm files
```

**`queued_at` is unix SECONDS.** Inserting milliseconds renders as the year 58603 and
looks exactly like a date-formatting bug in the app. It is not.

**Take the phone offline before draining** (`svc wifi disable`, `svc data disable`) —
CLAUDE.md forbids live writes to a Paperless instance during debug. Restore afterwards.

---

## The signing incident (root cause, fixed in #32)

A Pixel 10 carrying "v1.1.7" refused every upgrade. It had to be wiped, losing that
install's server config and credentials.

**Cause:** `android/app/build.gradle.kts` fell back to `signingConfigs.debug` when
`key.properties` was absent. `flutter build apk --release` on a keystore-less checkout
therefore produced something that looked entirely legitimate — right applicationId, right
version, minified, shrunk — but carried the **universal Android debug key**.

**Why that is more than an upgrade nuisance:** the debug key is public. Any APK anyone
signs with it, using this applicationId, can upgrade such an install in place and inherit
its data directory — which holds the Paperless server URL and API token.

**Fixed:** no keystore now means **unsigned** (Android rejects it outright:
`INSTALL_PARSE_FAILED_NO_CERTIFICATES`). Source builds still work; the builder signs
deliberately. CI additionally asserts the certificate fingerprint before publishing.

**Release key** (verified 2026-08-22): alias `paperless-go`, RSA 2048, `SHA384withRSA`,
valid to 2053-07-13, SHA-256
`a2:5e:d0:68:ab:33:1c:29:2c:cc:b5:8b:79:1d:9a:b6:5b:97:11:54:95:42:bc:c8:8b:63:08:7b:dd:d5:8e:81`.
The local keystore IS the CI key — a locally built APK upgrades a CI-signed install.

---

## OPEN — start here

### 1. Retention: the decision has come due, and the code says so

`upload_queue_service.dart:94-96` states its own precondition for resuming deletion:

> *Once the queue is visible — and can show a failed row, its `lastError`, and offer retry
> or delete — releasing the file here becomes defensible again.*

That shipped in v1.2.0. So the v1.1.9 trade (keep the bytes, let storage grow) has lost
its justification. Either retention deletes again after 30 days, or **storage grows
unbounded forever and that becomes permanent by default**. This is the one piece of the
queue arc deliberately left open. It is a product call, not an engineering one.

### 2. Play Console (#13) — one-way door, runbook written

The app signing key **must** be the existing `paperless-go-release.jks`, not one Google
generates. Get it wrong and Play-installed and GitHub-installed copies become permanently
non-upgradable in both directions, for every user, unfixable after the fact. Full steps
and the fingerprint to verify are in a comment on #13, and it is now the first acceptance
criterion on that issue.

### 3. The README's F-Droid badge 404s

"Get it on F-Droid" links to a package that does not exist (verified: both
`com.ventoux.paperlessgo` and `com.ventouxlabs.paperlessgo` return 404 from the F-Droid
API, and neither is in `fdroiddata`). The repo has F-Droid *preparation*
(`pubspec.lock.fdroid`, per-ABI changelogs at `metadata/en-US/changelogs/`), but nothing
is published. Left alone as a product call.

### 4. Smaller

- **The AAB is not signature-checked** in CI. `apksigner` verifies APKs; bundles are
  jarsigner-signed and need a different check.
- **#31's copy fix was never seen on hardware** — both phones were unplugged before the
  rebuild. Covered by a widget test that fails without the fix, which is not the same
  thing.
- **`.omc/skills/` is gitignored**, so the learned skills written this session
  (`queue-drain-test-falsifiability-expertise`, and the corrected
  `queue-drain-cleanup-ordering`) exist only on this machine.

---

## Process notes worth keeping

**Outside review earned its keep three times.** Two independent agents on the retention
work found zero overlapping issues, and the one that changed the design (the
`DateTime.now()` clock analysis) came from the adversarial pass. `/codex review` then
found a P1 on #29 that neither self-review nor those agents caught: Retry was a guaranteed
no-op on exactly the rows the queue screen exists to rescue.

**Vacuous tests were the recurring failure, not wrong code.** Several fault-boundary tests
passed with the boundary removed. Causes: undefined row order (no `ORDER BY`), a fake that
failed only on its first *call* while the service drains on `build()` as well as on
demand, and failing the last row (or the only row), where a broken loop strands nothing.
Written up in `.omc/skills/queue-drain-test-falsifiability-expertise.md`.

**Three times a confident diagnosis was wrong, and each was caught by reading the actual
output instead of the summary:**

- Dates rendering as year 58603 — my seed data was in milliseconds, not an app bug.
- An emulator upgrade chain "proving" the signing key changed between 1.1.8 and 1.1.9 —
  the full error was `INSUFFICIENT_STORAGE`.
- The F-Droid re-signing theory for the Pixel 10 — the app is not on F-Droid at all.

**The CI signature check failed on its first real run, for its own reason.** It matched
the label `Signer #1 certificate SHA-256 digest`; the runner has build-tools **37.0.0**,
which prints `V2 Signer: certificate SHA-256 digest`. My local 36.0.0 prints the old form,
so a local pre-flight passed while CI failed. It now prints apksigner's raw output and
matches the 64-hex digest rather than a label. **A check that only runs where you wrote it
has not been tested.**
