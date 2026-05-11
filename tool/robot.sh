#!/usr/bin/env bash
# Robot runner: Firebase emulators + adb reverse + integration tests.
#
# Prereqs:
#   • Java 11+ (`java -version`)
#   • Firebase CLI (`firebase --version`)
#   • Android device connected and authorised (`adb devices` shows one)
#   • Flutter SDK on PATH (or set FLUTTER below)
#
# Usage:
#   bash tool/robot.sh
#
# What it does:
#   1. Starts the Firebase auth + firestore + functions emulators in the bg.
#   2. Sets up adb reverse so the device can reach emulators on localhost.
#   3. Runs `flutter test integration_test/app_robot_test.dart` with the dev
#      flavor on the first attached device.
#   4. Tears down emulators on exit.
set -euo pipefail

FLUTTER="${FLUTTER:-$HOME/development/flutter/bin/flutter}"
ADB="${ADB:-$HOME/Android/sdk/platform-tools/adb}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
cd "$ROOT"

LOG_DIR="$ROOT/build/robot-logs"
mkdir -p "$LOG_DIR"
EMU_LOG="$LOG_DIR/emulators.log"

echo "▶ Robot runner starting ($(date -Iseconds))"

# Ensure a device is connected before doing anything else.
# Use $NF (last field) for the state because some serials contain spaces, e.g.
# `adb-XXXX (2)._adb-tls-connect._tcp`. Re-join all fields except the last.
DEVICES="$("$ADB" devices | awk 'NR>1 && $NF=="device" {NF--; sub(/[ \t]+$/,""); print}')"
if [[ -z "$DEVICES" ]]; then
  echo "✖ No Android device attached. Plug one and re-run." >&2
  exit 1
fi
# Prefer the requested device id; fall back to first usable device.
# Skip the broken `(2)._adb-tls-connect._tcp` mDNS entry that Flutter chokes
# on (Android null/API null). Prefer plain IP:port wireless devices.
DEVICE_ID="${DEVICE_ID:-}"
if [[ -z "$DEVICE_ID" ]]; then
  DEVICE_ID="$(echo "$DEVICES" | grep -E '^[0-9.]+:[0-9]+$' | head -n1)"
fi
if [[ -z "$DEVICE_ID" ]]; then
  DEVICE_ID="$(echo "$DEVICES" | grep -v '_adb-tls-connect._tcp' | head -n1)"
fi
if [[ -z "$DEVICE_ID" ]]; then
  DEVICE_ID="$(echo "$DEVICES" | head -n1)"
fi
echo "  • Device: $DEVICE_ID"

# Stop any previous emulator instance.
pkill -f "firebase.*emulators:start" 2>/dev/null || true
sleep 1

echo "  • Starting Firebase emulators (logs: $EMU_LOG)"
firebase emulators:start \
  --only auth,firestore,functions \
  --project shape-merge \
  >"$EMU_LOG" 2>&1 &
EMU_PID=$!

cleanup() {
  echo "▶ Cleaning up..."
  kill "$EMU_PID" 2>/dev/null || true
  pkill -f "firebase.*emulators:start" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

# Wait until emulators are listening.
echo -n "  • Waiting for emulators"
for i in {1..60}; do
  if nc -z localhost 9099 2>/dev/null && nc -z localhost 8080 2>/dev/null; then
    echo " ✓"
    break
  fi
  echo -n "."
  sleep 1
  if [[ $i -eq 60 ]]; then
    echo
    echo "✖ Emulators did not start in 60s. See $EMU_LOG" >&2
    exit 1
  fi
done

# adb reverse so the physical device hits localhost = the host machine.
# Still useful for the Android emulator path (10.0.2.2 → host loopback).
echo "  • Setting up adb reverse on $DEVICE_ID"
"$ADB" -s "$DEVICE_ID" reverse tcp:9099 tcp:9099 >/dev/null
"$ADB" -s "$DEVICE_ID" reverse tcp:8080 tcp:8080 >/dev/null
"$ADB" -s "$DEVICE_ID" reverse tcp:5001 tcp:5001 >/dev/null

# Pick the emulator host the app must connect to.
#   • Wireless / physical device (IP:port serial) → use the host's LAN IP,
#     because firebase_auth Android remaps localhost & 127.0.0.1 to 10.0.2.2.
#   • Android emulator → 10.0.2.2 (the default in test_entry.dart).
EMULATOR_HOST="${EMULATOR_HOST:-}"
if [[ -z "$EMULATOR_HOST" ]]; then
  if [[ "$DEVICE_ID" =~ ^[0-9.]+:[0-9]+$ ]]; then
    EMULATOR_HOST="$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || true)"
    if [[ -z "$EMULATOR_HOST" ]]; then
      echo "✖ Could not detect host LAN IP (en0/en1). Set EMULATOR_HOST explicitly." >&2
      exit 1
    fi
  else
    EMULATOR_HOST="10.0.2.2"
  fi
fi
echo "  • Emulator host for app: $EMULATOR_HOST"

echo "▶ Running integration test on $DEVICE_ID"
# Single end-to-end suite — installs the APK once, replays every scenario,
# fails fast at the first broken assertion.
export PUB_CACHE_DISABLE_BUFFERING=1
if "$FLUTTER" test integration_test/app_robot_test.dart \
    --flavor dev \
    -d "$DEVICE_ID" \
    --reporter expanded \
    --dart-define=ROBOT=1 \
    --dart-define=EMULATOR_HOST="$EMULATOR_HOST" \
    2>&1 | tee "$LOG_DIR/test-run.log"; then
  echo "✓ Robot suite passed."
else
  echo "✖ Robot suite failed. See $LOG_DIR/test-run.log"
  exit 1
fi

echo "▶ Done. Logs at $LOG_DIR"
