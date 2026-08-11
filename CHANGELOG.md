# Changelog

Issue numbers refer to
[sethbrasile/ember-remodal](https://github.com/sethbrasile/ember-remodal/issues).

## 3.0.0-beta.0 (unreleased)

Version 3 is a ground-up rewrite as a v2 (Embroider-native) addon in
TypeScript. The jQuery [Remodal](https://github.com/vodkabears/Remodal) library
is gone; the browser's native `<dialog>` element provides the top layer, focus
containment and Escape handling. The public API — component arguments, the
yielded block hash, the `remodal` service, and the `remodal-*` / `ember-remodal`
CSS class names — is preserved wherever it could be. Upgrading from 2.x? Read
[MIGRATION.md](MIGRATION.md), which covers each breaking change with
before/after code.

Published under the `beta` dist-tag, so `ember-remodal@^2` installers are not
moved onto it. Install with `pnpm add ember-remodal@beta`.

### Breaking

- **Ember >= 5.8 is required**, and the package is a v2 addon (`"type":
"module"`, `exports`-only entry points). It works in any Embroider/Vite app
  and in classic builds via `@embroider/compat`. Older Ember must stay on 2.x.
  (#55, #45, #43)
- **jQuery, `remodal` and `ember-wormhole` are no longer dependencies.** The
  `m.open` trigger is portaled with Ember's built-in `{{in-element}}`. (#17)
- **`@glimmer/component` is now a peer dependency** (`>= 1.1.2`). Every app with
  `ember-source` already satisfies it; only unusual installs need to act.
- **String action names are gone.** 2.x's four callbacks — `onOpen`, `onClose`,
  `onConfirm`, `onCancel` — take functions now, not `sendAction` strings.
  `@onClose` also receives the close reason (`'confirmation'`, `'cancellation'`
  or `undefined`).
- **RSVP is gone.** `open()` and `close()` return native promises. Code that did
  `instanceof RSVP.Promise`, called RSVP-only methods on the result, or relied on
  RSVP's automatic runloop wrapping needs updating.
- **`hashTracking` is removed.** Remodal's `#modalname` URL tracking has no
  replacement; drive `service.open()` / `close()` from a route or query param.
- **The service's property aliases are removed** — `service.title`,
  `service.text`, `service.confirmButton`, `service.closeOnEscape`,
  `service.modifier`, `service.buttonClasses` and the rest. Pass options through
  `service.open(name, opts)`.
- **Reaching the component instance through the service is removed.** 2.x
  registered each `forService` modal as a property on the service, so
  `this.remodal.get('my-modal')`, `modal.setProperties({ … })`, `modal.set('text',
…)`, `modal.open()` and `this.set('remodal.my-modal.text', …)` all worked. The
  registry is now private. Use `service.open(name, opts)` /
  `service.close(name)`.
- **The `modal` property is removed.** It exposed the wrapped jQuery remodal
  instance, including its `getState()`. The component now has a public tracked
  `state` property (`'closed' | 'opening' | 'opened' | 'closing'`), and
  `data-test-id="modalWindow"` / `@dataTestId` are the supported DOM handles.
- **The overlay is the dialog's `::backdrop`**, not a `.remodal-overlay`
  element. Move that CSS to `dialog.remodal-wrapper::backdrop`.
- **The `data-remodal-id` attribute is gone** from the modal card. It existed
  only so the jQuery library could find the element.
- **`{{ember-remodal class="my-class"}}` no longer merges `class` onto the outer
  element.** The component is a Glimmer component now, and curly invocation
  passes `class=` as an argument rather than as an attribute. Use angle-bracket
  invocation (`<EmberRemodal class="my-class" />`), or `@modalClasses` /
  `@modifier` for the modal itself.
- **The `er-button` deep import path moved** from
  `ember-remodal/components/er-button` to
  `ember-remodal/components/ember-remodal/er-button`. The loose-mode template
  name (`ember-remodal/er-button`) is unchanged, and you rarely need either —
  the component is yielded as `m.open` / `m.confirm` / `m.cancel`.
- **The `close`-before-`open` warning id is spelled correctly**:
  `ember-remodal.close-called-on-unitialized-modal` is now
  `ember-remodal.close-called-on-uninitialized-modal`. A `registerWarnHandler`
  filter keyed on the old id will stop matching.
- **`service.open(name)` / `service.close(name)` on a name that is not currently
  rendered always reject** the returned promise. 2.x threw synchronously from a
  dev-only `assert` and did something undefined in production.
- **Confirm and cancel buttons are styled now.** They carry `remodal-confirm` /
  `remodal-cancel` from the Remodal default theme; in 2.x they rendered
  unstyled. Your `@confirmButtonClasses` / `@cancelButtonClasses` still apply.
- **`@closeOnEscape={{false}}` is honored only while the modal contains a
  focusable control.** With none, Escape closes the modal anyway and a dev-mode
  warning explains why (WCAG 2.1.2). `showModal()` makes focus containment real,
  so the 1.x/2.x combination of "no Escape, no focusable content" is now an
  inescapable keyboard trap rather than a `<div>` a user could Tab out of.
- **Backdrop dismissal requires the press and the release to land on the
  backdrop**, and ignores presses on the dialog's own scrollbar. Dragging a
  selection out of the card no longer discards the modal.
- **The bare single-word class hooks are retired.** 1.x/2.x emitted `window`,
  `close`, `button`, `title`, `text`, `content`, `open`, `link`, `native`,
  `inner`, `outer`, `confirm`, `cancel`, `paragraph`, `yielded` and
  `invisible` beside the namespaced hooks. CSS frameworks own those names —
  Bootstrap's `.close` and `.invisible`, Bulma/Foundation's `.button` — and
  every addon rule backing them sits at specificity (0,1,0), so bundle order
  (which the addon cannot control) decided the winner. Each now has an
  `ember-remodal-` prefixed replacement: `.ember-remodal.window` →
  `.ember-remodal.ember-remodal-window`, `.ember-remodal.native.close` →
  `.ember-remodal.ember-remodal-native.ember-remodal-close`, and so on. The
  `remodal-*` names are all unchanged. `@legacyClassNames={{true}}` re-emits
  the old tokens as a migration bridge. Full table in
  [MIGRATION.md](MIGRATION.md#theme-changes).
- **The stylesheet ships inside `@layer ember-remodal`**, which makes the
  documented override contract stronger (unlayered consumer CSS beats it
  regardless of specificity or order, for geometry as well as colour) at the
  cost of the two deviations below.

### Added

- `@ariaLabel` — the accessible name for a modal with no visible `@title` (a
  `@disableForeground` overlay, a block-only modal). Wins over `@title` when
  both are given, so only one naming attribute is ever emitted.
- `@closeButtonLabel` — accessible name and tooltip for the built-in close
  button, default `'Close Modal'`. An option rather than a hardcoded string so
  it can be translated.
- `@legacyClassNames` — re-emits the retired bare single-word class tokens
  beside the namespaced hooks, as a migration bridge for 2.x consumer CSS.
  Default `false`.
- A public tracked `state` property on the component:
  `'closed' | 'opening' | 'opened' | 'closing'`.
- `m.isOpen` — yielded boolean for lazy content: `{{#if m.isOpen}}…{{/if}}`. It
  stays `true` through the closing animation so content does not vanish
  mid-transition. (#40)
- `m.openAction`, `m.closeAction`, `m.confirmAction`, `m.cancelAction` — yielded
  zero-argument functions for `{{on "click" …}}` on your own elements. (#36, #23)
- `@onBeforeOpen` — return `false` to veto the open. (#23)
- The five callbacks are valid `@options` and `service.open()` keys, restoring
  2.x's `setProperties` behavior: `service.open('x', { onClose })` works.
- **Stacked modals.** A modal opened from inside another modal stacks on the top
  layer; the document scroll lock is reference-counted, so it is released only
  when the last modal closes. (#34)
- **`ember-remodal/test-support`** — a real published test-support entry point:
  `setupRemodal(hooks, options?)`, `resetRemodalScrollLock()`,
  `setRemodalAnimationDisabled(disabled)`, `remodalDialog(scope?)`,
  `remodalDialogs(scope?)`, plus the `RemodalTestHooks`, `RemodalTestAssert` and
  `SetupRemodalOptions` types. `setupRemodal` resets the module-level scroll
  lock around every test and fails the test that leaked it. This replaces
  `config/environment`'s `disableAnimationWhileTesting`, which only ever
  resolved in classic-resolver apps.
- **Test-waiter integration.** The open/close animations are wrapped in
  `@ember/test-waiters`, so `await click(…)` and `await settled()` already wait
  for them.
- **The whole colour palette is exposed as CSS custom properties**, declared on
  `:where(html)` so they carry zero specificity: any consumer declaration wins
  regardless of stylesheet order. See the theming section of the
  [README](README.md#theming-with-custom-properties);
  `demo-app/styles.css`'s `demo-midnight` theme is written entirely through
  them.
- Animations are suppressed under `prefers-reduced-motion: reduce`, and the
  close/confirm/cancel colour transitions with them.
- A `forced-colors: active` block, so Windows High Contrast does not render
  confirm and cancel identically once their backgrounds are overridden (cancel
  takes a dashed border).
- `color-scheme` on the modal card, tracking `--ember-remodal-color-scheme`, so
  form controls inside a dark-themed card render dark.
- The stylesheet is importable on its own as
  `ember-remodal/styles/ember-remodal.css` for consumers who want to control
  when the theme loads. The component imports it already, so this is optional.
- Five documented dev-only warning ids:
  `ember-remodal.close-called-on-uninitialized-modal`,
  `ember-remodal.duplicate-service-name`,
  `ember-remodal.modal-without-accessible-name`,
  `ember-remodal.no-keyboard-exit`,
  `ember-remodal.er-button-without-focusable-content`.
- Full TypeScript types and Glint signatures, exported from `ember-remodal`
  (`EmberRemodal`, `ErButton`, `RemodalService`, `EmberRemodalOptions`,
  `EmberRemodalArgs`, `EmberRemodalSignature`, `EmberRemodalYield`,
  `ErButtonSignature`, `ModalState`, `CloseReason`).
- The `>= 5.8.0` peer floor is CI-proven: the `@embroider/try` matrix runs 5.8,
  5.12, 6.4, 6.12, latest, beta and alpha, plus a floating-dependency job.

### Fixed

- **`close()`'s promise never resolved** for interrupted or rapid open/close
  sequences. Transitions are now identified by a monotonic id, so a superseded
  transition settles its callers without side effects, and every terminal path
  settles in a `finally` — a throwing consumer callback can no longer strand a
  joined caller forever. (#44, #16)
- The `<dialog>` had **no accessible name**. Screen readers announced every open
  modal as an unnamed dialog (WCAG 4.1.2). The rendered `<h2>` now carries a
  generated id and the `<dialog>` an `aria-labelledby`; `@ariaLabel` covers the
  no-title case, and opening with neither warns in development.
- The built-in close button's accessible name was **"×"**. The `::before` glyph
  participates in name-from-contents, which outranks `title`, so the `title`
  attribute was superseded. The button now carries an `aria-label`, and the CSS
  uses the alt-text form `content: "\00d7" / ""` to keep the glyph out of the
  name computation entirely.
- `<m.open>Open modal</m.open>` produced a **click-only, keyboard-unreachable
  trigger** — the yielded components render a click-delegating `<span>` and rely
  on the block supplying the real control. A dev-mode warning now says so
  (WCAG 2.1.1).
- The `<dialog>` **overflowed the viewport by 20px** on both axes and left the
  card 10px off centre: `inset: 0` plus `width/height: 100%` plus `padding:
10px` under the UA default `content-box`. The dialog is explicitly
  `border-box` now. Apps with a global `* { box-sizing: border-box }` reset
  never saw this.
- Confirm and cancel **failed WCAG 1.4.3 AA**: upstream's `#81c784` / `#e57373`
  measured 2.01:1 and 2.99:1 against white text. They are now `#2e7d32` /
  `#c62828` (5.13:1 and 5.62:1), hovers `#1b5e20` / `#b71c1c`. Revertible via
  `--ember-remodal-confirm-background` and `--ember-remodal-cancel-background`.
- The close button's **× glyph failed WCAG 1.4.11**: upstream's `#95979c`
  measured 2.92:1 against the white card, and the glyph is the only visual
  identification the control has. It is now `#767981` (4.35:1). Revertible via
  `--ember-remodal-close-color`.
- **`outline: none` / `outline: 0`** came off the dialog, the card and all three
  buttons, where it had left a 1.18:1 background swap as the only focus cue and
  nothing at all in the `@disableForeground` path. Focus is now drawn with
  `:focus-visible` rings (WCAG 2.4.7).
- **`touch-action: none` is gone from the scroll lock.** Effective
  `touch-action` is the intersection with every ancestor's, and a top-layer
  `<dialog>` is still a DOM descendant of `<html>`, so a modal taller than the
  viewport could not be panned on a touch screen (WCAG 2.1.1, 1.4.10).
  `overflow: hidden` does the locking; the dialog gains
  `overscroll-behavior: contain`.
- **`transform: translate3d(0, 0, 0)` is gone from `.remodal`**, which had made
  the card a containing block for `position: fixed` content inside it.
- `@disableForeground`'s styling **collided with Bootstrap**, which owns
  `.invisible { visibility: hidden !important }` in 3, 4 and 5 — the modal
  rendered fully hidden while still holding the top layer and trapping focus.
  The styling moved to a namespaced `ember-remodal-invisible` class, and the
  bare `invisible` class is no longer emitted at all (see the breaking change
  above). Its foreground and close glyph are custom properties now
  (`--ember-remodal-frameless-color`, `--ember-remodal-frameless-close-color`,
  `--ember-remodal-frameless-close-color-hover`) rather than a hardcoded
  `#fff`: they sit on the themable overlay, not on a card background, so
  lightening `--ember-remodal-overlay` used to leave white on light with no
  token to fix it.
- **Deviation ten: the sheet is wrapped in `@layer ember-remodal`.** Unlayered
  author CSS beats layered author CSS regardless of specificity or source
  order, so the "any consumer declaration wins" promise in the stylesheet
  header and the README now covers geometry and layout, not just the colours
  the custom properties expose. Accepted cost: `@layer` **inverts** `!important`
  precedence, so the sheet's two deliberate `!important` declarations
  (`.remodal-close::before`'s `font-family`, and `visibility: visible` on the
  `@disableForeground` card) are no longer overridable by a plain consumer
  `!important` — which is exactly the behaviour the `invisible` fix above
  wanted. Declare a layer after `ember-remodal` to win either one; see
  [MIGRATION.md](MIGRATION.md#breaking-the-stylesheet-ships-inside-layer-ember-remodal).
- **Deviation eleven: engines without `@layer` support keep the collision.**
  They ignore the at-rule's cascade semantics and fall back to plain
  specificity and order. Accepted: the addon already requires
  `dialog.showModal()` and `Element.getAnimations()`, both of which shipped
  later than `@layer`, so the layer floor is not the binding constraint.
- **`.remodal-bg` blurring is restored** as
  `html.remodal-is-locked .remodal-bg { filter: blur(3px) }`. Keep the modal
  outside the `.remodal-bg` subtree — an ancestor filter can apply to top-layer
  descendants. (#34)
- **`-webkit-text-size-adjust` is restored.** The unprefixed property alone is a
  no-op on the one platform whose text inflation it exists to suppress.
  `-webkit-overflow-scrolling: touch` and the `::-moz-focus-inner` reset were
  deleted as dead.
- Transitions **hung in a backgrounded tab**, where `requestAnimationFrame` is
  suspended and CSS animations stop advancing: a timer or websocket message
  calling `close()` never reached the close callbacks. Transitions now settle
  immediately while the document is hidden, and race a `visibilitychange` if the
  tab is backgrounded mid-transition.
- `service.open(name, opts)` during initial render **tripped Ember's
  backtracking-rerender assertion.** The override merge now yields a microtask
  first, still before the open transition starts.
- **`close()` could not cancel an `open()`** that was still waiting for its
  `<dialog>` element: it warned and no-opped while the modal opened anyway.
- A queued native `close` event could **wedge a modal shut** against a chained
  reopen, and could drop the close reason when it finalized a close on our
  behalf.
- **A modal destroyed while open now fires `@onClose`** (2.x parity) and closes
  its `<dialog>`, instead of leaving a top-layer element behind.
- A modal whose `<dialog>` never renders **rejects** instead of resolving
  indistinguishably from success.
- A dev warning (`ember-remodal.duplicate-service-name`) fires when two
  `@forService` modals share a `@name`. Lookups are still last-writer-wins, but
  the registry now **stacks** registrations instead of overwriting them, so
  destroying the newest uncovers the one it shadowed rather than leaving the
  name unreachable for the rest of the session.
- Two unterminated `{{! template-lint-disable no-invalid-interactive }}`
  comments had suppressed the rule across the whole card subtree and every
  yielded block.
- FastBoot: the v1 `index.js` that imported `remodal.min.js` into the vendor
  tree — the thing FastBoot 1.0 broke — no longer exists in any form. FastBoot
  itself is not tested or claimed as supported. (#42)

### Deliberate deviations from upstream Remodal

The ported theme is not a pixel-for-pixel copy of Remodal v1.1.1. It deviates in
**eleven** places, each for an accessibility, correctness or cascade-safety
reason, and each revertible from a consuming application — see the entries above
for the revert instructions. This is the canonical list; README, MIGRATION,
LICENSE and the stylesheet header all point at it.

Each id below is enforced: `pnpm verify:css-deviations` deletes or neutralises
the CSS behind it, rebuilds, and requires the test that pins it to go red. An
id with no killing mutation fails that script, so a twelfth deviation cannot be
added without a test that would notice its loss.

<!-- deviation-registry:start -->

1. `confirm-cancel-contrast` — confirm/cancel backgrounds darkened to `#2e7d32`
   / `#c62828` (and hovers to `#1b5e20` / `#b71c1c`) so white labels reach
   WCAG 1.4.3 AA.
2. `close-glyph-contrast` — the × glyph darkened to `#767981` so it reaches
   WCAG 1.4.11 against the card.
3. `focus-visible-rings` — `outline: none` / `outline: 0` removed from the
   dialog, the card and all three buttons, replaced by `:focus-visible` ring
   pairs (WCAG 2.4.7).
4. `no-touch-action-lock` — `touch-action: none` dropped from the scroll lock,
   with `overscroll-behavior: contain` on the dialog in its place
   (WCAG 2.1.1, 1.4.10).
5. `no-translate3d` — `transform: translate3d(0, 0, 0)` dropped from the card,
   which had made it a containing block for `position: fixed` content.
6. `namespaced-invisible` — the `@disableForeground` styling moved off the bare
   `invisible` class, which Bootstrap owns, onto `ember-remodal-invisible`.
7. `dialog-border-box` — the wrapper is the `<dialog>` itself, so it carries
   explicit `box-sizing: border-box` plus `width`/`height`/`max-*` overrides of
   the UA `fit-content` sizing rather than upstream's plain `<div>` geometry.
8. `bg-blur-hook` — the `.remodal-bg` blur is keyed on
   `html.remodal-is-locked .remodal-bg` rather than upstream's
   `.remodal-bg.remodal-is-opened`, because the state class goes on the
   `<dialog>` and the card, never on the page background.
9. `webkit-text-size-adjust` — the prefixed property is declared alongside the
   unprefixed one, and `-webkit-overflow-scrolling` / `::-moz-focus-inner` were
   deleted as dead.
10. `css-layer` — the whole sheet ships inside `@layer ember-remodal`, which
    inverts `!important` precedence against unlayered consumer CSS.
11. `no-layer-fallback` — engines without `@layer` support get no layer
    protection, and no unlayered fallback copy is shipped for them; on those
    engines the zero-specificity `:where(html)` token block is all that keeps a
    consumer override winning.

<!-- deviation-registry:end -->

Note on 11: an engine that does not recognise `@layer` discards the whole
at-rule, including its block, so it gets no addon theme at all rather than an
unlayered one. The addon already requires `dialog.showModal()` and
`Element.getAnimations()`; `@layer` shipped in the same release as `showModal()`
in Safari (15.4) and ahead of it in Firefox (97 vs 98), so Chrome 84–98 is the
only window where the required APIs are present and `@layer` is not.
