# iOS Security Review Reference

Use during Phase 4 of the 360° testing workflow.

---

## Data at Rest

### App Sandbox Inspection

Retrieve the app container path on the booted simulator:
```bash
xcrun simctl get_app_container booted <bundle-id> data
```

Then inspect these subdirectories for sensitive plaintext data:

| Path | What to Look For |
|------|-----------------|
| `Library/Preferences/<bundle-id>.plist` | Auth tokens, user IDs, session data in UserDefaults |
| `Documents/` | Exported files, cached API responses with PII |
| `Library/Caches/` | Cached network responses containing sensitive data |
| `tmp/` | Temp files that should have been deleted |

**Red flags:**
- [ ] Auth tokens or passwords stored in UserDefaults (`Library/Preferences/`)
- [ ] Sensitive JSON responses cached unencrypted in `Library/Caches/`
- [ ] SQLite databases in `Documents/` or `Library/Application Support/` storing PII without encryption
- [ ] Log files in `Documents/` containing sensitive data

### Keychain Usage
- [ ] Passwords, auth tokens, and sensitive credentials use `Security.framework` Keychain APIs (not UserDefaults)
- [ ] Keychain items use appropriate accessibility (`.whenUnlockedThisDeviceOnly` for most secrets)
- [ ] Keychain items are deleted on sign-out (verify by: sign out → sign in as different user → confirm no data leaks)

### File Protection
- [ ] Files containing PII use `.completeFileProtection` or `.completeFileProtectionUnlessOpen` attribute
- [ ] No sensitive files are marked `.noProtection`

---

## Network Security

### App Transport Security (ATS)

Check `Info.plist` for:
- [ ] `NSAllowsArbitraryLoads = YES` — **FAIL**: disables ATS globally, allows HTTP
- [ ] `NSExceptionDomains` — review each domain exception; flag HTTP allowances for non-CDN domains
- [ ] All API domains should be HTTPS with valid certificates

### Certificate Pinning
- [ ] If the app handles financial, health, or authentication data: certificate or public key pinning should be implemented
- [ ] Test with Charles Proxy or mitmproxy (MITM test): if pinning is enabled, the app should reject the proxy certificate and fail gracefully (not crash or silently continue)

### Network Traffic Review (Instruments)
During Phase 3 profiling, also check:
- [ ] No credentials or tokens appear in URL query parameters (should be in headers or body)
- [ ] Authorization headers are present and correct (`Bearer <token>`)
- [ ] API responses do not include fields unnecessary for the client (over-fetching sensitive data)

---

## Authentication & Session Management

- [ ] Tokens are not logged to the console (search source for `print(token`, `NSLog`, `os_log` with non-private tokens)
- [ ] Token refresh is handled silently when a 401 is received
- [ ] After sign-out, all in-memory session state is cleared
- [ ] After sign-out, navigating back (if possible) does not reveal protected content
- [ ] Biometric authentication (Face ID / Touch ID) uses `LAContext` from `LocalAuthentication` framework
- [ ] Biometric fallback (PIN/password) works correctly
- [ ] Session timeout is enforced after inactivity (if applicable to the app's security requirements)

---

## Logging & Debugging

Search the source code for these patterns and verify they do not expose sensitive data in production builds:

```bash
# Find potential sensitive logging
grep -rn "print(" . --include="*.swift" | grep -i -E "(token|password|secret|key|auth|credential)"
grep -rn "NSLog" . --include="*.swift"
grep -rn "debugPrint" . --include="*.swift"
```

- [ ] `print()` statements do not output tokens, passwords, or PII
- [ ] Production builds use `os_log` with `%{private}` format for sensitive values
- [ ] `DEBUG` preprocessor flag gates verbose logging (not compiled into Release builds)

---

## Sensitive UI Protections

### App Switcher / Screenshot Prevention
- [ ] Screens displaying sensitive data (payment info, SSN, auth codes, passwords) add a privacy overlay when the app goes to background:
  - SwiftUI: `.privacySensitive()` modifier or manual overlay in `scenePhase` handler
  - UIKit: add an overlay view in `applicationWillResignActive`
- [ ] Verify by: open the sensitive screen → press Home → check the app switcher card

### Pasteboard
- [ ] Password fields use `isSecureTextEntry = true` (disables copy/paste by default)
- [ ] If copy is enabled for sensitive values (e.g., TOTP codes): the pasteboard item has an expiry (`UIPasteboard.general.setItems(..., options: [.expirationDate: ...])`

### Screenshot & Screen Recording
- [ ] If the app has content that must not be captured (e.g., DRM video), verify that `AVPlayerLayer` with `AVPlayer` automatically prevents screenshots (this is handled by the system for protected content)

---

## Permissions & Privacy

- [ ] The app's `Info.plist` does not request permissions that are not used (remove unused `NS*UsageDescription` keys)
- [ ] Privacy Manifest (`PrivacyInfo.xcprivacy`) is present and accurately declares all API usage categories (required for App Store submission since iOS 17)
- [ ] No use of device fingerprinting APIs beyond what is declared in the Privacy Manifest

---

## Dependency Audit

Check `Podfile.lock`, `Package.resolved`, or `Cartfile.resolved`:
- [ ] No known vulnerable versions of dependencies (check against the CVE database or GitHub Security Advisories)
- [ ] Third-party analytics SDKs are initialized after user consent (if applicable under GDPR/CCPA)
- [ ] Crash reporting SDK does not send personally identifiable information without consent
