#!/bin/sh
set -e

# macOS/iCloud adds com.apple.provenance under ~/Documents. In-place lipo writes
# during debug_unpack_ios then fail codesign with "resource fork, Finder
# information, or similar detritus not allowed". Keeping build/ios outside
# Documents avoids that.
export COPYFILE_DISABLE=1

APP_DIR="${FLUTTER_APPLICATION_PATH:-$(cd "$(dirname "$0")/.." && pwd)}"
BUILD_IOS="${APP_DIR}/build/ios"
SAFE_BUILD="${FAIRPLAYLAB_IOS_BUILD_DIR:-/tmp/FairPlayLab_ios_build}"

ensure_ios_build_symlink() {
  if [ -L "$BUILD_IOS" ]; then
    return 0
  fi

  mkdir -p "$(dirname "$SAFE_BUILD")"
  if [ -d "$BUILD_IOS" ]; then
    rm -rf "$SAFE_BUILD"
    mv "$BUILD_IOS" "$SAFE_BUILD"
  else
    mkdir -p "$SAFE_BUILD"
  fi
  mkdir -p "${APP_DIR}/build"
  ln -s "$SAFE_BUILD" "$BUILD_IOS"
}

ensure_ios_build_symlink

if [ -n "${FLUTTER_ROOT:-}" ] && [ -d "${FLUTTER_ROOT}/bin/cache/artifacts/engine" ]; then
  xattr -cr "${FLUTTER_ROOT}/bin/cache/artifacts/engine" 2>/dev/null || true
fi

/bin/sh "${FLUTTER_ROOT}/packages/flutter_tools/bin/xcode_backend.sh" build
