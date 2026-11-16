#!/bin/bash
# Xenoblade Chronicles 2 (Switch) on Android: builds the app and its data from YOUR OWN game files and installs them.
#   ./setup.sh            everything: tools, the port, the install on the connected device
#   ./setup.sh check      what is found and what is missing (changes nothing)
#   ./setup.sh build      everything but the install (the APK and the data folder stay in work/)
#   ./setup.sh install    install what an earlier run built
# It reads the game files and prod.keys from put-game-files-here/ and a Vulkan driver (.so) from drivers/.
# Everything it makes goes into work/ (about 30 GB while it runs). Nothing is uploaded.
# The engine is nx2android (https://github.com/shirai91/nx2android), fetched at the exact commit this port was tested with.
# SETUP_YES=1 answers yes to the download questions. NX2A_DIR=<checkout> uses an nx2android checkout you already have.
set -eu
[ -n "${BASH_VERSION:-}" ] || exec bash "$0" "$@"
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
NX_URL=https://github.com/G0zsilva/nx2android.git
NX_COMMIT=419b4bf4ffd999089261ce609abf4c98c3a75649   # branch feat/xenoblade-chronicles-2 (pull request 403 of shirai91/nx2android)
TITLE=0100E95004038000
APP=XenobladeChronicles2
PACKAGE=org.nx2a.t0100e95004038000
WORK="$HERE/work"
NX="${NX2A_DIR:-$WORK/nx2android}"
GAME="$NX/.gamedump/$APP"
VENV="$WORK/venv"
MODE="${1:-all}"

say() { printf '\n== %s\n' "$*"; }
die() { printf '\nsetup: %s\n' "$*" >&2; exit 1; }
ask() { [ "${SETUP_YES:-}" = 1 ] && return 0; printf '%s [y/N] ' "$1"; read -r a; case "$a" in y|Y|yes) return 0;; esac; return 1; }

find_python() {
  for p in python3.14 python3.13 python3.12 python3.11 python3 python; do
    if command -v "$p" > /dev/null 2>&1 && "$p" -c 'import sys; sys.exit(sys.version_info < (3, 11))' 2> /dev/null; then echo "$p"; return; fi
  done
}
game_files() { find "$HERE/put-game-files-here" -maxdepth 1 -type f \( -iname '*.nsp' -o -iname '*.nsz' -o -iname '*.xci' -o -iname '*.xcz' \) | sort; }
keys_file() { find "$HERE/put-game-files-here" -maxdepth 1 -type f -iname 'prod.keys' | head -1; }
driver_file() { find "$HERE/drivers" -maxdepth 1 -type f -name '*.so' | sort | head -1; }
porter() { ( cd "$NX" && "$VENV/bin/python" -m porter "$@" ); }
find_adb() {
  if command -v adb > /dev/null 2>&1; then command -v adb; return; fi
  for d in "$HOME/Library/Application Support/nx2android" "${XDG_DATA_HOME:-$HOME/.local/share}/nx2android" "$NX/tools"; do
    for a in "$d/toolchains/platform-tools/adb" "$d/platform-tools/adb"; do [ -x "$a" ] && { echo "$a"; return; }; done
  done
}

check() {
  local py n k d g nxs apk
  py=$(find_python); n=$(game_files | wc -l | tr -d ' '); k=$(keys_file); d=$(driver_file)
  g=$(command -v git || true)
  nxs="not fetched yet"; [ -d "$NX/porter" ] && nxs="$NX"
  apk="not built yet"; [ -f "$GAME/$APP.apk" ] && apk="$GAME/$APP.apk"
  echo "Python 3.11+        : ${py:-MISSING, install Python 3.11 or newer}"
  echo "git                 : ${g:-MISSING}"
  echo "game files          : $n found in put-game-files-here/, the base game and update 2.1.0 are needed, DLC is optional"
  echo "prod.keys           : ${k:-MISSING, put it in put-game-files-here/}"
  echo "Vulkan driver       : ${d:-none in drivers/, the stock driver of the device will be used, not tested with the final fixes}"
  echo "engine checkout     : $nxs"
  echo "built app           : $apk"
}

prepare_engine() {
  local py; py=$(find_python); [ -n "$py" ] || die "Python 3.11 or newer is needed"
  command -v git > /dev/null 2>&1 || die "git is needed"
  mkdir -p "$WORK"
  if [ ! -d "$NX/porter" ]; then
    [ -z "${NX2A_DIR:-}" ] || die "NX2A_DIR=$NX2A_DIR is not an nx2android checkout"
    say "fetching the engine (nx2android at ${NX_COMMIT:0:7}, about 320 MB)"
    mkdir -p "$NX"; git -C "$NX" init -q
    git -C "$NX" fetch -q --depth 1 "$NX_URL" "$NX_COMMIT" && git -C "$NX" checkout -q FETCH_HEAD
  elif [ -z "${NX2A_DIR:-}" ] && [ "$(git -C "$NX" rev-parse HEAD)" != "$NX_COMMIT" ]; then
    say "updating the engine to ${NX_COMMIT:0:7}"
    git -C "$NX" fetch -q --depth 1 "$NX_URL" "$NX_COMMIT" && git -C "$NX" checkout -q FETCH_HEAD
  fi
  if [ ! -x "$VENV/bin/python" ]; then say "making a private Python environment (work/venv)"; "$py" -m venv "$VENV"; fi
  "$VENV/bin/python" -c 'import lz4, capstone, PIL, fontTools, yaml, Crypto' 2> /dev/null || {
    say "installing the Python packages into work/venv"
    "$VENV/bin/python" -m pip install -q --upgrade pip
    "$VENV/bin/python" -m pip install -q lz4 capstone pillow fonttools pyyaml pycryptodome 'backports.zstd; python_version < "3.14"'
  }
  if porter doctor 2>&1 | grep -E '^!!' | grep -q -E 'Android NDK|\.NET SDK|adb'; then
    say "nx2android needs the Android NDK, the .NET SDK and adb (about 2 GB, from Google and Microsoft, into its own folder)"
    ask "Download the missing ones now? You accept their licenses." || die "the tools are needed: run './setup.sh' again, or install them and see 'python -m porter doctor'"
    porter tools --download
  fi
}

link_game() {
  local k n=0; k=$(keys_file); [ -n "$k" ] || die "put your prod.keys into put-game-files-here/"
  [ "$(game_files | wc -l | tr -d ' ')" -ge 2 ] || die "put the base game and the update (NSP, NSZ, XCI or XCZ) into put-game-files-here/"
  mkdir -p "$GAME"
  while IFS= read -r f; do
    [ -e "$GAME/$(basename "$f")" ] || ln "$f" "$GAME/" 2> /dev/null || ln -s "$f" "$GAME/"   # a hard link (no copy); a symbolic link across drives
    n=$((n + 1))
  done < <(game_files)
  echo "$n game files linked into the work folder (not copied)"
}

pull_captured() {   # shaders the app saved on the device while the game ran (code no game file holds), if any: the next build includes them
  local adb dst="$GAME/${TITLE}_build/android/captured_shaders"; adb=$(find_adb); [ -n "$adb" ] || return 0
  "$adb" shell "ls /sdcard/Android/data/$PACKAGE/files/captured_shaders/*.bin" > /dev/null 2>&1 || return 0
  mkdir -p "$dst"; "$adb" pull "/sdcard/Android/data/$PACKAGE/files/captured_shaders/." "$dst/" > /dev/null 2>&1 && echo "shaders captured by an earlier run on the device: taken into this build"
}

build() {
  local d k; d=$(driver_file); k=$(keys_file)
  pull_captured || true
  say "porting (the first run extracts about 14 GB and translates 12,750 shaders: several minutes)"
  if [ -n "$d" ]; then porter port "$GAME" -k "$k" --vulkan-driver "$d" --progress lines
  else echo "no driver in drivers/: building for the device's own Vulkan driver (not tested)"; porter port "$GAME" -k "$k" --progress lines; fi
}

install() {
  [ -d "$GAME/$APP-data" ] || die "nothing built yet: run './setup.sh' first"
  say "installing on the connected device (USB debugging on; about 14 GB the first time)"
  porter install "$GAME/$APP-data" --progress lines
  cat << 'TXT'

Done. Open "Xenoblade Chronicles 2" on the device.
In the pause menu (the button at the top of the screen), Game tab: Frame rate (30 / 60), Resolution (Low / Auto / High),
Mode. On the Gamepad tab, "Face buttons" switches A/B/X/Y between their position and their letter.
TXT
}

case "$MODE" in
  check) check;;
  build) prepare_engine; link_game; build;;
  install) prepare_engine; install;;
  all) prepare_engine; link_game; build; install;;
  *) sed -n '2,10p' "$0"; exit 2;;
esac
