#!/usr/bin/env bash
# run_profiling.sh
# Runs xcodebuild tests with timing metrics for the performance phase of iOS 360° testing.
# Reports build time, test execution time, and reminds the tester to open Instruments for
# memory and frame rate profiling.
#
# Usage: bash run_profiling.sh <scheme> [simulator-name] [output-dir]
#   scheme:         Xcode scheme to build and test (required)
#   simulator-name: name of the simulator to target (default: "iPhone 16 Pro")
#   output-dir:     directory for result bundle (default: ./test-results)
#
# Examples:
#   bash run_profiling.sh MyApp
#   bash run_profiling.sh MyApp "iPhone SE (3rd generation)"
#   bash run_profiling.sh MyApp "iPhone 16 Pro" ./ci-results

set -euo pipefail

SCHEME="${1:-}"
SIMULATOR_NAME="${2:-iPhone 16 Pro}"
OUTPUT_DIR="${3:-./test-results}"
RESULT_BUNDLE="$OUTPUT_DIR/TestResults.xcresult"

if [[ -z "$SCHEME" ]]; then
  echo "Usage: bash run_profiling.sh <scheme> [simulator-name] [output-dir]"
  echo ""
  echo "Available schemes:"
  xcodebuild -list 2>/dev/null | grep -A 100 "Schemes:" | tail -n +2 | sed 's/^[[:space:]]*/  /'
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

echo "================================================"
echo " iOS 360° Performance Profiling"
echo " Scheme:    $SCHEME"
echo " Simulator: $SIMULATOR_NAME"
echo " Results:   $RESULT_BUNDLE"
echo "================================================"
echo ""

# --- 1. Build & Test (measures test suite execution time) ---
echo "[1/3] Building and running tests..."
START_BUILD=$(date +%s)

xcodebuild test \
  -scheme "$SCHEME" \
  -destination "platform=iOS Simulator,name=$SIMULATOR_NAME" \
  -resultBundlePath "$RESULT_BUNDLE" \
  -quiet \
  2>&1 | tail -20

END_BUILD=$(date +%s)
BUILD_DURATION=$((END_BUILD - START_BUILD))

echo ""
echo "Test run completed in ${BUILD_DURATION}s"
echo "Result bundle: $RESULT_BUNDLE"
echo ""

# --- 2. Launch time measurement (cold launch via simctl) ---
echo "[2/3] Measuring cold launch time..."

# Derive bundle ID from the result bundle (best effort)
BUNDLE_ID=$(xcodebuild -scheme "$SCHEME" -showBuildSettings 2>/dev/null \
  | grep "PRODUCT_BUNDLE_IDENTIFIER" | head -1 | awk '{print $3}')

if [[ -n "$BUNDLE_ID" ]]; then
  echo "Bundle ID: $BUNDLE_ID"

  # Terminate any running instance
  xcrun simctl terminate booted "$BUNDLE_ID" 2>/dev/null || true

  # Launch and measure time to first log output (proxy for launch time)
  LAUNCH_START=$(date +%s%3N)
  xcrun simctl launch --console booted "$BUNDLE_ID" 2>&1 | head -5 &
  LAUNCH_PID=$!
  sleep 3
  kill $LAUNCH_PID 2>/dev/null || true
  LAUNCH_END=$(date +%s%3N)
  LAUNCH_MS=$((LAUNCH_END - LAUNCH_START))

  echo "Approximate cold launch time: ~${LAUNCH_MS}ms"
  echo "(For accurate pre-main / post-main breakdown, use Instruments → App Launch template)"
else
  echo "Could not determine bundle ID automatically. Skipping launch time measurement."
  echo "Run manually: xcrun simctl launch booted <bundle-id>"
fi

echo ""

# --- 3. Instruments reminders ---
echo "[3/3] Manual Instruments profiling checklist:"
echo ""
echo "  Memory:"
echo "    Xcode → Product → Profile (Cmd+I)"
echo "    Template: Leaks"
echo "    Exercise all major flows, check for leaks and abandoned allocations"
echo ""
echo "  Frame Rate:"
echo "    Template: Core Animation"
echo "    Scroll all lists/scroll views → target 60fps (no red frames)"
echo ""
echo "  CPU:"
echo "    Template: Time Profiler"
echo "    Identify hot functions during heavy interactions"
echo ""
echo "  Network:"
echo "    Template: Network"
echo "    Confirm HTTPS only, check for redundant calls and large payloads"
echo ""
echo "  App Launch (precise):"
echo "    Template: App Launch"
echo "    Target: <400ms cold launch to first frame"
echo ""
echo "================================================"
echo " Performance Phase Complete"
echo " Record your metrics in the test report:"
echo "   Cold Launch: ___ms"
echo "   Peak Memory: ___MB"
echo "   Leaks Found: Yes / No"
echo "   Scroll FPS (worst): ___ fps"
echo "================================================"
