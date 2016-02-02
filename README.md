# ember-remodal
[![Build Status](https://travis-ci.org/sethbrasile/ember-remodal.svg?branch=master)](https://travis-ci.org/sethbrasile/ember-remodal) [![npm version](https://badge.fury.io/js/ember-remodal.svg)](http://badge.fury.io/js/ember-remodal) [![Code Climate](https://codeclimate.com/github/sethbrasile/ember-remodal/badges/gpa.svg)](https://codeclimate.com/github/sethbrasile/ember-remodal) [![Dependencies](https://david-dm.org/sethbrasile/ember-remodal.svg)](https://david-dm.org/sethbrasile/ember-remodal) [![Test Coverage](https://codeclimate.com/github/sethbrasile/ember-remodal/badges/coverage.svg)](https://codeclimate.com/github/sethbrasile/ember-remodal/coverage) [![Ember Observer Score](http://emberobserver.com/badges/ember-remodal.svg)](http://emberobserver.com/addons/ember-remodal)

*This README is up-to-date and accurate as of ember-remodal v0.0.19*

There are many modal addons for Ember, but most of them (in my experience) are
only useful in a very specific situation. Often, when building large apps, you
may need flexibility in your modals. Sometimes you just want a simple
informational modal triggered by a button press. Other times, you may need to
use a modal as a loading state, programmatically closing the modal when loading
has finished.

This addon aims to be usable in a variety of situations. Also, there weren't any
[remodal](http://vodkabears.github.io/remodal/) ember addons, so I thought I'd
write one :D

## Compatibility
ember-remodal is compatible with Ember 1.13.x and up and is tested against:
- 1.13.x
- release (2.3.0 as of v0.0.19)
- beta
- canary

## Installation
`ember install ember-remodal`

## Usage

### Included Components
- `ember-remodal`: This is the base component for ember-remodal. This
component renders and controls a modal in your application. Example:

  ```hbs
    {{ember-remodal openButton='Open!' text='Text inside a modal.'}}
  ```

- `er-open-button`: Placed in the block of an `ember-remodal`, this optional
component allows you to specify your own html to act as the "open button" for a
modal.

- `er-cancel-button`: Placed in the block of an `ember-remodal`, this optional
component allows you to specify your own html to act as the "cancel button" for
a modal.

- `er-confirm-button`: Placed in the block of an `ember-remodal`, this optional
component allows you to specify your own html to act as the "confirm button" for
a modal.

Example:

```hbs
  {{#ember-remodal}}
    <p>This text will show up inside the modal</p>

    {{#er-open-button}}
      <!-- You can put anything you want in here
      and it will render OUTSIDE the modal, opening
      the modal when clicked and fire 'onOpen' -->
    {{/er-open-button}}

    <p>This text will also show up inside the modal</p>

    {{#er-cancel-button}}
      <!-- You can put anything you want in here
      and it will render inside the modal, closing
      the modal when clicked and fire 'onCancel' -->

      <button>Click to cancel!</button>
    {{/er-cancel-button}}

    {{#er-confirm-button}}
      <!-- You can put anything you want in here
      and it will render inside the modal, closing
      the modal when clicked and fire 'onConfirm' -->

      <button>Click to confirm!</button>
    {{/er-confirm-button}}
  {{/ember-remodal}}
```

### Simplest Use-Case

Apply the `remodal-bg` class to anything on your page that you would like blurred
while the modal is open. A common pattern would be to apply this class to a `div`
that is wrapping your entire application. This is completely optional, this modal
will work (and look) fine without this step.

#### Inline Form

```hbs
{{ember-remodal
  openButton='Open Modal'
  confirmButton='OK'
  title='A Title!'
  text='lorem ipsum dolar sit amet'
}}
```

#### Block Form

A modal can be used the same way as described above, but in block form.
This will display anything contained in the block, inside the modal.
Note that the `title` and `text` properties still work. Both will be displayed
above the yielded content from the block.

```hbs
{{#ember-remodal openButton='Open'}}
  <!-- Any content you want displayed in the modal! -->
{{/ember-remodal}}
```

### Options as a hash

In order to keep your templates clean, you may pass all the modal's options in
as a single hash called `options`.

Controller or Component:

```js
export default Ember.Whatever.extend({
  modalOptions: {
    openButton: 'Open Modal',
    confirmButton: 'OK',
    title: 'A Title!',
    text: 'lorem ipsum dolar sit amet'
  }
});
```

Template:

```hbs
{{ember-remodal options=modalOptions}}
```

### Programmatically Opening or Closing

Please see the section on [using ember-remodal as a service][1] for more information on
programmatically opening or closing a modal.

### Action Hooks

- `onOpen` is called when a modal has been opened
- `onClose` is called when a modal has been closed for **any** reason
- `onConfirm` is called when a modal has been closed via it's `confirm` button
- `onCancel` is called when a modal has been closed via it's `cancel` button

Template:

```hbs
{{ember-remodal
  openButton='Open'
  onClose='someCloseAction'
  onOpen='someOpenAction'
}}
```

Controller, Route or Component:

```js
actions: {
  someOpenAction() {
    console.log('The modal was opened!');
  },

  someCloseAction() {
    console.log('The modal was closed!');
  }
}
```

### Using ember-remodal as a service

By setting a modal's `forService` property to `true`, the modal will register
itself with the application-wide `remodal` service.

```hbs
{{ember-remodal forService=true}}
```

*You can place a service modal anywhere in your application, but keep in mind
that it must currently be rendered in order for your service to use it.*

You can then access the modal via the `remodal` service throughout your
application:

```js
export default Ember.Whatever.extend({
  remodal: Ember.inject.service(),

  actions: {
    openModal() {
      this.get('remodal').open();
    }
  }
});
```

Options can be set directly on the `remodal` service, or they can be passed in
to the `open` call:

```js
export default Ember.Whatever.extend({
  remodal: Ember.inject.service(),

  actions: {
    openModal() {
      this.get('remodal').open({
        title: 'Modal',
        text: 'Here is some text.'
      });
    }
  }
});
```

OR

```js
export default Ember.Whatever.extend({
  remodal: Ember.inject.service(),

  actions: {
    openModal() {
      const modal = this.get('remodal');

      modal.setProperties({
        title: 'Modal',
        text: 'Here is some text'
      });

      modal.open();
    }
  }
});
```

#### Named Service Modals

A modal that has been registered with the `remodal` service can be named,
allowing you to have multiple service modals, each with their own use, styling,
etc.. to exist at the same time:

```hbs
{{ember-remodal forService=true name='modal1'}}
{{ember-remodal forService=true name='modal2'}}
```

Named service modals are just like un-named service modals, except that you
refer to them by name:

*An "un-named" service modal is not actually "un-named", it just uses the default
name, `modal`.*

```js
export default Ember.Whatever.extend({
  remodal: Ember.inject.service(),

  someFunction() {
    this.get('remodal').open('modal1');
  }
});
```

OR

```js
export default Ember.Whatever.extend({
  remodal: Ember.inject.service(),

  someFunction() {
    this.get('remodal.modal2').open();
  }
});
```

#### Closing Service Modals

`close` works just like `open`, except that the only argument that it accepts is
the name of a named service modal. To close an un-named service modal, call
`close` with no arguments, or with the name `modal`.

##### Un-named:

```js
export default Ember.Whatever.extend({
  remodal: Ember.inject.service(),

  actions: {
    closeModal() {
      this.get('remodal').close();
    }
  }
});
```

##### Named:

```js
export default Ember.Whatever.extend({
  remodal: Ember.inject.service(),

  actions: {
    closeModal() {
      this.get('remodal').close('modal1');
    }
  }
});
```

### Promises

A modal's `open` and `close` methods return promises. The promise resolves when
remodal's [corresponding event](https://github.com/VodkaBears/Remodal#events)
fires. If `disableAnimation` is `true`, this happens *near* instantly, otherwise the
promise will resolve after css animations for the given action are complete.

```js
export default Ember.Whatever.extend({
  remodal: Ember.inject.service(),

  actions: {
    openModal() {
      this.get('remodal').open('some-modal').then((modal) => {
        // "modal" here is the 'some-modal' instance
        // which is just an Ember.Object
        console.log(`${modal.get('name')} was opened!`);
      });
    },

    closeModal() {
      this.get('remodal').close('some-modal').then((modal) => {
        console.log(`${modal.get('name')} was closed!`);
      });
    },
  }
});
```

### Options

#### Remodal Options
These [remodal options](https://github.com/VodkaBears/Remodal#options) are
supported:

- `closeOnOutsideClick` defaults to `true`
- `closeOnEscape` defaults to `true`
- `closeOnCancel` defaults to `true`
- `closeOnConfirm` defaults to `true`
- `modifier` defaults to an empty string
- `hashTracking` defaults to `false` - You probably want to leave this one alone.
It affects Ember's routes/browser-history. It's there if you want to mess.

#### Options Specific to this addon:

##### Button Options

Providing `string` values to these will enable the corresponding button and set
it's label value to the value provided. There are no default values. If a value
is not provided, that button will not show up.

- `openButton`: Shows up outside of the modal, allowing a user to click and open
the modal.

- `openLink`: Just like `openButton`, but rendered as an `a` tag instead of a
`button`.

- `confirmButton`: Shows up inside the modal, toward the bottom. With it's
default setup, when a user clicks this button, the component will:

  1. Fire it's `onConfirm` action.
  2. Close the modal.
  3. Fire it's `onClose` action.

  `closeOnConfirm` can be set to `false` which will keep steps 2 and 3 from
  taking place.

- `cancelButton`: Exactly the same as `confirmButton`, but `onCancel` is fired
instead of `onConfirm`. `closeOnCancel` can also be set to `false`.

- `buttonClasses`: If provided, this string value is added to the `class`
attribute on all built-in buttons: `confirmButton`, `openLink`, `confirmButton`,
and `cancelButton`.

- `outerButtonClasses`: If provided, this string value is added to the `class`
attribute on the built-in `openButton` and `openLink`.

- `innerButtonClasses`: If provided, this string value is added to the `class`
attribute on the built-in `confirmButton` and the `cancelButton`.

**Button Booleans**

- `disableNativeClose`: If `true`, this keeps the little `x` button from
appearing in the top left corner of the modal.

*Note on close events*: `remodal` doesn't currently offer a hook to allow for
`onNativeClose` or `onOverlayClose` actions, but `onClose` is available and
fires when a modal closes for any reason.

##### Style Options

- `modalClasses`: If set, this string value will be added to the classes on the
main modal window.

##### Functionality Options

- `closeOnOutsideClick`: Default is `true`, which allows the user to click the
dark overlay outside the modal window to close the modal.

- `closeOnEscape`: Default is `true`, which allows the user to hit the `escape`
key on their keyboard to close the modal.

- `disableForeground`: If `true`, this causes the white box surrounding the modal
content to be transparent, and switches the default text color from
`black` to `white`. When combined with `closeOnOutsideClick: false` and
`closeOnEscape: false`, this allows one to use the modal as an un-exitable
overlay, such as a `loading state`. By default, setting this option to true
also sets `disableNativeClose` to `true`, but `disableNativeClose` can be
explicitly set back to `false` if you prefer.

- `disableAnimation`: If `true`, this disables remodal's opening/closing
animations. This is useful for certain situations, such as when you are:
  - Using a modal as a loading state.
  - Facing a modal that needs to programmatically open then close quickly. You
should generally use the [promises that are returned](#promises) from `open` and
`close`, but sometimes promises are more complex to use than is preferable. An
example of this could be a modal that opens on one route, then closes on another.

- `forService`: If `true`, the modal is registered with the `remodal`
service in your application. You'll find more on using modals as a service in
the [using ember-remodal as a service][1] section.

##### Content Options

- `title`: If provided, displayed at the top of the modal as an `h2`.
- `text`: If provided, displayed under the title as a `p`.
- Block Content: Content placed inside `ember-remodal`'s block will be rendered
below the `title`/`text`, or by itself if no `title`/`text` are provided.

## Styling

You can easily target every portion of the modal.

- Main modal window: `.ember-remodal.window`
- Named modal main window: `.ember-remodal.whatever-you-named-the-modal.window`
- Open button: `.ember-remodal.open.button`
- Open link: `.ember-remodal.link.text`
- Confirm button: `.ember-remodal.confirm.button`
- Cancel button: `.ember-remodal.cancel.button`
- Native close button: `.ember-remodal.native.close`
- Title: `.ember-remodal.title.text`
- Text: `.ember-remodal.paragraph.text`
- Content yielded with block form: `.ember-remodal.yielded.content`
- Overlay: `.remodal-overlay`
- Buttons: `.ember-remodal.button`
- Buttons inside the modal: `.ember-remodal.inner.button`
- Button outside the modal: `.ember-remodal.outer.button`

You can set additional classes on the main modal window via `modalClasses`.

You can also set additional classes on any of the provided buttons via:

- `buttonClasses`
- `outerButtonClasses`
- `innerButtonClasses`

For instance, if you were using [semantic ui](http://semantic-ui.com/), you may
want to add the `.ui` class to all of the included buttons. `.button` is already
applied, so just do:

```hbs
{{ember-remodal buttonClasses='ui' openButton='Open' confirmButton='Ok!'}}
```

# Troubleshooting

### "Race Conditions"

If you are programmatically opening/closing a modal in quick succession, you may
run into this problem, because a modal, once opened or closed, is in `opening`
or `closing` state (respectively) and can't be modified again until it's CSS
animations are complete.

#### Solving "race conditions" with promises

The best way to handle this is to use the [promises that are returned](#promises)
from `open`/`close`:

```js
this.get('remodal').open('some-modal')

.then((modal) => {
  // "modal" here is the instance of 'some-modal'
  console.log(`${modal.get('name')} was opened!`);
  return modal.close();
})

.then((modal) => {
  console.log(`${modal.get('name')} was closed!`);
});
```

#### Other options to consider to solve "race conditions"

- Place the call that should be called 2nd into an `Ember.run.next` block.
This has the potential to force your 2nd call into the next "run loop", but this
fix is highly dependent on your application code and **will not always work**.

- Use `disableAnimation=true` in the modal's options. This will cause a modal
to open/close *near* instantaneously, but again, is highly dependent on your
application code (and potentially the end-user's device) and will also,
**not always work**.


# Collaborating

PRs are welcome, please contribute! If you have a use-case which this does not suit,
please feel free to fix it and PR or open an issue.

## Installation

* `git clone` this repository
* `npm install`
* `bower install`

## Running

* `ember server`
* Visit the 'dummy' app at http://localhost:4200

## Running Tests

* `ember test`
* `ember test --server`

## Building

* `ember build`

For more information on using ember-cli, visit [http://www.ember-cli.com/](http://www.ember-cli.com/).


[1]: #using-ember-remodal-as-a-service
