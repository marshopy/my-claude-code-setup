---
name: ios-360-testing
description: This skill should be used when performing comprehensive 360-degree testing of an iOS application. It applies when testing iPhone/iPad apps using Xcode and iOS Simulator, covering a strict 5-phase sequence: design consistency → functional correctness → performance profiling → security review → iOS system component interactions. Use for pre-release quality gates, regression sweeps, or deep QA sessions on any iOS app project.
---

# iOS 360° Testing

Comprehensive mobile QA methodology for iOS applications executed in Xcode with its associated simulators. Testing always follows the exact 5-phase sequence below — never skip or reorder phases.

## Phase Sequence

```
1. Design Check  →  2. Functional Correctness  →  3. Performance  →  4. Security Review  →  5. iOS System Components
```

---

## Prerequisites

Before starting any phase:

1. Open the project in Xcode and confirm it builds without errors (`Cmd+B`)
2. Select the target simulator (iPhone 16 Pro recommended for latest APIs; also test iPhone SE for small screen)
3. Run the app on the simulator (`Cmd+R`) and confirm it launches to the home/root screen
4. Open the Console app or Xcode's Debug Console to monitor logs during testing
5. Capture a baseline screenshot set using the provided script:

```bash
bash scripts/capture_screenshots.sh <simulator-udid>
```

Get the booted simulator UDID with:
```bash
xcrun simctl list devices | grep Booted
```

---

## Phase 1: Design Check

**Goal:** Verify visual consistency, Apple Human Interface Guidelines (HIG) compliance, and a unified design language across all screens.

Load `references/design-checklist.md` for the full checklist. Key steps:

1. Navigate to every screen in the app (use the navigation map from Phase 2 once known)
2. Capture screenshots of each screen (`scripts/capture_screenshots.sh`)
3. Compare screens side-by-side for consistency in:
   - Navigation bar style (title, back button, color)
   - Tab bar icons, labels, and active states
   - Typography (font, size, weight hierarchy)
   - Color palette (primary, secondary, destructive, background)
   - Button styles (filled, outlined, text-only) — consistent across equivalent actions
   - Spacing and alignment (8pt grid adherence, safe area insets respected)
4. Toggle Dark Mode (`Cmd+Shift+A` in Simulator) and verify all screens adapt correctly
5. Open Accessibility Inspector (`Xcode → Open Developer Tool → Accessibility Inspector`) and run the audit on each screen

Report format for Phase 1:
```
Screen: [Screen Name]
  ✅ Pass / ❌ Fail — [check item]
  Finding: [describe issue if any]
  Screenshot: [filename]
```

---

## Phase 2: Functional Correctness

**Goal:** Verify every interactive element functions correctly and all screen transitions are properly wired.

Load `references/functional-checklist.md` for the full checklist. Key steps:

1. **Build a navigation inventory** — list every screen and how to reach it (tab, push, modal, sheet, alert)
2. **Button/control sweep** — for every screen, tap every button, toggle, slider, picker, and link:
   - Confirm it responds (visual feedback, haptic if expected)
   - Confirm the resulting action is correct (navigation, data change, API call)
   - Confirm destructive actions have confirmation dialogs
3. **Navigation wiring** — verify:
   - Back buttons return to the correct prior screen
   - Dismiss/Cancel on modals and sheets works
   - Deep-link entry points land on the correct screen
   - Tab switches preserve navigation state within each tab
4. **Data integrity** — verify:
   - Forms validate input and show inline errors
   - Empty states display meaningful UI (not blank screens)
   - Loading states show indicators and don't block interaction unnecessarily
   - Error states (network failure, server error) show actionable messages
5. **Edge cases** — test:
   - Rotate device (portrait ↔ landscape) if the app supports rotation
   - Interrupt with a phone call simulation: `xcrun simctl spawn booted notifyutil -p com.apple.springboard.simulateIncomingCall`
   - Background and foreground the app; confirm state is preserved

---

## Phase 3: Performance

**Goal:** Profile the app for launch time, memory consumption, CPU usage, and rendering performance.

Use `scripts/run_profiling.sh` to collect baseline metrics:

```bash
bash scripts/run_profiling.sh <scheme-name> <simulator-udid>
```

Manual Instruments workflow:

1. **Launch Time** — `Xcode → Profile (Cmd+I)` → select **App Launch** template → run and review pre-main and post-main times
   - Target: cold launch < 400ms to first frame
2. **Memory** — select **Leaks** template → exercise all major flows → check for:
   - Memory leaks (Leaks instrument)
   - Abandoned memory (Allocations instrument, mark generation before/after flows)
   - Target: no leaks; memory stable after repeated navigation
3. **CPU / Frame Rate** — select **Time Profiler** + **Core Animation** templates:
   - Scroll through all list/scroll views; confirm 60fps (no dropped frames shown in Core Animation FPS graph)
   - Identify hot functions in Time Profiler if CPU spikes
4. **Network** — select **Network** template:
   - Confirm no redundant API calls on screen entry
   - Confirm requests use HTTPS only
   - Check payload sizes; flag anything > 1MB for a single request

Record metrics in the report:
```
Cold Launch Time: Xms
Peak Memory: YMB
Steady-State Memory: ZMB
Leaks Found: Yes/No
Scroll FPS (worst): N fps
Network Issues: [list]
```

---

## Phase 4: Security Review

**Goal:** Identify security vulnerabilities in data storage, network communication, authentication, and sensitive UI.

Load `references/security-checklist.md` for the full checklist. Key steps:

1. **Data at rest** — inspect the app's sandbox:
   ```bash
   xcrun simctl get_app_container booted <bundle-id> data
   ```
   Open the returned path in Finder. Check `Documents/`, `Library/Preferences/`, `Library/Caches/` for plaintext sensitive data (tokens, passwords, PII).

2. **Keychain** — confirm sensitive credentials are stored in Keychain, not UserDefaults or files. Search source for `UserDefaults` usage storing anything security-sensitive.

3. **Network** — verify ATS is not globally disabled (`NSAllowsArbitraryLoads = YES` in Info.plist is a red flag). Use the Network Instruments template to confirm all traffic is HTTPS.

4. **Logging** — search source for `print(` statements that may expose sensitive data. Production builds should use `os_log` with appropriate privacy levels.

5. **Authentication** — verify:
   - Tokens are not stored in plaintext
   - Session expiry is handled (app logs out or refreshes cleanly)
   - Biometric authentication (Face ID/Touch ID) uses `LocalAuthentication` correctly

6. **Sensitive screens** — verify that screens showing sensitive data (payment info, SSN, passwords) prevent screenshots in the app switcher using `.privacySensitive()` or equivalent.

---

## Phase 5: iOS System Component Interactions

**Goal:** Verify correct integration with all iOS system APIs, permissions, hardware, and platform features.

Load `references/ios-permissions.md` for the complete permissions matrix. Key steps:

1. **Permission flows** — for each system permission the app requests:
   - Reset all permissions: `xcrun simctl privacy booted reset all <bundle-id>`
   - Launch app and trigger the feature requiring the permission
   - Confirm the usage description string is present and meaningful (not generic)
   - Confirm permission is requested at the right moment (not on launch)
   - Deny permission → confirm app degrades gracefully with an explanation and a Settings deep-link
   - Grant permission → confirm feature works correctly

2. **Simulator permission simulation** — use simctl to grant/deny specific permissions:
   ```bash
   xcrun simctl privacy booted grant camera <bundle-id>
   xcrun simctl privacy booted revoke camera <bundle-id>
   ```
   Supported services: `camera`, `microphone`, `location`, `contacts`, `photos`, `reminders`, `calendar`, `motion`, `health`, `bluetooth`

3. **Push notifications** — send a test push:
   ```bash
   xcrun simctl push booted <bundle-id> scripts/test-push.json
   ```
   Verify notification appears, tap action navigates correctly, and badge clears.

4. **Background modes** — if the app declares background modes in Info.plist:
   - Background fetch: simulate with `Xcode → Debug → Simulate Background Fetch`
   - Background audio: lock device in Simulator, confirm audio continues
   - Silent push: verify content-available handler fires in background

5. **Universal links / URL schemes** — test deep links:
   ```bash
   xcrun simctl openurl booted "yourapp://path/to/screen"
   xcrun simctl openurl booted "https://yourdomain.com/path"
   ```
   Confirm correct screen opens and state is set properly.

6. **Hardware & platform features** — verify as applicable:
   - Status bar (light/dark) matches the screen background
   - Keyboard behavior (dismiss on scroll, return key action, input types)
   - Dynamic Island / Live Activities (if implemented)
   - Haptic feedback fires at correct moments
   - Home indicator respected (no UI hidden behind it)

---

## Test Report Format

After completing all 5 phases, produce a structured report:

```markdown
# iOS 360° Test Report — [App Name] v[Version]
Date: [YYYY-MM-DD]
Tester: Claude Code
Device/Simulator: [e.g., iPhone 16 Pro, iOS 18.x]

## Phase 1: Design Check
Status: ✅ Pass / ⚠️ Issues Found / ❌ Fail
[Findings list]

## Phase 2: Functional Correctness
Status: ✅ Pass / ⚠️ Issues Found / ❌ Fail
[Findings list — screen name, element, expected behavior, actual behavior]

## Phase 3: Performance
Status: ✅ Pass / ⚠️ Issues Found / ❌ Fail
Cold Launch: Xms | Peak Memory: YMB | Leaks: No | Scroll FPS: 60

## Phase 4: Security Review
Status: ✅ Pass / ⚠️ Issues Found / ❌ Fail
[Findings list]

## Phase 5: iOS System Components
Status: ✅ Pass / ⚠️ Issues Found / ❌ Fail
[Permissions matrix with pass/fail per permission]

## Summary
Total Issues: N (Critical: X, Major: Y, Minor: Z)
Recommended Action: [Ship / Fix & Retest / Block]
```

---

## Quick Xcode & Simulator Commands

```bash
# List available simulators
xcrun simctl list devices available

# Boot a specific simulator
xcrun simctl boot "iPhone 16 Pro"

# Open Simulator app
open -a Simulator

# Install app on booted simulator
xcrun simctl install booted /path/to/App.app

# Launch app
xcrun simctl launch booted com.example.YourApp

# Terminate app
xcrun simctl terminate booted com.example.YourApp

# Reset app permissions
xcrun simctl privacy booted reset all com.example.YourApp

# Take screenshot
xcrun simctl io booted screenshot screenshot.png

# Record video
xcrun simctl io booted recordVideo output.mov

# Open URL / deep link
xcrun simctl openurl booted "yourapp://route"

# Send push notification
xcrun simctl push booted com.example.YourApp payload.json

# Run tests via command line
xcodebuild test -scheme YourScheme -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -resultBundlePath TestResults
```
