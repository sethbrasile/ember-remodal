# Migrating from ember-remodal 2.x to 3.0

Version 3 is a ground-up rewrite as a v2 addon on the native `<dialog>`
element. The good news: the public API was deliberately preserved, so for most
apps the upgrade is small. This guide lists everything that changed.

## Requirements

- **Ember >= 5.8.** 3.x works in any Embroider/Vite app, and in classic builds
  via `@embroider/compat`. Older Ember versions must stay on 2.x.
- **jQuery and the remodal library are no longer used or installed.** If
  nothing else in your app needs jQuery, you can remove it.
- **ember-wormhole is no longer a dependency.** The yielded `m.open` trigger is
  now portaled with Ember's built-in `in-element`.

## Breaking changes

### String actions → function arguments

2.x used `sendAction`-style string action names. 3.0 takes plain functions:

```hbs
{{! 2.x }}
{{ember-remodal openButton="Open" onOpen="modalDidOpen" onClose="modalDidClose"}}
```

```hbs
{{! 3.0 }}
<EmberRemodal
  @openButton="Open"
  @onOpen={{this.modalDidOpen}}
  @onClose={{this.modalDidClose}}
/>
```

`@onClose` now also receives the close reason (`'confirmation'`,
`'cancellation'`, or `undefined`) as its argument.

### `hashTracking` removed

Remodal's URL-hash tracking (`#modalname` in the address bar) is gone. In an
Ember app the router owns the URL; if you need URL-driven modals, drive
`service.open()`/`close()` from a route or query param instead.

### Removed: the service's property aliases

2.x's `remodal` service exposed a grab-bag of properties that aliased onto the
default modal instance — `service.title`, `service.confirmButton`,
`service.closeOnEscape`, `service.modifier`, `service.buttonClasses`, and
several more (see the old `addon/services/remodal.js`). Reading or setting
these directly (`this.remodal.set('title', 'Are you sure?')`,
`{{this.remodal.title}}`) only ever worked if a modal happened to be
registered under the default name; it was never a documented, reliable API.

3.0 drops them entirely. Pass options through `service.open(name, opts)`
instead:

```js
// 2.x
this.remodal.set('title', 'Are you sure?');
this.remodal.open();

// 3.0
this.remodal.open('ember-remodal', { title: 'Are you sure?' });
```

### Confirm/cancel buttons are now styled

The confirm and cancel buttons now carry the `remodal-confirm` /
`remodal-cancel` theme classes (green/red flat buttons from the remodal default
theme). In 2.x they rendered unstyled. If you styled them yourself via
`confirmButtonClasses` / `cancelButtonClasses`, your classes still apply — but
check for visual conflicts with the new defaults, or override
`.remodal-confirm` / `.remodal-cancel`.

### Under-the-hood differences that may affect edge cases

- The overlay is the dialog's `::backdrop` pseudo-element, not a
  `.remodal-overlay` div. CSS targeting `.remodal-overlay` should move to
  `dialog.remodal-wrapper::backdrop`.
- The wrapper element *is* the `<dialog>` (it still has the `remodal-wrapper`
  class and `data-test-id="modalWrapper"`).
- The modal renders in the browser's top layer, so `z-index` hacks around the
  old wrapper are unnecessary (and have no effect).
- Focus containment and restoration are handled by the browser's native modal
  behavior.
- Some browsers (notably Chromium) may force-close a `<dialog>` on a quick
  double-press of Escape, as part of a built-in abuse-prevention guard, even
  with `@closeOnEscape={{false}}`. This is a platform limitation, not addon
  behavior — the modal's internal state stays consistent either way.

## What stayed the same

- **All component arguments**: `title`, `text`, `confirmButton`,
  `cancelButton`, `openButton`, `openLink`, `linkButton`, `name`, `forService`,
  `dataTestId`, `modifier`, `modalClasses`, `buttonClasses`,
  `outerButtonClasses`, `innerButtonClasses`, `openButtonClasses`,
  `openLinkClasses`, `confirmButtonClasses`, `cancelButtonClasses`,
  `closeOnEscape`, `closeOnCancel`, `closeOnConfirm`, `closeOnOutsideClick`,
  `disableForeground`, `disableNativeClose`, `disableAnimation`, and the
  `options` hash — same names, same defaults.
- **The yielded block API**: `m.open`, `m.confirm`, `m.cancel` work exactly as
  before (including portaling of `m.open` out of the dialog).
- **The `remodal` service**: `open(name, opts?)` and `close(name)`, the same
  default name (`'ember-remodal'`), the same persistent option overrides
  (merged cumulatively across calls, exactly like 2.x's `setProperties`), and
  the same helpful assertion when a modal is not rendered (in production
  builds, where the assertion is stripped, `open()`/`close()` reject the
  returned promise instead — an improvement over 2.x, which threw an
  unguarded error in that case).
- **Option precedence**: `@options` wins over individual arguments, and
  `service.open()` overrides win over both — the same order 2.x resolved
  options in.
- **Promise semantics**: `open()`/`close()` resolve with the modal once the
  animation finishes — and now they resolve reliably even for interrupted or
  rapid open/close sequences (2.x issue #44).
- **CSS class names and test selectors**: `remodal`, `remodal-is-*` state
  classes, `remodal-close`, `remodal-is-locked`, the `ember-remodal …` utility
  classes, and every `data-test-id` (`modalWindow`, `modalWrapper`,
  `openButton`, `confirmButton`, `cancelButton`, `nativeClose`, `title`,
  `text`, `yielded`).
- **`disableAnimationWhileTesting`** in `config/environment.js` (though with
  test-waiter integration you likely no longer need it).

## New in 3.0

- `m.isOpen` — yielded boolean for lazy-rendering modal content:
  `{{#if m.isOpen}}…{{/if}}`.
- `m.openAction` / `m.closeAction` / `m.confirmAction` / `m.cancelAction` —
  yielded zero-argument functions for use with `{{on}}` on your own elements.
- `@onBeforeOpen` — return `false` to veto opening.
- **Stacked modals**: opening a modal from within another modal now works
  naturally via the top layer.
- **Test-waiter integration**: `await click(…)`/`await settled()` wait for the
  open/close animations automatically.
- Animations are suppressed under `prefers-reduced-motion: reduce`.
- Full TypeScript types and Glint signatures; imports available from
  `ember-remodal` (`EmberRemodal`, `RemodalService`, and the public types).
