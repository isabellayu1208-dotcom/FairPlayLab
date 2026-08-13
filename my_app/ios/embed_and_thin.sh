#!/bin/sh
set -e

# macOS adds com.apple.provenance to files in ~/Documents, which breaks codesign.
export COPYFILE_DISABLE=1

if [ -n "${FLUTTER_ROOT:-}" ] && [ -d "${FLUTTER_ROOT}/bin/cache" ]; then
  xattr -cr "${FLUTTER_ROOT}/bin/cache/artifacts/engine" 2>/dev/null || true
fi

if [ -n "${FLUTTER_APPLICATION_PATH:-}" ]; then
  xattr -cr "${FLUTTER_APPLICATION_PATH}" 2>/dev/null || true
fi

/bin/sh "${FLUTTER_ROOT}/packages/flutter_tools/bin/xcode_backend.sh" embed_and_thin || {
  if [ -n "${FLUTTER_APPLICATION_PATH:-}" ]; then
    xattr -cr "${FLUTTER_APPLICATION_PATH}/build/ios" 2>/dev/null || true
  fi
  /bin/sh "${FLUTTER_ROOT}/packages/flutter_tools/bin/xcode_backend.sh" embed_and_thin
}
