# Catalog goldens

One PNG per `/dev/catalog` state (`lib/features/dev_catalog/catalog_entries.dart`), 375×667 @1x,
drawn with the bundled fonts. **They are Linux pixels**: CI (ubuntu, Flutter 3.47.8) compares
them; macOS anti-aliases glyphs differently, so there the tests render every state but skip the
pixel diff (`../flutter_test_config.dart`).

Redraw after a visual change, from the repo root, in an x64 Linux container on CI's Flutter
(uses a clean export of `HEAD`, so commit first; your checkout's `.dart_tool` is untouched):

```bash
mkdir -p /tmp/goldens && git archive HEAD | tar -x -C /tmp/goldens
docker run --rm --platform linux/amd64 -v /tmp/goldens:/work -w /work ubuntu:24.04 bash -c '
  apt-get update -qq && apt-get install -y -qq curl git xz-utils unzip ca-certificates \
    clang cmake ninja-build pkg-config build-essential libasound2-dev >/dev/null &&
  curl -sSfL https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.47.8-stable.tar.xz | tar -xJ -C /opt &&
  git config --global --add safe.directory "*" && export PATH=/opt/flutter/bin:$PATH &&
  flutter pub get && cd apps/mobile &&
  flutter test --update-goldens test/features/dev_catalog/catalog_golden_test.dart'
cp /tmp/goldens/apps/mobile/test/features/dev_catalog/goldens/*.png apps/mobile/test/features/dev_catalog/goldens/
```

The C toolchain and ALSA headers are for the audio engine's native build (the sound PR); CI's
runner has them already. Then look at every changed image before committing.
