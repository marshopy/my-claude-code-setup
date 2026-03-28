#!/usr/bin/env bash
# capture_screenshots.sh
# Captures a screenshot from the booted iOS Simulator and saves it with a timestamp.
# Usage: bash capture_screenshots.sh [simulator-udid] [label]
#   simulator-udid: optional, defaults to the first booted simulator
#   label:          optional screen label appended to the filename (e.g., "home", "profile")
#
# Output: ./test-screenshots/YYYY-MM-DD_HH-MM-SS_[label].png
#
# Examples:
#   bash capture_screenshots.sh                         # captures booted simulator
#   bash capture_screenshots.sh "" home                 # labels screenshot "home"
#   bash capture_screenshots.sh <udid> settings         # targets specific simulator

set -euo pipefail

UDID="${1:-}"
LABEL="${2:-screen}"
OUTPUT_DIR="./test-screenshots"
TIMESTAMP=$(date "+%Y-%m-%d_%H-%M-%S")
FILENAME="${TIMESTAMP}_${LABEL}.png"

mkdir -p "$OUTPUT_DIR"

if [[ -z "$UDID" ]]; then
  # Find the first booted simulator
  UDID=$(xcrun simctl list devices | awk '/\(Booted\)/{match($0, /\(([A-F0-9-]+)\)/, arr); if (arr[1] != "" && arr[1] != "Booted") {print arr[1]; exit}}')
  if [[ -z "$UDID" ]]; then
    echo "Error: No booted simulator found. Boot a simulator first with:"
    echo "  xcrun simctl boot \"iPhone 16 Pro\" && open -a Simulator"
    exit 1
  fi
  echo "Using booted simulator: $UDID"
fi

OUTPUT_PATH="$OUTPUT_DIR/$FILENAME"
xcrun simctl io "$UDID" screenshot "$OUTPUT_PATH"
echo "Screenshot saved: $OUTPUT_PATH"
