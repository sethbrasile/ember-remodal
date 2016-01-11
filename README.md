# Beta!
I'll try not to break things, but until v1.0.0 expect possibly breaking changes
even in point releases. I'm rapidly iterating and planning on hitting v1.0.0 by
January 17th 2016.

# ember-remodal
[![Build Status](https://travis-ci.org/sethbrasile/ember-remodal.svg?branch=master)](https://travis-ci.org/sethbrasile/ember-remodal) [![npm version](https://badge.fury.io/js/ember-remodal.svg)](http://badge.fury.io/js/ember-remodal) [![Ember Observer Score](http://emberobserver.com/badges/ember-remodal.svg)](http://emberobserver.com/addons/ember-remodal)

*This README is up-to-date and accurate as of ember-remodal v0.0.8*

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
ember-remodal is compatible with Ember 1.13.x and up.

## Installation
`ember install ember-remodal`

This will add [remodal](http://vodkabears.github.io/remodal/) to your `bower.json` and make the `{{ember-remodal}}`
component available in your application.

## Usage

*Remember to add the `remodal-bg` class to anything in your app that you want
blurred while a modal is open!*

### Options Summary

#### Remodal Options
These [remodal options](https://github.com/VodkaBears/Remodal#options) are supported:

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

- `linkButton`: Just like `openButton`, but rendered as an `a` tag instead of a
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

**Button Booleans**

- `disableNativeClose`: If `true`, this keeps the little `x` button from
appearing in the top left corner of the modal.

*Note on close events:* `onClose` fires when a modal closes for any reason.
`remodal` doesn't currently offer a hook to allow for `onNativeClose` or
`onOverlayClose` actions.

##### Functionality Options

- `closeOnOutsideClick`: If `true` (which is the default), this allows the user
to click the dark overlay outside the modal window to close the modal.

- `closeOnEscape`: If `true` (which is the default), this allows the user to hit
the `escape` key on their keyboard to close the modal.

- `disableForeground`: If `true`, this causes the white box surrounding the modal
content to be transparent, and switches the default text color from
`black` to `white`. When combined with `closeOnOutsideClick: false` This allows
one to use the modal as an un-exitable overlay, such as a `loading state`.
By default, setting this option to true also sets `disableNativeClose` to `true`,
but `disableNativeClose` can be explicitly set back to `false` if you prefer.

- `forService`: If `true`, the modal is registered with the `remodal`
service in your application. You'll find more on using modals as a service
[below][1].

##### Content Options

- `title`: The (optional) title is displayed at the top of the modal as an `h2`.
- `text`: The (optional) text is displayed just under the title as a `p`.
- Content placed inside the component when used as a block-component will be
rendered below the `title`/`text`, or by itself if no `title`/`text` are provided.


### Simplest Use-Case

*If you will be using more than a couple modals in your application,
please read through here to understand how many of the options work, but refer
to the [using ember-remodal as a service][1] section for implementation*

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
{{#ember-remodal title='Some Title'}}
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
that it must currently be rendered in order for your service to use it. For this
reason, a common convention would be to place `{{ember-remodal forService=true}}`
in the application template, so that it is always accessible.*

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
`close` with no arguments.

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
- Overlay: `.remodal-overlay` optionally in combination with `.remodal-is-opened` or `.remodal-is-closed`
- Buttons inside the modal: `.ember-remodal.inner.button`
- Button outside the modal: `.ember-remodal.outer.button`

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


[1]: https://github.com/sethbrasile/ember-remodal#using-ember-remodal-as-a-service
