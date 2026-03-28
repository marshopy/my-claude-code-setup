# iOS Functional Correctness Reference

Use during Phase 2 of the 360° testing workflow.

---

## Navigation Inventory Template

Build this table before starting the button sweep:

| Screen Name | Entry Point(s) | Exit Point(s) | Presentation Style |
|-------------|----------------|---------------|-------------------|
| Home        | App launch, tab | Push: Detail | Root tab          |
| Detail      | Home tap        | Back button   | Push              |
| Settings    | Tab bar         | —             | Root tab          |
| Login Modal | Any auth-gated  | Dismiss, Login | Full screen modal |

---

## Button & Control Sweep

For every screen, inventory and test each interactive element:

### Buttons
- [ ] Tapping produces immediate visual feedback (highlight, opacity change)
- [ ] Action completes correctly (navigation, API call, state change)
- [ ] Disabled state is visually distinct and cannot be tapped
- [ ] Loading state disables button and shows indicator (prevents double-submission)
- [ ] Destructive buttons (Delete, Remove, Sign Out) show confirmation alert/action sheet before executing

### Toggles & Switches
- [ ] Toggle state persists after navigating away and returning
- [ ] Toggle triggers the correct side effect (API call, UI change, preference save)
- [ ] Toggle is not in a loading state without visual indication

### Text Fields & Text Views
- [ ] Correct keyboard type for input (email → `.emailAddress`, phone → `.phonePad`, etc.)
- [ ] Return key action is appropriate (`.next` to advance to next field, `.done` or `.go` on last field)
- [ ] Secure text entry for password fields
- [ ] Character limits enforced where required
- [ ] Inline validation fires at the right time (on submit, not on every keystroke, unless confirming format)
- [ ] Clear button appears on text fields when content is present (if designed to)
- [ ] Auto-correction and auto-capitalization set appropriately per field

### Pickers, Segmented Controls, Steppers
- [ ] Value changes update UI immediately
- [ ] Value persists when leaving and returning to screen
- [ ] Min/max bounds enforced on steppers

### Lists & Tables
- [ ] Row tap navigates to the correct detail screen
- [ ] Swipe actions (delete, edit) work and confirm destructive actions
- [ ] Reordering works (if supported) and persists
- [ ] Empty list shows empty state UI (not a blank screen)
- [ ] Pagination / infinite scroll loads next page on reaching bottom

### Links
- [ ] In-app links navigate to the correct screen
- [ ] External URLs open in SFSafariViewController or the system browser (not a blank WKWebView)

---

## Navigation Wiring

- [ ] Every screen in the navigation inventory is reachable
- [ ] Back button returns to the exact prior screen (not root)
- [ ] Back swipe gesture (iOS swipe-from-left-edge) works on all pushed screens
- [ ] Modal dismiss (swipe down on sheet, or Cancel button) returns to the presenting screen
- [ ] Tab switches do not reset navigation stack within each tab
- [ ] After deep-link navigation, back button chain is logical
- [ ] After completing a flow (e.g., onboarding, purchase), the app lands on the correct screen

---

## State Management

### Empty States
- [ ] List screen with zero items shows: illustration or icon + title message + CTA (if actionable)
- [ ] Search with no results shows a "No results" message specific to the query
- [ ] Profile screen for new user shows onboarding prompt

### Loading States
- [ ] Initial data load shows a loading indicator (spinner, skeleton, or shimmer)
- [ ] Loading state replaces content area (not overlaid on stale data without indication)
- [ ] Pull-to-refresh shows indicator while refreshing

### Error States
- [ ] Network error (airplane mode test): app shows a meaningful error message with a retry action
- [ ] Server error (5xx): app shows a user-friendly message (not a raw error code)
- [ ] Auth error (401): app redirects to login without crash
- [ ] Inline form errors appear below the relevant field, not just in an alert

### Data Persistence
- [ ] Data entered in forms is not lost when backgrounding and foregrounding the app
- [ ] User preferences persist across app restarts
- [ ] Sign-out clears all user-specific cached data

---

## Edge Cases

### Orientation
- [ ] If rotation is supported: every screen lays out correctly in landscape
- [ ] If rotation is locked: landscape orientation shows an appropriate message or locks

### Interruptions
- [ ] Incoming call (simulate): `xcrun simctl spawn booted notifyutil -p com.apple.springboard.simulateIncomingCall`
  - App suspends cleanly; resumes to the same state
- [ ] Low memory warning: `Xcode → Debug → Simulate Memory Warning`
  - App handles gracefully without crash

### Background / Foreground
- [ ] Foreground after 30s background: data is fresh or a refresh is triggered
- [ ] Foreground after extended background (>10 min): app re-authenticates if session has expired

### Long Text & Localization Stress
- [ ] Test with Settings → General → Language & Region → set to a language with longer strings (German, Finnish)
  - Buttons and labels should not clip or overflow

### Accessibility Sizes
- [ ] Set to largest accessibility text size and verify no layout breakage on key screens
