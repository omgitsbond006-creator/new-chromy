#!/bin/bash
# Installs Flutter and the Android SDK so cloud sessions can analyze, test
# and build Orbiquo. Safe to run repeatedly: every step is skipped if done.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

FLUTTER_VERSION="3.47.6"
FLUTTER_HOME="/opt/flutter"
ANDROID_HOME="/opt/android-sdk"
ANDROID_PACKAGES=("platform-tools" "platforms;android-36" "build-tools;36.0.0")

# --- Flutter ---------------------------------------------------------------
if [ ! -x "$FLUTTER_HOME/bin/flutter" ]; then
  echo "Installing Flutter $FLUTTER_VERSION..."
  tmp="$(mktemp -d)"
  curl -fsSL -o "$tmp/flutter.tar.xz" \
    "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
  tar -xf "$tmp/flutter.tar.xz" -C /opt
  rm -rf "$tmp"
fi
git config --global --add safe.directory "$FLUTTER_HOME" 2>/dev/null || true
export PATH="$FLUTTER_HOME/bin:$PATH"
flutter --disable-analytics >/dev/null 2>&1 || true

# --- Android SDK -----------------------------------------------------------
SDKMANAGER="$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager"
if [ ! -x "$SDKMANAGER" ]; then
  echo "Installing Android command-line tools..."
  mkdir -p "$ANDROID_HOME/cmdline-tools"
  zip_name="$(curl -fsSL https://dl.google.com/android/repository/repository2-3.xml \
    | grep -o 'commandlinetools-linux-[0-9]*_latest.zip' | head -1)"
  tmp="$(mktemp -d)"
  curl -fsSL -o "$tmp/tools.zip" "https://dl.google.com/android/repository/$zip_name"
  unzip -q "$tmp/tools.zip" -d "$tmp"
  rm -rf "$ANDROID_HOME/cmdline-tools/latest"
  mv "$tmp/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest"
  rm -rf "$tmp"
fi

missing=()
for pkg in "${ANDROID_PACKAGES[@]}"; do
  [ -d "$ANDROID_HOME/${pkg//;//}" ] || missing+=("$pkg")
done
if [ ${#missing[@]} -gt 0 ]; then
  echo "Installing Android packages: ${missing[*]}"
  yes | "$SDKMANAGER" --licenses >/dev/null 2>&1 || true
  "$SDKMANAGER" "${missing[@]}" >/dev/null
fi

flutter config --android-sdk "$ANDROID_HOME" >/dev/null
yes | flutter doctor --android-licenses >/dev/null 2>&1 || true

# --- Session environment -----------------------------------------------------
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  {
    echo "export ANDROID_HOME=\"$ANDROID_HOME\""
    echo "export ANDROID_SDK_ROOT=\"$ANDROID_HOME\""
    echo "export PATH=\"$FLUTTER_HOME/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:\$PATH\""
  } >> "$CLAUDE_ENV_FILE"
fi

# --- Project dependencies ----------------------------------------------------
cd "${CLAUDE_PROJECT_DIR:-$(pwd)}"
flutter pub get
