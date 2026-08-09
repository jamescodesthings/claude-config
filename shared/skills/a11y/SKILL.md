---
name: a11y
description: Frontend a11y — HTML, ARIA, keyboard, contrast, forms, images
---

# Accessibility Review (a11y)

Check frontend changes for accessibility issues. Fix clear violations in place. Flag ambiguous items for author review rather than guessing intent.

## Output Format

List violations with element and file:line reference. Mark items requiring browser/screen-reader verification with `[manual check]`.

## Checks

### Semantic structure
- Heading hierarchy is logical — no skipped levels (h1 → h3), no headings used for visual styling
- Landmark elements present: `<main>`, `<nav>`, `<header>`, `<footer>`, `<aside>` where appropriate
- Lists use `<ul>`/`<ol>` — not `<div>` or `<span>` chains masquerading as lists

### Images and media
- All `<img>` have `alt` attribute — empty `alt=""` is correct for purely decorative images, not missing
- Icons used as interactive elements have `aria-label` or adjacent visible text
- Videos carrying information have captions or transcripts

### Forms
- Every `<input>`, `<select>`, `<textarea>` has an associated `<label>` via `for`/`id`, `aria-label`, or `aria-labelledby`
- Error messages are descriptive ("Email must be a valid address", not "Invalid input") and programmatically associated with their field via `aria-describedby`
- Required fields indicated in a way that doesn't rely solely on colour
- Submit buttons have descriptive text

### Keyboard and focus
- All interactive elements reachable by Tab in logical order
- Focus indicator visible — `outline: none` / `outline: 0` without a replacement style is a violation
- No keyboard traps — user can Tab out of every component
- Modal dialogs: focus moves into modal on open, is trapped within, restores to trigger on close

### Colour and contrast
- Hardcoded colour values that may fail WCAG AA (4.5:1 for normal text, 3:1 for large text/UI components) — flag for `[manual check]` if cannot verify statically
- Information not conveyed by colour alone (error states use icon + text, not just red colour)

### ARIA
- ARIA roles/properties only added where native HTML semantics are insufficient
- `aria-label` values are descriptive and not redundant with visible text
- `role="button"` on a non-`<button>` element also has `tabindex="0"` and keyboard handler
- `aria-hidden="true"` not applied to focusable elements

### Interactive elements
- Buttons have descriptive accessible text — not "click here", not icon-only without `aria-label`
- Links describe their destination in context — not "read more" without context
