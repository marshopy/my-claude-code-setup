# iOS Permissions & System Components Reference

Use during Phase 5 of the 360° testing workflow.

---

## Permissions Testing Matrix

For each permission below, verify all three states: **Not Determined** (fresh install), **Denied**, **Granted**.

Reset all permissions before starting:
```bash
xcrun simctl privacy booted reset all <bundle-id>
```

Grant/revoke individual permissions programmatically:
```bash
xcrun simctl privacy booted grant <service> <bundle-id>
xcrun simctl privacy booted revoke <service> <bundle-id>
```

### Camera (`NSCameraUsageDescription`)
- [ ] Usage description is present in Info.plist and explains *why* (not just "access camera")
- [ ] Permission is requested when the user first triggers a camera action (not on app launch)
- [ ] **Denied:** App shows explanation message with "Open Settings" button linking to app settings
- [ ] **Granted:** Camera opens and functions correctly within the app

### Microphone (`NSMicrophoneUsageDescription`)
- [ ] Usage description meaningful and specific
- [ ] **Denied:** Recording feature is disabled with explanation
- [ ] **Granted:** Microphone captures audio correctly

### Photo Library (`NSPhotoLibraryUsageDescription`, `NSPhotoLibraryAddUsageDescription`)
- [ ] Distinguish between read access and add-only access — use the minimal permission required
- [ ] PHPicker (iOS 14+) is used instead of UIImagePickerController where possible (no permission needed for PHPicker)
- [ ] **Denied:** Photo picker or save action shows explanation
- [ ] **Granted/Limited:** App handles limited photo library access gracefully (iOS 14+)

### Location (`NSLocationWhenInUseUsageDescription`, `NSLocationAlwaysAndWhenInUseUsageDescription`)
- [ ] App requests "When In Use" first; escalates to "Always" only if necessary and with explanation
- [ ] Usage description explains specifically what location is used for
- [ ] **Denied:** Location-dependent features degrade gracefully (fallback to manual entry, or explanation)
- [ ] **Granted:** Location updates trigger correct behavior (map center, nearby search, etc.)
- [ ] Location accuracy is appropriate to the use case (don't request full accuracy for city-level features — use `desiredAccuracy = kCLLocationAccuracyReduced`)

Simulate location in Simulator:
```
Simulator → Features → Location → Custom Location (set lat/lon)
```

### Contacts (`NSContactsUsageDescription`)
- [ ] **Denied:** Contact-dependent features show explanation with Settings link
- [ ] **Granted:** Contacts are read correctly; app does not upload full contact list without explicit user consent

### Calendar (`NSCalendarsUsageDescription`)
- [ ] Write-only usage requests write access; read+write requests full access
- [ ] **Denied:** Calendar features are disabled gracefully
- [ ] **Granted:** Events are created/read correctly

### Reminders (`NSRemindersUsageDescription`)
- [ ] Same pattern as Calendar

### Motion & Fitness (`NSMotionUsageDescription`)
- [ ] **Denied:** Step count / fitness features disabled gracefully
- [ ] **Granted:** Motion data is correct

### Health (`NSHealthShareUsageDescription`, `NSHealthUpdateUsageDescription`)
- [ ] HealthKit entitlement is declared in the entitlements file
- [ ] Individual data types are requested, not blanket access
- [ ] **Denied:** Health features degrade gracefully

### Bluetooth (`NSBluetoothAlwaysUsageDescription`)
- [ ] **Denied / Off:** App handles CBCentralManagerStatePoweredOff and CBManagerAuthorizationDenied gracefully
- [ ] **Granted:** Device scanning and connection work correctly

### Face ID / Touch ID (`NSFaceIDUsageDescription`)
- [ ] Usage description explains why biometrics are used
- [ ] `LAContext.canEvaluatePolicy` checked before showing biometric option
- [ ] Fallback to password/PIN when biometrics fail or are unavailable
- [ ] Biometric prompt not shown immediately on cold launch (only when user initiates a protected action)

### Notifications (`UNUserNotificationCenter`)
- [ ] Permission is requested at an appropriate moment (after user opts into a feature, not on launch)
- [ ] **Denied:** Notification-dependent features inform the user and offer a Settings deep-link
- [ ] **Granted:** Test notification delivery using simctl:
  ```bash
  xcrun simctl push booted <bundle-id> scripts/test-push.json
  ```
- [ ] Notification tap action deep-links to the correct screen
- [ ] Badge count clears when the app is opened

Test push payload template (`scripts/test-push.json`):
```json
{
  "aps": {
    "alert": {
      "title": "Test Notification",
      "body": "This is a test push from xcrun simctl"
    },
    "badge": 1,
    "sound": "default"
  }
}
```

### Local Network (`NSLocalNetworkUsageDescription`)
- [ ] Usage description is present if the app uses Bonjour or local network APIs
- [ ] **Denied:** Local network features degrade gracefully

---

## Background Modes

Check `UIBackgroundModes` keys in Info.plist and test each declared mode:

| Mode | Key | Test Method |
|------|-----|-------------|
| Background Fetch | `fetch` | Xcode → Debug → Simulate Background Fetch |
| Remote Notifications | `remote-notification` | Send silent push with `content-available: 1` |
| Background Audio | `audio` | Lock simulator, verify audio continues |
| Background Location | `location` | Verify location updates fire in background |
| VoIP | `voip` | PushKit credentials and handler tested |
| Background Processing | `processing` | `BGTaskScheduler` tasks registered and tested |

- [ ] App only declares background modes it actually uses
- [ ] Background tasks complete within their time budget (background fetch < 30s)
- [ ] `BGAppRefreshTask` and `BGProcessingTask` are registered in `application(_:didFinishLaunchingWithOptions:)`

---

## Universal Links & URL Schemes

### URL Schemes
Test custom URL scheme:
```bash
xcrun simctl openurl booted "yourapp://path?param=value"
```
- [ ] App opens and navigates to the correct screen
- [ ] Parameters are parsed and applied correctly
- [ ] Invalid/malformed URLs are handled gracefully (no crash)

### Universal Links
Test associated domain:
```bash
xcrun simctl openurl booted "https://yourdomain.com/path"
```
- [ ] `apple-app-site-association` file is hosted at `https://yourdomain.com/.well-known/apple-app-site-association`
- [ ] App opens (not browser) when the link is tapped from Messages, Notes, Safari
- [ ] App handles the path and navigates to the correct screen
- [ ] Fallback to website works if the app is not installed

---

## Hardware & Platform Features

### Status Bar
- [ ] Status bar style (`.lightContent` / `.darkContent` / `.default`) matches the screen background
- [ ] Status bar is not hidden unnecessarily (hiding reduces trust on security-sensitive screens)

### Keyboard
- [ ] Keyboard appears for focused text fields
- [ ] Keyboard dismisses on scroll (`UIScrollView.keyboardDismissMode = .onDrag` or `.interactive`)
- [ ] No content hidden behind the keyboard
- [ ] Hardware keyboard (iPad/Mac Catalyst) does not break the layout

### Home Indicator & Safe Areas
- [ ] Content does not overlap the home indicator
- [ ] `.edgesIgnoringSafeArea(.bottom)` used only where intentional (full-bleed backgrounds, not interactive content)
- [ ] Home indicator can be deferred for immersive content (games, video) using `prefersHomeIndicatorAutoHidden`

### Haptics
- [ ] Success feedback: `UINotificationFeedbackGenerator().notificationOccurred(.success)`
- [ ] Error feedback: `UINotificationFeedbackGenerator().notificationOccurred(.error)`
- [ ] Selection feedback: `UISelectionFeedbackGenerator().selectionChanged()` on picker changes
- [ ] Impact feedback: `UIImpactFeedbackGenerator(style:).impactOccurred()` on drag/drop or significant UI events
- [ ] Haptics are not overused (should feel intentional, not constant)

### Dynamic Island & Live Activities (iPhone 14 Pro+ features)
- [ ] If Live Activities are implemented: test start, update, and end lifecycle
- [ ] ActivityKit entitlement is declared
- [ ] Live Activity UI renders correctly in all sizes (compact, minimal, expanded)

### iPad Multitasking (if iPad is supported)
- [ ] Slide Over: app adapts layout for narrow width
- [ ] Split View: app functions at 1/2 and 1/3 screen widths
- [ ] Stage Manager (iPadOS 16+): app resizes to arbitrary window sizes without layout breakage
