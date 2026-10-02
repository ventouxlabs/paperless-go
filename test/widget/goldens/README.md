# Golden tests

`matchesGoldenFile` does exact pixel comparison, which is sensitive to the
exact Flutter engine build (font rasterization/anti-aliasing differs by
engine version even with identical fonts loaded). These baselines are
generated against **Flutter 3.41.3** — the version `.github/workflows/ci.yml`
pins — not whatever Flutter is installed locally.

`flutter_test_config.dart` in this directory makes that workable locally:

- **Off CI** (`CI` unset), a golden passes if at most **1%** of its pixels
  differ. Drift between Flutter versions peaks at 0.68% (3.47 vs 3.41.3), so a
  local run is green.
- **On CI** (`CI=true`, which GitHub Actions sets), comparison stays exact.

So a local pass is approximate: a small real change, such as a chip's text
colour, can stay under 1% and only fail on CI. CI is the gate. To see the
exact result locally, run `CI=true flutter test test/widget/goldens/`; it will
show the version-drift failures too unless you're on 3.41.3.

To regenerate correctly:

```bash
# From the flutter/flutter repo, in a worktree so it doesn't disturb your
# regular install:
git worktree add /tmp/flutter-3413 3.41.3

# Copy this repo to scratch so an older Flutter's `pub get` never touches
# the real pubspec.lock:
rsync -a --exclude='.git' --exclude='build' --exclude='.dart_tool' ./ /tmp/scratch/

cd /tmp/scratch
export PUB_CACHE=/tmp/scratch/.pub-cache
/tmp/flutter-3413/bin/flutter pub get
/tmp/flutter-3413/bin/flutter test test/widget/goldens/ --update-goldens

# Copy the results back:
cp test/widget/goldens/goldens/*.png <real-repo>/test/widget/goldens/goldens/
```
