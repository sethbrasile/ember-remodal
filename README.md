# ember-remodal

[![npm version](https://img.shields.io/npm/v/ember-remodal.svg)](https://www.npmjs.com/package/ember-remodal)

An intensely usable modal addon for Ember.js — jQuery-free, built on the native
`<dialog>` element, with the same remodal look and feel.

Version 3 is a ground-up rewrite as a v2 addon in TypeScript. The jQuery
[Remodal](https://github.com/vodkabears/Remodal) library is gone; the browser's
`<dialog>` element now provides the top layer, focus containment, and Escape
handling, while the classic remodal theme (dark backdrop, flat white card, 0.3s
zoom/fade) is ported. The public API — component arguments, yielded buttons, the
`remodal` service, promise resolution points, and the `remodal-*` CSS classes —
is preserved. Upgrading from 2.x? Read the
[migration guide](MIGRATION.md); changes are listed in the
[changelog](CHANGELOG.md).

## Contents

- [Compatibility](#compatibility)
- [Installation](#installation)
- [Usage](#usage)
  - [Inline](#inline)
  - [Block form with yielded buttons](#block-form-with-yielded-buttons)
  - [As a service](#as-a-service)
- [Promises and state](#promises-and-state)
- [Options](#options)
- [Callbacks](#callbacks)
- [Styling and theming](#styling-and-theming)
  - [Styling hooks](#styling-hooks)
  - [Theming with custom properties](#theming-with-custom-properties)
  - [Per-modal themes with `@modifier`](#per-modal-themes-with-modifier)
  - [Custom animations](#custom-animations)
- [Testing](#testing)
- [Accessibility](#accessibility)
- [Development warnings](#development-warnings)
- [Contributing](#contributing)
- [License](#license)

## Compatibility

| ember-remodal | Ember                                                                        |
| ------------- | ---------------------------------------------------------------------------- |
| 3.x           | Ember >= 5.8 — any Embroider/Vite app, or classic builds via `@embroider/compat` |
| 2.x           | Legacy line for older Ember (classic builds, jQuery-based) — no longer maintained |

The 5.8 floor is exercised in CI: the `@embroider/try` matrix runs 5.8, 5.12,
6.4, 6.12, `latest`, `beta` and `alpha`, plus a floating-dependency job.

## Installation

3.0 is in beta and published under the `beta` dist-tag, so `ember-remodal@latest`
still resolves to the 2.x line:

```sh
pnpm add ember-remodal@beta
```

(`npm install ember-remodal@beta` / `yarn add ember-remodal@beta` work the same
way. `ember install ember-remodal` would install 2.18.0.)

The theme is imported by the component, so there is nothing to add to your
build. If you want to control when it loads, import it yourself:

```js
import 'ember-remodal/styles/ember-remodal.css';
```

## Usage

### Inline

The component can render everything for you, including the trigger:

```gjs
import EmberRemodal from 'ember-remodal/components/ember-remodal';

<template>
  <EmberRemodal
    @openButton="Open modal"
    @title="Hello"
    @text="Some text content."
    @confirmButton="Sounds good"
    @cancelButton="No thanks"
    @onConfirm={{this.save}}
  />
</template>
```

In loose-mode (classic) templates the component resolves as `<EmberRemodal />` /
`{{ember-remodal}}` with no import.

### Block form with yielded buttons

The block receives a hash (conventionally `m`) of button components and actions,
so you bring your own markup:

```gjs
import EmberRemodal from 'ember-remodal/components/ember-remodal';

<template>
  <EmberRemodal @title="Custom content" as |m|>
    <m.open>
      <button type="button">Open</button>
    </m.open>

    <p>Anything you like: forms, images, other components…</p>

    <m.cancel><button type="button" class="remodal-cancel">Cancel</button></m.cancel>
    <m.confirm><button type="button" class="remodal-confirm">Confirm</button></m.confirm>
  </EmberRemodal>
</template>
```

- `m.open` — a trigger component. Even though it is declared inside the block, it
  renders *outside* the `<dialog>` (it is portaled next to the component), so it
  is always visible and clickable.
- `m.confirm` / `m.cancel` — close the modal with reason `'confirmation'` /
  `'cancellation'` and fire `@onConfirm` / `@onCancel`.
- `m.isOpen` — `true` while the modal is opening, open, or closing. Use it to
  defer expensive content: `{{#if m.isOpen}}…{{/if}}`. It stays `true` through
  the closing animation so lazy content does not vanish mid-transition.
- `m.openAction`, `m.closeAction`, `m.confirmAction`, `m.cancelAction` — plain
  zero-argument functions, for the `{{on}}` modifier on your own elements.

`m.open`, `m.confirm` and `m.cancel` render a click-delegating `<span>`, so
**their blocks must contain your own focusable control.**
`<m.open>Open modal</m.open>` works with a mouse but is unreachable by keyboard;
use `<m.open><button type="button">Open modal</button></m.open>`. The addon warns
in development if it finds nothing focusable in the block.

### As a service

Render one modal with `@forService={{true}}` (typically in your application
template), then drive it from anywhere:

```gjs
import EmberRemodal from 'ember-remodal/components/ember-remodal';

<template>
  <EmberRemodal @forService={{true}} @name="wat" />
</template>
```

```js
import Component from '@glimmer/component';
import { service } from '@ember/service';

export default class extends Component {
  @service remodal;

  openModal = () => {
    // Rejects if no modal named "wat" is currently rendered, so handle it
    // rather than leaving the promise floating.
    this.remodal.open('wat', { title: 'Hello' }).catch(console.error);
  };
}
```

Give each service-driven modal its own `@name`. Two modals registered under one
name is last-writer-wins — the most recently rendered one answers `open()` and
`close()` — and the addon warns about it in development. Registrations are
stacked rather than overwritten, so destroying the winner uncovers the modal it
was shadowing instead of leaving the name unreachable.

## Promises and state

`open(name, options?)` and `close(name)` return native promises that resolve with
the modal component once the animation completes, so chaining works:

```js
this.remodal
  .open('wat')
  .then((modal) => doSomething(modal))
  .then(() => this.remodal.close('wat'));
```

Both **reject** when no modal is currently rendered under that name, in every
build. `open()` also rejects if the modal's `<dialog>` never renders or the
browser refuses `showModal()`.

Options passed to `open()` override the rendered arguments and `@options`, and
merge into — rather than replace — the options set by a previous `open()` call,
so they persist until replaced.

The component exposes a tracked `state` property:
`'closed' | 'opening' | 'opened' | 'closing'`. It is the replacement for 2.x's
`modal.getState()`, and `m.isOpen` is the same information yielded into the
template (`true` for anything other than `'closed'`).

## Options

All options can be passed as individual arguments (`@title="Hi"`) or grouped in
an `@options` hash. The `@options` hash wins over individual arguments (matching
2.x's `setProperties`-based precedence); options passed to `service.open()` win
over both. That includes the callbacks, so
`@options={{hash onConfirm=this.save}}` and `service.open('x', { onClose })` both
work.

### Content

| Option             | Default          | Description                                                                                        |
| ------------------ | ---------------- | -------------------------------------------------------------------------------------------------- |
| `title`            | —                | Renders an `<h2>`, and names the dialog via `aria-labelledby`                                       |
| `text`             | —                | Renders a `<p>`                                                                                     |
| `ariaLabel`        | —                | Accessible name for a modal with no visible `@title`. Wins over `@title` when both are given         |
| `closeButtonLabel` | `'Close Modal'`  | `aria-label` and `title` for the built-in close button. An option so it can be translated            |

### Triggers and buttons

| Option          | Default | Description                                                             |
| --------------- | ------- | ----------------------------------------------------------------------- |
| `openButton`    | —       | Label; renders a `<button>` trigger                                     |
| `openLink`      | —       | Label; renders an `<a>` trigger                                         |
| `linkButton`    | —       | Legacy alias for an `<a>` trigger (takes precedence over the other two)  |
| `confirmButton` | —       | Label; renders a confirm button (`remodal-confirm`)                     |
| `cancelButton`  | —       | Label; renders a cancel button (`remodal-cancel`)                       |

### Identity

| Option       | Default           | Description                                                             |
| ------------ | ----------------- | ----------------------------------------------------------------------- |
| `name`       | `'ember-remodal'` | Registry key for service usage; also added as a class on the modal card |
| `forService` | `false`           | Registers this modal with the `remodal` service under `name`            |
| `dataTestId` | —                 | Sets `data-test-id` on the outer component element                      |

### Class hooks

| Option                 | Default | Description                                                          |
| ---------------------- | ------- | -------------------------------------------------------------------- |
| `modifier`             | `''`    | Extra class on both the `<dialog>` and the card — remodal's theming hook |
| `modalClasses`         | —       | Extra classes for the modal card                                     |
| `buttonClasses`        | —       | Extra classes for **all** rendered buttons                           |
| `outerButtonClasses`   | —       | Extra classes for trigger (outside) buttons and links                |
| `innerButtonClasses`   | —       | Extra classes for confirm/cancel (inside) buttons                    |
| `openButtonClasses`    | —       | Extra classes for the `openButton`                                   |
| `openLinkClasses`      | —       | Extra classes for the `openLink`                                     |
| `confirmButtonClasses` | —       | Extra classes for the confirm button                                 |
| `cancelButtonClasses`  | —       | Extra classes for the cancel button                                  |

### Behavior

| Option                | Default                      | Description                                                                                                 |
| --------------------- | ---------------------------- | ----------------------------------------------------------------------------------------------------------- |
| `closeOnEscape`       | `true`                       | Close when Escape is pressed. `false` is honored only while the modal contains a focusable control — see [Accessibility](#accessibility) |
| `closeOnOutsideClick` | `true`                       | Close when the backdrop (outside the card) is clicked. Requires the press *and* the release to land there    |
| `closeOnConfirm`      | `true`                       | Close when confirm fires (`false` keeps it open, `@onConfirm` still fires)                                   |
| `closeOnCancel`       | `true`                       | Close when cancel fires                                                                                     |
| `disableForeground`   | `false`                      | Removes the card styling so content floats on the backdrop (lightbox style). Pass `@ariaLabel` with it       |
| `disableNativeClose`  | value of `disableForeground` | Hides the built-in × close button                                                                           |
| `disableAnimation`    | `false`                      | Skips the open/close animations                                                                             |

## Callbacks

Function arguments (in 2.x these were string action names):

| Argument        | Called                                                                                   |
| --------------- | ---------------------------------------------------------------------------------------- |
| `@onBeforeOpen` | Before opening; return `false` to veto the open                                          |
| `@onOpen`       | After the opening animation completes                                                    |
| `@onClose`      | After closing; receives `'confirmation'`, `'cancellation'`, or `undefined` as the reason  |
| `@onConfirm`    | When the confirm button (or `m.confirm` / `m.confirmAction`) fires                        |
| `@onCancel`     | When the cancel button (or `m.cancel` / `m.cancelAction`) fires                           |

`@onClose` also fires when a modal is destroyed while open — a route transition,
an `{{#if}}` flipping — so cleanup keyed on it runs in that case too.

## Styling and theming

The classic remodal class names are all preserved: `remodal`, `remodal-wrapper`,
`remodal-close`, `remodal-confirm`, `remodal-cancel`, `remodal-is-locked`,
`remodal-bg`, `remodal-is-initialized`, and the state classes
`remodal-is-opening` / `-opened` / `-closing` / `-closed`. The default theme
(ported from Remodal v1.1.1, MIT) ships with the addon and is applied
automatically. It is not a pixel-for-pixel copy: it deviates from upstream in
eight places, all for accessibility or layout correctness, and each one is
revertible from your own stylesheet. They are listed in
[CHANGELOG.md](CHANGELOG.md#fixed) and in the header comment of
`src/styles/ember-remodal.css`.

Apply `remodal-bg` to the page content you want blurred while a modal is open.
One caveat that is new in 3.0: the `<dialog>` renders where you invoke the
component rather than being moved to the application root, so keep the modal
outside the `.remodal-bg` subtree — an ancestor filter can apply to top-layer
descendants and would blur the modal along with the page.

### Styling hooks

Every part of the modal is addressable, and every one of these selectors carried
over from 2.x unchanged:

| Part                                | Selector                             |
| ----------------------------------- | ------------------------------------ |
| Modal card (the "window")           | `.ember-remodal.window`              |
| A named modal's card                | `.ember-remodal.<name>.window`       |
| Open button                         | `.ember-remodal.open.button`         |
| Open link / link button             | `.ember-remodal.link.text`           |
| Confirm button                      | `.ember-remodal.confirm.button`      |
| Cancel button                       | `.ember-remodal.cancel.button`       |
| Built-in close button               | `.ember-remodal.native.close`        |
| Title                               | `.ember-remodal.title.text`          |
| Text                                | `.ember-remodal.paragraph.text`      |
| Content yielded in block form       | `.ember-remodal.yielded.content`     |
| All rendered buttons                | `.ember-remodal.button`              |
| Buttons inside the modal            | `.ember-remodal.inner.button`        |
| Buttons outside the modal           | `.ember-remodal.outer.button`        |
| Overlay (2.x: `.remodal-overlay`)   | `dialog.remodal-wrapper::backdrop`   |

The one change is the last row: the overlay is now the dialog's `::backdrop`
pseudo-element, so there is no `.remodal-overlay` element to select. Note also
that `.ember-remodal.outer.button` matches the `@openButton` only — the `@openLink`
and `@linkButton` forms render as `.ember-remodal.outer.link.text`.

### Theming with custom properties

Every colour in the theme is a CSS custom property, declared on `:where(html)`.
That selector carries **zero specificity**, so any declaration of yours wins
regardless of stylesheet order — which matters, because the theme ships as a
side-effect import whose position in your bundle the addon cannot control. It is
also the only route to `::backdrop` from a class on the card: `@modalClasses`
lands inside the dialog, and `::backdrop` inherits only from the dialog itself.

| Property                                    | Default                   |
| ------------------------------------------- | ------------------------- |
| `--ember-remodal-background`                | `#fff`                    |
| `--ember-remodal-color`                     | `#2b2e38`                 |
| `--ember-remodal-color-scheme`              | `light`                   |
| `--ember-remodal-overlay`                   | `rgba(43, 46, 56, 0.9)`   |
| `--ember-remodal-close-color`               | `#767981`                 |
| `--ember-remodal-close-color-hover`         | `#2b2e38`                 |
| `--ember-remodal-button-color`              | `#fff`                    |
| `--ember-remodal-confirm-background`        | `#2e7d32`                 |
| `--ember-remodal-confirm-background-hover`  | `#1b5e20`                 |
| `--ember-remodal-cancel-background`         | `#c62828`                 |
| `--ember-remodal-cancel-background-hover`   | `#b71c1c`                 |
| `--ember-remodal-focus-ring`                | `#2b2e38`                 |
| `--ember-remodal-focus-ring-inverse`        | `#fff`                    |

`--ember-remodal-color-scheme` sets `color-scheme` on the card, so form controls,
selects and scrollbars inside a dark modal render dark.

The card and the three buttons draw their focus ring as a pair — a
`--ember-remodal-focus-ring` outline plus a `--ember-remodal-focus-ring-inverse`
halo — so one of them clears 3:1 against the surface whichever way you theme it.
The `<dialog>` itself (focused by `showModal()` when there is no other focusable
control, e.g. under `@disableForeground`) draws an inset ring in the inverse
colour alone, against the backdrop. Set both properties when you change the
card's background.

A dark theme applied globally:

```css
:root {
  --ember-remodal-background: #1b1f2a;
  --ember-remodal-color: #e8eaf2;
  --ember-remodal-color-scheme: dark;
  --ember-remodal-close-color: #8b91a5;
  --ember-remodal-close-color-hover: #e8eaf2;
  --ember-remodal-focus-ring: #e8eaf2;
  --ember-remodal-focus-ring-inverse: #10131a;
}
```

To restore upstream Remodal's original confirm/cancel colours (which fail WCAG
1.4.3 AA against their white labels — that is why they were changed):

```css
:root {
  --ember-remodal-confirm-background: #81c784;
  --ember-remodal-confirm-background-hover: #66bb6a;
  --ember-remodal-cancel-background: #e57373;
  --ember-remodal-cancel-background-hover: #ef5350;
}
```

### Per-modal themes with `@modifier`

`@modifier="my-theme"` puts the class on both the `<dialog>` and the card, so you
can scope a theme to one modal. Setting the custom properties on the card cascades
them to everything inside it:

```hbs
<EmberRemodal @modifier="midnight" @openButton="Open" @title="Midnight" />
```

```css
.remodal.midnight {
  --ember-remodal-background: #1b1f2a;
  --ember-remodal-color: #e8eaf2;
  --ember-remodal-color-scheme: dark;
  --ember-remodal-focus-ring: #e8eaf2;
  --ember-remodal-focus-ring-inverse: #10131a;

  border-radius: 12px;
}

/* ::backdrop does not inherit from the card, so scope it to the dialog. */
dialog.remodal-wrapper.midnight::backdrop {
  background: rgba(10, 12, 20, 0.85);
}
```

That is exactly how the demo app's `demo-midnight` theme is written — see
`demo-app/styles.css` for the full worked example.

Finer-grained hooks are available as options: `modalClasses`, `buttonClasses`,
`outerButtonClasses`, `innerButtonClasses`, and the per-button variants (see
[Class hooks](#class-hooks)).

### Custom animations

Custom open/close animations are recognized and awaited by `open()` / `close()`
only if their CSS `@keyframes` name starts with `remodal-` (matching the built-in
`remodal-opening-keyframes` and friends) and they target the `<dialog>`, its
`::backdrop`, or the `.remodal` card. This is deliberate: animations on other
elements inside your yielded content — a spinner, say — are ignored, so an
infinite animation cannot hang `open()` / `close()` forever.

All built-in animations and transitions are suppressed under
`prefers-reduced-motion: reduce`.

## Testing

Animations are wrapped in `@ember/test-waiters`, so `await click(…)` and
`await settled()` already wait for them — no configuration required.

Beyond that, the addon ships a test-support entry point:

```js
import { setupRemodal } from 'ember-remodal/test-support';

module('Integration | checkout', function (hooks) {
  setupRenderingTest(hooks);
  setupRemodal(hooks, { disableAnimation: true });
});
```

**Add `setupRemodal(hooks)` even if you do not want `disableAnimation`.** The
document scroll lock is module-level state — a class on `<html>` and an inline
style on `<body>`, both outside `#ember-testing` and `#qunit-fixture`. Neither
QUnit's fixture reset nor `setupRenderingTest`'s teardown can clean it up, so a
test that ends with a transition still in flight leaks a locked document into
every test that follows. `setupRemodal` force-resets it before and after each
test, and fails the test that leaked rather than letting the failure cascade.

| Export                                 | Purpose                                                                                                          |
| -------------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| `setupRemodal(hooks, options?)`        | Installs the reset/leak-detection hooks. `options.disableAnimation` turns animations off for the module            |
| `resetRemodalScrollLock()`             | Force-releases the scroll lock. Only needed if you manage QUnit hooks yourself                                    |
| `setRemodalAnimationDisabled(flag)`    | Turns animations off (or back on) process-wide. Prefer the `setupRemodal` option, which also unwinds it            |
| `remodalDialog(scope?)`                | The one rendered modal `<dialog>`. Throws when there is none, or when several are rendered and no scope was given  |
| `remodalDialogs(scope?)`               | Every rendered modal `<dialog>`, in document order — the helper to reach for with stacked modals                   |

The exported types are `RemodalTestHooks`, `RemodalTestAssert` and
`SetupRemodalOptions`. The module deliberately imports neither `qunit` nor
`@ember/test-helpers` — the hook and assert types are structural, and QUnit's own
`NestedHooks` and `Assert` satisfy them — so it pulls no undeclared package into
your resolution.

With more than one modal on screen, scope the lookup rather than taking the
first match:

```js
const dialog = remodalDialog('[data-test-id="confirm-delete"]');
```

Any selector or element works as a scope; `@dataTestId="confirm-delete"` on the
component is the tidiest way to create one.

### The classic-resolver fallback

The 2.x `config/environment` flag still works, but **only in apps using the
classic `ember-resolver`**:

```js
// config/environment.js — classic-resolver apps only
if (environment === 'test') {
  ENV['ember-remodal'] = { disableAnimationWhileTesting: true };
}
```

A strict-resolver app registers no `config:environment` module at all, so the
addon cannot read it and the flag is silently inert. `setupRemodal(hooks, {
disableAnimation: true })` works in both kinds of app and is the supported path.

## Accessibility

- The modal is a native `<dialog>` opened with `showModal()`: it renders in the
  browser's top layer, contains focus while open, and handles Escape natively
  (intercepted so the closing animation still plays).
- Content outside the open dialog is inert to assistive technology, courtesy of
  the platform — no `aria-hidden` bookkeeping.
- **Focus restoration** is the platform's: `showModal()` snapshots the focused
  element and the browser restores it when the dialog closes. Two caveats worth
  knowing. It lands when the closing animation finishes — roughly 300ms after
  `close()` is called, not immediately. And it restores whatever was focused at
  open time, which is not reliably the trigger: Safari does not focus a
  `<button>` on click, so the snapshot is frequently `<body>`. If focus placement
  matters to your flow, set it yourself in `@onClose`.
- **The dialog needs an accessible name.** `showModal()` supplies
  `role="dialog"` and implicit `aria-modal` but no name. `@title` provides one
  (the `<h2>` gets a generated id and the dialog an `aria-labelledby`); when
  there is no visible title — a `@disableForeground` overlay, a block-only modal
  — pass `@ariaLabel`. Opening with neither warns in development.
- **The built-in close button** is a real `<button>` carrying both `aria-label`
  and `title`, defaulting to `'Close Modal'` and settable with
  `@closeButtonLabel`. The `title` alone was not enough: the visible × comes
  from `.remodal-close::before`, and pseudo-element content participates in
  name-from-contents, which outranks `title` — so the button announced as
  "times, button". The CSS now also uses the alt-text form
  `content: "\00d7" / ""` to keep the glyph out of the name computation
  entirely.
- **The yielded `m.open` / `m.confirm` / `m.cancel` blocks must contain a
  focusable control** — they render a click-delegating `<span>`. See
  [Block form](#block-form-with-yielded-buttons).
- **`@closeOnEscape={{false}}` is conditional.** It is honored only while the
  modal contains some focusable control. With none — no close button, nothing
  focusable in your content — Escape closes the modal anyway, because
  `showModal()` makes focus containment real and the alternative is an
  inescapable keyboard trap (WCAG 2.1.2, Level A). A development warning
  explains it at open time. This is not dev-only behavior: development and
  production must not disagree about whether a modal can be escaped.
- **Escape can force-close a modal regardless of `@closeOnEscape={{false}}`.**
  The addon calls `preventDefault()` on the dialog's `cancel` event, but in
  browsers implementing the HTML close-watcher algorithm that event is
  dispatched *non-cancelable* when the window has no history-action activation.
  For a modal the user opened by clicking, that means a quick second Escape can
  force-close it; for a modal opened programmatically with no preceding user
  gesture, the *first* Escape can. This is a platform behavior, not addon
  behavior, and the modal's state stays consistent either way — `@onClose`
  still fires.
- The default confirm and cancel colours meet WCAG 1.4.3 AA against their white
  labels (5.13:1 and 5.62:1); upstream Remodal's did not.
- Focus is drawn with `:focus-visible` rings on the dialog, the card and all
  three buttons. Upstream set `outline: none` on all of them.
- A `forced-colors: active` block keeps confirm and cancel distinguishable in
  Windows High Contrast, where their backgrounds are overridden, by giving cancel
  a dashed border.
- All open/close animations and colour transitions are suppressed under
  `prefers-reduced-motion: reduce`.

## Development warnings

These are `@ember/debug` warnings, stripped from production builds. Each can be
filtered by id with `registerWarnHandler`.

| Id                                                  | Fires when                                                                                     |
| --------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| `ember-remodal.modal-without-accessible-name`        | A modal is opened with neither `@title` nor `@ariaLabel`                                        |
| `ember-remodal.no-keyboard-exit`                     | A modal is opened with `@closeOnEscape={{false}}` and contains no focusable control              |
| `ember-remodal.er-button-without-focusable-content`  | An `<m.open>` / `<m.confirm>` / `<m.cancel>` block contains no focusable control                 |
| `ember-remodal.duplicate-service-name`               | Two `@forService` modals register under the same `@name` (the newest wins until it is destroyed) |
| `ember-remodal.close-called-on-uninitialized-modal`  | `close()` is called on a modal that has never been opened. Harmless; the promise resolves         |

## Contributing

See the [Contributing](CONTRIBUTING.md) guide for details.

- `pnpm install` — install dependencies
- `pnpm start` — serve the demo app (Vite prints the URL; http://localhost:5173
  by default)
- `pnpm test` — build the addon, link it into `node_modules`, then run the suite
  in headless Chrome
- `pnpm lint` / `pnpm lint:fix` — lint everything
- `pnpm build` — build the addon, including declarations

## License

This project is licensed under the [MIT License](LICENSE.md). The default theme
is ported from [Remodal](https://github.com/vodkabears/Remodal) by Ilya Makarov,
also MIT licensed; Remodal's copyright and permission notice are reproduced in
[LICENSE.md](LICENSE.md#third-party-licenses).
