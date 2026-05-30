#!/usr/bin/env bash

set -e

shopt -s extglob

if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: $0 version destdir [--no-package] [--dev-build] [--64-only|--32-only] [--d3d9-only]"
  exit 1
fi

DXVK_VERSION="$1"
DXVK_SRC_DIR=$(readlink -f "$0")
DXVK_SRC_DIR=$(dirname "$DXVK_SRC_DIR")
DXVK_BUILD_DIR=$(realpath "$2")"/dxvk-$DXVK_VERSION"
DXVK_ARCHIVE_PATH=$(realpath "$2")"/dxvk-$DXVK_VERSION.tar.gz"

shift 2

opt_nopackage=0
opt_devbuild=0
opt_buildid=false
opt_64_only=0
opt_32_only=0
opt_d3d9_only=0

crossfile="build-win"

while [ $# -gt 0 ]; do
  case "$1" in
  "--no-package")
    opt_nopackage=1
    ;;
  "--dev-build")
    opt_nopackage=1
    opt_devbuild=1
    ;;
  "--build-id")
    opt_buildid=true
    ;;
  "--64-only")
    opt_64_only=1
    ;;
  "--32-only")
    opt_32_only=1
    ;;
  "--d3d9-only")
    opt_d3d9_only=1
    opt_nopackage=1
    ;;
  *)
    echo "Unrecognized option: $1" >&2
    exit 1
  esac
  shift
done

function build_arch {
  export WINEARCH="win$1"
  export WINEPREFIX="$DXVK_BUILD_DIR/wine.$1"

  cd "$DXVK_SRC_DIR"

  opt_strip=
  if [ $opt_devbuild -eq 0 ] && [ $opt_d3d9_only -eq 0 ]; then
    opt_strip=--strip
  fi

  # Skip meson setup if the build dir is already configured. Lets
  # successive runs incrementally rebuild instead of paying the
  # full configure cost.
  if [ ! -e "$DXVK_BUILD_DIR/build.$1/build.ninja" ]; then
    meson setup --cross-file "$DXVK_SRC_DIR/$crossfile$1.txt" \
          --buildtype "release"                               \
          --prefix "$DXVK_BUILD_DIR"                          \
          $opt_strip                                          \
          --bindir "x$1"                                      \
          --libdir "x$1"                                      \
          -Db_ndebug=if-release                               \
          -Dbuild_id=$opt_buildid                             \
          "$DXVK_BUILD_DIR/build.$1"
  fi

  cd "$DXVK_BUILD_DIR/build.$1"

  if [ $opt_d3d9_only -eq 1 ]; then
    ninja src/d3d9/d3d9.dll
    mkdir -p "$DXVK_BUILD_DIR/x$1"
    cp "src/d3d9/d3d9.dll" "$DXVK_BUILD_DIR/x$1/d3d9.dll"
    # ninja install would have stripped via meson's --strip option,
    # but the d3d9-only path skips install. Strip explicitly so the
    # artifact matches a full release build (~7.5MB vs ~20MB).
    if [ $opt_devbuild -eq 0 ]; then
      case "$1" in
        32) strip_tool=i686-w64-mingw32-strip ;;
        64) strip_tool=x86_64-w64-mingw32-strip ;;
      esac
      "$strip_tool" "$DXVK_BUILD_DIR/x$1/d3d9.dll"
    fi
    return
  fi

  ninja install

  if [ $opt_devbuild -eq 0 ]; then
    # get rid of some useless .a files
    rm "$DXVK_BUILD_DIR/x$1/"*.!(dll)
    rm -R "$DXVK_BUILD_DIR/build.$1"
  fi
}

function package {
  cd "$DXVK_BUILD_DIR/.."
  tar -czf "$DXVK_ARCHIVE_PATH" "dxvk-$DXVK_VERSION"
  rm -R "dxvk-$DXVK_VERSION"
}

if [ $opt_32_only -eq 0 ]; then
  build_arch 64
fi
if [ $opt_64_only -eq 0 ]; then
  build_arch 32
fi

if [ $opt_nopackage -eq 0 ]; then
  package
fi
