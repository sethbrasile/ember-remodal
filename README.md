[![Build Status](https://travis-ci.org/sethbrasile/ember-remodal.svg)](https://travis-ci.org/sethbrasile/ember-remodal)

# This ember addon is not ready for public consumption.

Feel free to try it out or whatever, but this readme is probably not correct.
I'm releasing it so that I can test/tweak it with a non-local app I'm working on.
I'll do a real release when I'm confident that it's ready.

# ember-remodal
[![Build Status](https://travis-ci.org/sethbrasile/ember-remodal.svg?branch=master)](https://travis-ci.org/sethbrasile/ember-remodal) [![npm version](https://badge.fury.io/js/ember-remodal.svg)](http://badge.fury.io/js/ember-remodal) [![Ember Observer Score](http://emberobserver.com/badges/ember-remodal.svg)](http://emberobserver.com/addons/ember-remodal)


There are many modal addons for Ember, but most of them (in my experience) are
only useful in a very specific situation. Often, when building large apps, you
may need flexibility in your modals. Sometimes you just want a simple
informational modal triggered by a button press. Other times, you may need to
use a modal as a loading state, programmatically closing the modal when loading
has finished.

This addon aims to be usable in a variety of situations. Also, there weren't any
[remodal](http://vodkabears.github.io/remodal/) ember addons, so I thought I'd
write one :D

## Installation
`ember install ember-remodal`

## Use

### Options Summary

#### Remodal Options
these [options](https://github.com/VodkaBears/Remodal#options) are supported:

- `closeOnOutsideClick` defaults to `true`
- `closeOnEscape` defaults to `true`
- `closeOnCancel` defaults to `true`
- `closeOnConfirm` defaults to `true`
- `modifier` defaults to an empty string
- `hashTracking` defaults to `false` - You probably want to leave this one alone.
It messes with Ember's routes a bit. It's there if you want to mess around.

#### Options Specific to this addon

- `openLabel`:
- `confirmLabel`:
- `cancelLabel`:
- `disableNativeClose`:
- `title`:
- `text`:

### Simplest Use-Case
#### Inline, using the (optional) included triggers

Apply the `remodal-bg` class to anything on your page that you would like blurred
while the modal is open. A common pattern would be to apply this class to a `div`
that is wrapping your entire application. This is completely optional, this modal
will work (and look) fine without this step.

```hbs
{{ember-remodal
  openLabel='Open Modal'
  confirmLabel='OK'
  title='A Title!'
  text='lorem ipsum dolar sit amet'
}}
```

- `openLabel` is the label on the button that will appear to trigger the modal.
- `confirmLabel` is the label on the button that will appear within the modal,
allowing the user to close the modal.
- `title` and `text` are the title and text contained in the modal.

#### Options

In order to keep your templates clean, you may pass all the modal's options in as
a single hash called `options`.

Controller:

```js
export default Ember.Component.extend({
  modalOptions: {
    openLabel: 'Open Modal',
    confirmLabel: 'OK',
    title: 'A Title!',
    text: 'lorem ipsum dolar sit amet'
  }
});
```

Template:

```hbs
{{ember-remodal options=modalOptions}}
```

### Block Form

A modal can be used the same way as described above, but in block form.
This will display anything contained in the block, inside the modal.
Note that the `title` and `text` attributes still work. Both will be displayed
above the `yield`ed content from the block.

```hbs
{{#ember-remodal options=modalOptions}}
  <!-- Any content you want displayed in the modal! -->
{{/ember-remodal}}
```

### Programmatically Opening or Closing

A modal can be programmatically opened by setting it's `showModal` property to `true`

```hbs
{{ember-remodal showModal=someBool}}
```

The opened modal can be programmatically closed by setting `showModal` back to false.

A modal that has been opened using one of the provided triggers, can be programmatically
closed by setting it's `shouldClose` property to true.

```hbs
{{ember-remodal openLabel='Open' shouldClose=someBool}}
```

When a modal has been closed (programmatically or via an included triggger),
it's `shouldClose` property is always set back to `false`, but it's `showModal`
property is up to you.

### Action Hooks

- `onOpen` is called when a modal has been opened
- `onClose` is called when a modal has been closed for **any** reason
- `onConfirm` is called when a modal has been closed via it's `confirm` button
- `onCancel` is called when a modal has been closed via it's `cancel` button
- TODO: (not implemented yet) `onNativeClose` is called when a modal has been closed via remodal's native
close button (the little gray arrow on the top left of the modal)
- TODO: (not implemented yet) `onOverlayClose` is called when a user clicks it's background overlay to close

Template:

```hbs
{{ember-remodal openLabel='Open' onClose='modalDidClose' onOpen='modalDidOpen'}}
```

Controller or Route:

```js
actions: {
  modalDidOpen() {
    console.log('The modal was opened!');
  },

  modalDidClose() {
    console.log('The modal was closed!');
  }
}
```

## Styling

You can easily target every portion of the modal.

- Open button: `.ember-remodal.open.button`
- Confirm button: `.ember-remodal.confirm.button`
- Cancel button: `.ember-remodal.cancel.button`
- Native close button: `.ember-remodal.native.close`
- Main modal window: `.ember-remodal.window`
- Title: `.ember-remodal.title.text`
- Text: `.ember-remodal.paragraph.text`
- Content yielded with block form: `.ember-remodal.yielded.content`
- Overlay: `.remodal-overlay` optionally in combination with `.remodal-is-opened` or `.remodal-is-closed`

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
