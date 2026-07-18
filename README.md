# ember-remodal

[![npm version](https://img.shields.io/npm/v/ember-remodal.svg)](https://www.npmjs.com/package/ember-remodal)

An intensely usable modal addon for Ember.js — now jQuery-free, built on the
native `<dialog>` element, with the same remodal look and feel.

Version 3 is a ground-up rewrite as a v2 addon in TypeScript. The jQuery
[remodal](https://github.com/vodkabears/Remodal) library is gone; the browser's
`<dialog>` element now provides the top layer, focus containment, and Escape
handling, while the classic remodal theme (dark backdrop, flat white card, 0.3s
zoom/fade) is ported verbatim. The public API — component arguments, yielded
buttons, the `remodal` service, promise semantics, and the `remodal-*` CSS
classes — is preserved. Upgrading from 2.x? See the
[migration guide](MIGRATION.md).

## Compatibility

| ember-remodal | Ember                                                                                        |
| ------------- | -------------------------------------------------------------------------------------------- |
| 3.x           | Ember >= 5.8 — any Embroider/Vite app, or classic builds via `@embroider/compat`              |
| 2.x           | Legacy line for older Ember (classic builds, jQuery-based) — no longer maintained             |

## Installation

```sh
ember install ember-remodal
# or
pnpm add ember-remodal
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

In loose-mode (classic) templates the component is available as
`<EmberRemodal />` / `{{ember-remodal}}` without an import.

### Block form with yielded buttons

The block receives a hash (conventionally `m`) of button components and
actions, so you bring your own markup:

```gjs
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

- `m.open` — a trigger component. Even though it is declared inside the block,
  it renders *outside* the `<dialog>` (it is portaled next to the component),
  so it is always visible and clickable.
- `m.confirm` / `m.cancel` — close the modal with reason `'confirmation'` /
  `'cancellation'` and fire `@onConfirm` / `@onCancel`.
- `m.isOpen` — `true` while the modal is opening or open. Use it to defer
  expensive content: `{{#if m.isOpen}}…{{/if}}`.
- `m.openAction`, `m.closeAction`, `m.confirmAction`, `m.cancelAction` — plain
  zero-argument functions, handy with the `{{on}}` modifier on your own
  elements.

### As a service

Render one modal with `@forService={{true}}` (typically in your application
template), then drive it from anywhere:

```gjs
<EmberRemodal @forService={{true}} @name="wat" />
```

```js
import Component from '@glimmer/component';
import { service } from '@ember/service';

export default class extends Component {
  @service remodal;

  openModal = () => {
    this.remodal.open('wat', { title: 'Hello' });
  };
}
```

`open(name, options?)` and `close(name)` return promises that resolve with the
modal component once the animation completes, so chaining works:

```js
this.remodal
  .open('wat')
  .then((modal) => doSomething())
  .then(() => this.remodal.close('wat'));
```

Options passed to `open()` override the rendered arguments and `@options`, and
merge into — rather than replace — any options set by a previous `open()`
call, so they persist across subsequent opens until the app tears the modal
down. Opening a `name` that is not currently rendered throws a helpful
assertion (in dev/test builds) or rejects the returned promise (in production,
where the assertion is stripped).

## Options

All options can be passed as individual arguments (`@title="Hi"`) or grouped in
an `@options` hash. The `@options` hash wins over individual arguments
(matching 2.x's `setProperties`-based precedence); options passed to
`service.open()` win over both.

| Option                 | Default                     | Description                                                                    |
| ---------------------- | --------------------------- | ------------------------------------------------------------------------------ |
| `title`                | —                           | Renders an `<h2>` in the modal                                                 |
| `text`                 | —                           | Renders a `<p>` in the modal                                                   |
| `confirmButton`        | —                           | Label; renders a confirm button (`remodal-confirm`)                            |
| `cancelButton`         | —                           | Label; renders a cancel button (`remodal-cancel`)                              |
| `openButton`           | —                           | Label; renders a `<button>` trigger                                            |
| `openLink`             | —                           | Label; renders an `<a>` trigger                                                |
| `linkButton`           | —                           | Legacy alias for an `<a>` trigger (takes precedence over the other two)        |
| `name`                 | `'ember-remodal'`           | Registry key for service usage; also added as a class on the modal card        |
| `forService`           | `false`                     | Registers this modal with the `remodal` service under `name`                   |
| `dataTestId`           | —                           | Sets `data-test-id` on the outer component span                                |
| `modifier`             | `''`                        | Extra class on both the wrapper and the card — remodal's theming hook          |
| `modalClasses`         | —                           | Extra classes for the modal card                                               |
| `buttonClasses`        | —                           | Extra classes for **all** rendered buttons                                     |
| `outerButtonClasses`   | —                           | Extra classes for trigger (outside) buttons                                    |
| `innerButtonClasses`   | —                           | Extra classes for confirm/cancel (inside) buttons                              |
| `openButtonClasses`    | —                           | Extra classes for the `openButton`                                             |
| `openLinkClasses`      | —                           | Extra classes for the `openLink`                                               |
| `confirmButtonClasses` | —                           | Extra classes for the confirm button                                           |
| `cancelButtonClasses`  | —                           | Extra classes for the cancel button                                            |
| `closeOnEscape`        | `true`                      | Close when Escape is pressed                                                   |
| `closeOnOutsideClick`  | `true`                      | Close when the backdrop (outside the card) is clicked                          |
| `closeOnConfirm`       | `true`                      | Close when confirm fires (`false` keeps it open, `@onConfirm` still fires)     |
| `closeOnCancel`        | `true`                      | Close when cancel fires                                                        |
| `disableForeground`    | `false`                     | Removes the card styling so content floats on the backdrop (lightbox style)    |
| `disableNativeClose`   | value of `disableForeground` | Hides the built-in × close button                                             |
| `disableAnimation`     | `false`                     | Skips the open/close animations                                                |

### Callbacks

Function arguments (in 2.x these were string action names):

| Argument        | Called                                                                                  |
| --------------- | --------------------------------------------------------------------------------------- |
| `@onBeforeOpen` | Before opening; return `false` to veto the open                                         |
| `@onOpen`       | After the opening animation completes                                                   |
| `@onClose`      | After closing; receives `'confirmation'`, `'cancellation'`, or `undefined` as the reason |
| `@onConfirm`    | When the confirm button (or `m.confirm` / `m.confirmAction`) fires                      |
| `@onCancel`     | When the cancel button (or `m.cancel` / `m.cancelAction`) fires                         |

## Styling and theming

The classic remodal class names are all preserved, so existing overrides keep
working: `remodal`, `remodal-wrapper`, `remodal-close`, `remodal-confirm`,
`remodal-cancel`, `remodal-is-locked`, and the state classes
`remodal-is-opening/opened/closing/closed`. The default theme (ported from
Remodal v1.1.1, MIT) ships with the addon and is applied automatically.

- To restyle a single modal, pass `@modifier="my-theme"` and target
  `.remodal.my-theme { … }` — plus
  `dialog.remodal-wrapper.my-theme::backdrop { … }` for the overlay.
- The overlay is now the dialog's `::backdrop` pseudo-element; override
  `dialog.remodal-wrapper::backdrop` to change it globally.
- Fine-grained class hooks: `modalClasses`, `buttonClasses`,
  `outerButtonClasses`, `innerButtonClasses`, and the per-button variants (see
  the options table).
- Custom open/close animations are recognized and awaited by `open()`/
  `close()` only if their CSS `@keyframes` name starts with `remodal-`
  (matching the built-in `remodal-opening-keyframes`, etc.). This is
  deliberate: animations on other elements inside your yielded content (a
  spinner, say) are ignored so they can't hang `open()`/`close()` forever.

### Disabling animations in tests

Animations are awaited through `@ember/test-waiters`, so `await click(…)` and
`await settled()` already wait for them — no configuration required. If you
still want to skip the 0.3s animations in your app's test suite:

```js
// config/environment.js
if (environment === 'test') {
  ENV['ember-remodal'] = { disableAnimationWhileTesting: true };
}
```

## Accessibility

- The modal is a native `<dialog>` opened with `showModal()`: it renders in the
  browser's top layer, traps focus while open, restores focus to the trigger on
  close, and handles Escape natively (intercepted so the closing animation
  still plays).
- Content outside the open dialog is inert to assistive technology, courtesy of
  the platform — no aria-hidden bookkeeping.
- The built-in close button is a real `<button>` with a `title`.
- All open/close animations are suppressed under
  `prefers-reduced-motion: reduce`.
- Some browsers (notably Chromium) may force-close a `<dialog>` if Escape is
  pressed twice in quick succession, as part of a built-in abuse-prevention
  guard — regardless of `@closeOnEscape={{false}}`. This is a platform
  limitation, not addon behavior; the modal's internal state stays consistent
  either way (`@onClose` still fires).

## Contributing

See the [Contributing](CONTRIBUTING.md) guide for details.

- `pnpm install` — install dependencies
- `pnpm start` — serve the demo app at http://localhost:4200
- `pnpm test` — run the test suite (headless Chrome)
- `pnpm lint` / `pnpm lint:fix` — lint everything
- `pnpm build` — build the addon

## License

This project is licensed under the [MIT License](LICENSE.md). The default theme
is ported from [Remodal](https://github.com/vodkabears/Remodal) by Ilya
Makarov, also MIT licensed.
