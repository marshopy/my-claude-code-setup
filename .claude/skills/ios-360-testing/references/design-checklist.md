# iOS Design Check Reference

Use during Phase 1 of the 360° testing workflow.

---

## Layout & Spacing

- [ ] Content respects safe area insets (no text/buttons under notch, home indicator, or Dynamic Island)
- [ ] 8pt grid adherence — spacing between elements is a multiple of 8 (or 4 for small gaps)
- [ ] Consistent horizontal margins (typically 16pt from screen edges)
- [ ] No content clipping at screen edges or overlapping with system UI
- [ ] Scroll views have correct content insets (bottom inset clears tab bar / home indicator)
- [ ] Keyboard avoidance works — focused fields scroll above the keyboard

## Typography

- [ ] Dynamic Type is supported — test by going to Settings → Accessibility → Display & Text Size → Larger Text and changing the slider; text should scale
- [ ] Consistent type scale across the app (title, headline, body, caption — not random sizes)
- [ ] Text does not truncate prematurely with default font size
- [ ] Long text wraps correctly and doesn't overflow containers
- [ ] Text contrast meets WCAG AA minimum (4.5:1 for body text) — verify with Accessibility Inspector

## Color & Theming

- [ ] App uses system semantic colors (`.label`, `.background`, `.systemBlue`, etc.) or well-defined custom tokens — no hardcoded hex values for UI colors
- [ ] All screens adapt correctly in Light Mode
- [ ] All screens adapt correctly in Dark Mode (toggle with `Cmd+Shift+A` in Simulator)
- [ ] No pure white backgrounds on screens that should adapt to dark mode
- [ ] Destructive actions consistently use red; primary actions consistently use the brand color
- [ ] No color used as the sole differentiator for information (colorblind accessibility)

## Icons & Images

- [ ] All icons use SF Symbols or custom assets at the correct weight to match surrounding text weight
- [ ] Icons are appropriately sized (22pt for navigation bar icons, 24–28pt for tab bar icons)
- [ ] Images display at the correct resolution (no pixelation from undersized assets)
- [ ] Images have correct content mode (`.aspectFit` for photos, `.aspectFill` for hero images with clipping)
- [ ] Template images (icons used as masks) tint correctly in dark mode and when selected

## Navigation & Chrome

- [ ] Navigation bar titles are consistent style (large title vs inline) within each section
- [ ] Back button label is appropriate (previous screen title, or "Back" if title is too long)
- [ ] Tab bar is present on all root-level screens (not hidden behind pushed views)
- [ ] Tab bar item labels are short (≤12 characters), icons are distinct
- [ ] Toolbar buttons are appropriately positioned (destructive actions on trailing side)
- [ ] Modal presentations use consistent style (.sheet, .fullScreenCover) for equivalent flows
- [ ] Alert and action sheet styles are consistent across the app

## Consistency Across Screens

For each screen, compare against 3 other screens to confirm:

- [ ] Same navigation bar appearance (opaque vs transparent, same tint color)
- [ ] Same empty state UI pattern (illustration + title + CTA button)
- [ ] Same loading indicator style (spinner, skeleton, shimmer — not mixed)
- [ ] Same error UI pattern (inline banner, toast, modal alert — consistent per error type)
- [ ] Same list/cell style for equivalent data types
- [ ] Same button hierarchy (primary = filled, secondary = outlined, tertiary = text)

## Accessibility

Run Accessibility Inspector audit on each screen:

- [ ] All interactive elements have accessibility labels
- [ ] Accessibility labels are descriptive (not "button" or the icon name)
- [ ] Minimum touch target size: 44×44pt for all interactive elements
- [ ] Accessibility traits are correct (`.button`, `.header`, `.link`, `.image` as appropriate)
- [ ] VoiceOver reading order is logical (top-to-bottom, left-to-right unless intentional)
- [ ] Custom UI components expose correct accessibility value (e.g., sliders announce current value)
- [ ] Focus management on modal presentation (VoiceOver focus moves into modal)

## Platform-Specific Design

- [ ] Swipe-to-delete (or swipe actions) on list rows where expected by iOS convention
- [ ] Long-press context menus (UIContextMenu / .contextMenu) on interactive content where applicable
- [ ] Pull-to-refresh on scrollable content lists (where data can be refreshed)
- [ ] Haptic feedback on significant state changes (success, error, selection)
- [ ] App icon matches brand identity and renders correctly at all sizes (check in Settings and Springboard)
