# Migrating from ember-remodal 2.x to 3.0

Version 3 is a ground-up rewrite as a v2 addon on the native `<dialog>`
element. The public API was preserved wherever it could be, so for most apps
the upgrade is small — but "most" is not "all", and this guide lists every
change that can reach your code.

If you are new to ember-remodal, read the [README](README.md) instead; this
document assumes you have a working 2.x integration in front of you.

- [Requirements](#requirements)
- [Install](#install)
- [Breaking changes](#breaking-changes)
- [Accessibility behavior changes](#accessibility-behavior-changes)
- [Theme changes](#theme-changes)
- [Testing your upgrade](#testing-your-upgrade)
- [What stayed the same](#what-stayed-the-same)
- [New in 3.0](#new-in-30)

## Requirements

- **Ember >= 5.8.** 3.x works in any Embroider/Vite app, and in classic builds
  via `@embroider/compat`. Older Ember versions must stay on 2.x. The floor is
  exercised in CI across 5.8, 5.12, 6.4, 6.12, latest, beta and alpha.
- **jQuery and the `remodal` library are no longer used or installed.** If
  nothing else in your app needs jQuery, you can remove it.
- **`ember-wormhole` is no longer a dependency.** The yielded `m.open` trigger
  is portaled with Ember's built-in `{{in-element}}`.
- **`@glimmer/component` is now a peer dependency** (`>= 1.1.2`). Every app with
  `ember-source` already has it; only unusual installs (a strict package manager
  with no hoisting and no direct `@glimmer/component` entry) need to add it.

## Install

3.0 is published under the `beta` dist-tag while it is in beta, so
`ember-remodal@latest` still resolves to 2.18.0:

```sh
pnpm add ember-remodal@beta
```

## Breaking changes

### String actions → function arguments

2.x used `sendAction`-style string action names for its four callbacks —
`onOpen`, `onClose`, `onConfirm` and `onCancel`. 3.0 takes plain functions (and
adds a fifth, `onBeforeOpen`):

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

`@onClose` now also receives the close reason — `'confirmation'`,
`'cancellation'`, or `undefined` when the modal was closed some other way.

### RSVP promises → native promises

2.x returned `rsvp` promises from `open()` and `close()`. 3.0 returns native
ones. The awaiting/`.then()` shape is unchanged, but:

- `result instanceof RSVP.Promise` is now `false`.
- RSVP-only methods on the returned value (`.finally()` predates native support,
  but `RSVP.hash`-style helpers, `.fail()`, and RSVP's `Promise.cast`) are gone.
- RSVP promises resolved inside an autorun, so a `.then()` callback that mutated
  tracked state or scheduled work often happened to land inside a runloop.
  Native promise callbacks do not. If a callback of yours relies on that, wrap it
  yourself.

### `hashTracking` removed

Remodal's URL-hash tracking (`#modalname` in the address bar) is gone. In an
Ember app the router owns the URL; if you need URL-driven modals, drive
`service.open()` / `close()` from a route or a query param instead.

### The service's property aliases are removed

2.x's `remodal` service exposed a grab-bag of properties that aliased onto
whichever modal was registered under the default name — `service.title`,
`service.text`, `service.confirmButton`, `service.closeOnEscape`,
`service.modifier`, `service.buttonClasses`, and several more (see the old
`addon/services/remodal.js`). Pass options through `service.open()` instead:

```js
// 2.x
this.remodal.set('title', 'Are you sure?');
this.remodal.open();

// 3.0
this.remodal.open('ember-remodal', { title: 'Are you sure?' });
```

### Reaching the modal component through the service is removed

This one was documented in 2.x, with three distinct call shapes, so it is worth
spelling out. 2.x's `_setProperties()` ran
`this.get('remodal').set(this.get('name'), this)`, which put every
`forService=true` modal component on the service as a property. That made all of
this work:

```js
// 2.x — all three of these are gone in 3.0
const modal = this.get('remodal.my-second-modal');
modal.setProperties({ title: 'A Modal', text: 'Text in a modal' });
modal.set('text', 'Other text in a modal');
modal.open();

this.set('remodal.my-awesome-modal.text', text);
```

3.0 keeps its registry in a private `Map`, so there is no property to read and
nothing to `set()`. Everything above becomes one `open()` call, which merges the
options and then opens:

```js
// 3.0
this.remodal.open('my-second-modal', {
  title: 'A Modal',
  text: 'Other text in a modal',
});
```

Options given to `open()` persist for the modal — they merge into any set by a
previous call, exactly like 2.x's `setProperties` — so to change text without
reopening, pass it on the next `open()`, or drive the content from your own
tracked state in a block-form modal.

### The `modal` property (and `getState()`) is removed

2.x exposed the wrapped jQuery remodal instance as `modal`, which is how the
repro in [#44](https://github.com/sethbrasile/ember-remodal/issues/44) reached
`remodal.<name>.modal` and called `getState()` on it. Both are gone with the
library. The replacements:

- **State**: the component has a public tracked `state` property —
  `'closed' | 'opening' | 'opened' | 'closing'`. In a template, `m.isOpen` is
  the yielded boolean (true for anything other than `'closed'`).
- **The DOM element**: pass `@dataTestId="my-modal"` and select
  `[data-test-id="my-modal"]` for the outer component element, or
  `[data-test-id="modalWindow"]` for the modal card and
  `[data-test-id="modalWrapper"]` for the `<dialog>` itself. In tests,
  `remodalDialog()` from `ember-remodal/test-support` hands you the `<dialog>`
  directly.

### `service.open()` / `close()` on an unrendered name always reject

2.x called a bare `assert(message)` — which threw synchronously in development
and did nothing coherent in a production build, where asserts are stripped. 3.0
returns a rejected promise in every build:

```js
try {
  await this.remodal.open('not-rendered');
} catch (error) {
  // error.message explains that no modal is registered under that name
}
```

Any `try`/`catch` you wrote around a synchronous throw needs to become a
`.catch()` or an `await` inside `try`.

### `{{ember-remodal class="…"}}` no longer merges `class`

2.x was a classic `Component` with `tagName: 'span'`, so `class="x"` in a curly
invocation merged onto its element. 3.0 is a Glimmer component, and curly
invocation passes `class=` as an *argument*, which the component ignores. Use
angle-bracket invocation, where `class` is an attribute again:

```hbs
{{! 2.x }}
{{ember-remodal class="my-wrapper" openButton="Open"}}

{{! 3.0 }}
<EmberRemodal class="my-wrapper" @openButton="Open" />
```

For the modal itself rather than the outer element, `@modalClasses` and
`@modifier` are the right hooks.

### The `er-button` deep import path moved

```diff
- import ErButton from 'ember-remodal/components/er-button';
+ import ErButton from 'ember-remodal/components/ember-remodal/er-button';
```

The loose-mode template name is unchanged (`ember-remodal/er-button`). You
rarely need either — the component is yielded as `m.open` / `m.confirm` /
`m.cancel`, and `ErButton` is also re-exported from the package root.

### The `close`-before-`open` warning id is spelled correctly

`ember-remodal.close-called-on-unitialized-modal` is now
`ember-remodal.close-called-on-uninitialized-modal`. If you filter it with
`registerWarnHandler`, update the id or the filter stops matching.

### `data-remodal-id` is gone

The modal card no longer carries `data-remodal-id="{{elementId}}"`; it existed
only so the jQuery library could find the element. Selectors keyed on it should
move to `[data-test-id="modalWindow"]`, or to `@dataTestId` on the component.

### The overlay is `::backdrop`, not `.remodal-overlay`

CSS targeting `.remodal-overlay` should move to
`dialog.remodal-wrapper::backdrop`. Note that `::backdrop` cannot be targeted by
a class the component puts on the card, which is why the theme's colours are
exposed as custom properties — see [Theme changes](#theme-changes).

### Confirm and cancel buttons are styled now

They carry the `remodal-confirm` / `remodal-cancel` theme classes (flat
green/red buttons from the Remodal default theme). In 2.x they rendered
unstyled, because the addon shipped the theme but never applied those classes.
Your `@confirmButtonClasses` / `@cancelButtonClasses` still apply — check for
visual conflicts, or override `.remodal-confirm` / `.remodal-cancel`, or set
`--ember-remodal-confirm-background` / `--ember-remodal-cancel-background`.

### Backdrop dismissal requires press *and* release

`@closeOnOutsideClick` (still `true` by default) now dismisses only when both
the `mousedown` and the `click` land on the backdrop, and never when the press
landed on the dialog's own scrollbar. Under remodal 1.x, dragging a text
selection from inside the card and releasing over the backdrop discarded the
modal, because the `click` dispatches on the common ancestor.

### Under-the-hood differences that may affect edge cases

- The wrapper element *is* the `<dialog>`. It keeps the `remodal-wrapper` class
  the jQuery library used to add at runtime, and gains
  `data-test-id="modalWrapper"`.
- The modal renders in the browser's top layer, so `z-index` hacks around the
  old wrapper are unnecessary and have no effect.
- Focus containment and restoration are the browser's native modal behavior.
  `showModal()` snapshots the currently focused element and restores it on
  close — so restoration happens when the closing animation finishes, roughly
  300ms after `close()` is called, not immediately.
- `remodal-is-initialized` is still emitted on the card for 1.x/2.x consumer CSS
  and test selectors, but no addon rule targets it: upstream used it to unwind an
  anti-FOUC `display: none`, which a `<dialog>` makes unnecessary.

## Accessibility behavior changes

Three of these change what your app does at runtime, not only what it looks
like.

### `@closeOnEscape={{false}}` is conditional now

It is honored only while the modal contains a focusable control. With none,
Escape closes the modal anyway, and a dev-mode warning
(`ember-remodal.no-keyboard-exit`) explains why. Under 1.x/2.x the modal was a
plain `<div>` a keyboard user could Tab out of; `showModal()` makes focus
containment real, so "Escape suppressed, nothing focusable inside" is now an
inescapable keyboard trap (WCAG 2.1.2, Level A). This is deliberately not
dev-only — development and production must not disagree about whether a modal
can be escaped.

To keep Escape suppressed, render the built-in close button (drop
`@disableNativeClose` / `@disableForeground`) or put any focusable control
inside the modal.

### Escape can force-close regardless of `@closeOnEscape={{false}}`

3.0 intercepts the `<dialog>`'s `cancel` event and calls `preventDefault()` so
the closing animation plays. In browsers implementing the HTML close-watcher
algorithm, that event is dispatched **non-cancelable** when the window has no
history-action activation — and then `preventDefault()` does nothing and the
dialog closes.

In practice:

- A modal the user opened by clicking something: the first Escape is
  cancelable, so `@closeOnEscape={{false}}` holds. A second Escape in quick
  succession can still force-close (the abuse-prevention guard).
- A modal opened **programmatically** with no preceding user gesture — a timer,
  a websocket message, `service.open()` from a route hook: the first Escape can
  force-close it.

This is a platform behavior, not addon behavior, and the modal's internal state
stays consistent either way: the queued native `close` event re-syncs `state`
and `@onClose` still fires with no reason.

### Yielded `m.open` / `m.confirm` / `m.cancel` blocks must contain a focusable control

Those components render a click-delegating `<span>` and rely on your block
supplying the real control. `<m.open>Open modal</m.open>` compiles and works
with a mouse, but a keyboard user can never reach it (WCAG 2.1.1). 3.0 warns in
development (`ember-remodal.er-button-without-focusable-content`). Write:

```hbs
<EmberRemodal @title="Custom content" as |m|>
  <m.open><button type="button">Open modal</button></m.open>
</EmberRemodal>
```

This was equally true in 2.x; it was simply never diagnosed.

### The rendered markup gained naming attributes

If you snapshot the modal's markup, expect: a generated `id` on the `<h2>`, an
`aria-labelledby` (or `aria-label`) on the `<dialog>`, and an `aria-label` plus
`title` on the close button. There is a new `@ariaLabel` option for modals with
no visible `@title`, and a new `@closeButtonLabel` (default `'Close Modal'`,
translatable). Opening a modal with neither `@title` nor `@ariaLabel` warns in
development (`ember-remodal.modal-without-accessible-name`).

## Theme changes

Every 2.x class hook still exists — see the
[styling table in the README](README.md#styling-hooks) — and all of the
`remodal-*` names are preserved. The ported theme does deviate from upstream
Remodal in eight places, each for a WCAG or correctness reason, and each
revertible. They are listed in [CHANGELOG.md](CHANGELOG.md#fixed); the ones
most likely to be visible in a 2.x app:

- Confirm and cancel are darker (`#2e7d32` / `#c62828`) so white label text
  reaches AA contrast. Set `--ember-remodal-confirm-background` and
  `--ember-remodal-cancel-background` back to `#81c784` / `#e57373` (and the
  `-hover` variants to `#66bb6a` / `#ef5350`) for upstream fidelity.
- The dialog, card and buttons draw `:focus-visible` rings; upstream set
  `outline: none` on all of them.
- `@disableForeground`'s styling hangs off `ember-remodal-invisible` rather than
  the bare `invisible` class, which Bootstrap owns. `invisible` is still
  emitted, so 1.x/2.x CSS keyed on it still applies — but the addon's own rules
  no longer do.
- `.remodal-bg` blurring works again, as
  `html.remodal-is-locked .remodal-bg { filter: blur(3px) }`. One caveat that is
  new in 3.0: the `<dialog>` renders in place rather than being moved to the
  application root, so keep the modal's own markup **outside** the
  `.remodal-bg` subtree — an ancestor filter can apply to top-layer descendants
  and would blur the modal along with the page.

## Testing your upgrade

### `disableAnimationWhileTesting` — classic resolver only

The 2.x recipe still works, but only in an app using the classic
`ember-resolver`:

```js
// config/environment.js — classic-resolver apps only
if (environment === 'test') {
  ENV['ember-remodal'] = { disableAnimationWhileTesting: true };
}
```

A strict-resolver app registers no `config:environment` module at all, so the
addon cannot read it and the flag is silently inert. Use the published test
support instead — it works in both kinds of app:

```js
import { setupRemodal } from 'ember-remodal/test-support';

module('Integration | checkout', function (hooks) {
  setupRenderingTest(hooks);
  setupRemodal(hooks, { disableAnimation: true });
});
```

`setupRemodal(hooks)` is worth adding even without `disableAnimation`: the
document scroll lock is module-level state on `<html>` and `<body>`, outside
`#ember-testing`, so a test that ends mid-transition otherwise leaks it into
every test that follows. See
[the test-support reference in the README](README.md#testing).

### Animations are awaited automatically

The open/close animations are wrapped in `@ember/test-waiters`, so
`await click(…)` and `await settled()` already wait for them. Most suites can
drop their manual waits.

### Selector updates in tests

- `.remodal-overlay` → `dialog.remodal-wrapper::backdrop` (there is no element
  to select; assert on the dialog instead).
- `[data-remodal-id=…]` → `[data-test-id="modalWindow"]` or your own
  `@dataTestId`.
- With more than one modal rendered, use `remodalDialogs()` or scope the lookup:
  `remodalDialog('[data-test-id="my-modal"]')`.

## What stayed the same

- **Every component argument**: `title`, `text`, `confirmButton`,
  `cancelButton`, `openButton`, `openLink`, `linkButton`, `name`, `forService`,
  `dataTestId`, `modifier`, `modalClasses`, `buttonClasses`,
  `outerButtonClasses`, `innerButtonClasses`, `openButtonClasses`,
  `openLinkClasses`, `confirmButtonClasses`, `cancelButtonClasses`,
  `closeOnEscape`, `closeOnCancel`, `closeOnConfirm`, `closeOnOutsideClick`,
  `disableForeground`, `disableNativeClose`, `disableAnimation`, and the
  `options` hash — same names, same defaults. (`closeOnEscape` is now
  conditional; see above.)
- **The yielded block API**: `m.open`, `m.confirm`, `m.cancel` work as before,
  including portaling `m.open` out of the dialog.
- **The `remodal` service**: `open(name, opts?)` and `close(name)`, the same
  default name (`'ember-remodal'`), and the same persistent option overrides,
  merged cumulatively across calls exactly like 2.x's `setProperties`.
- **Option precedence**: `@options` wins over individual arguments, and
  `service.open()` overrides win over both — the order 2.x resolved options in.
  The five callbacks now take part in that resolution too, so
  `@options={{hash onConfirm=this.save}}` and `service.open('x', { onClose })`
  work again.
- **Promise resolution points**: `open()` and `close()` still resolve with the
  modal component once the animation finishes — and now they resolve reliably
  for interrupted and rapid open/close sequences
  ([#44](https://github.com/sethbrasile/ember-remodal/issues/44)). The promise
  *type* changed; see [RSVP](#rsvp-promises--native-promises) above.
- **CSS class names**: `remodal`, `remodal-wrapper`, the `remodal-is-*` state
  classes, `remodal-is-initialized`, `remodal-close`, `remodal-is-locked`,
  `remodal-bg`, and every `ember-remodal …` utility class.
- **`data-test-id` hooks**: `modalWindow`, `openButton`, `openLink`,
  `linkButton`, `confirmButton`, `cancelButton`, `nativeClose`, `title`, `text`,
  `yielded` — plus `modalWrapper`, which is new (2.x had no test hook on the
  wrapper).

## New in 3.0

- `m.isOpen` for lazy content, and `m.openAction` / `m.closeAction` /
  `m.confirmAction` / `m.cancelAction` for `{{on}}` on your own elements.
- `@onBeforeOpen` — return `false` to veto opening.
- `@ariaLabel` and `@closeButtonLabel`.
- A public tracked `state` property.
- **Stacked modals**: opening a modal from within another modal works naturally
  via the top layer, and the scroll lock is reference-counted across them.
- **`ember-remodal/test-support`**: `setupRemodal`, `resetRemodalScrollLock`,
  `setRemodalAnimationDisabled`, `remodalDialog`, `remodalDialogs`.
- Animations suppressed under `prefers-reduced-motion: reduce`, a
  `forced-colors: active` block, and the whole palette exposed as CSS custom
  properties.
- Full TypeScript types and Glint signatures, importable from `ember-remodal`.
