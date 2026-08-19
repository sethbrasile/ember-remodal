import { pageTitle } from 'ember-page-title';
import DemoExample from '../components/demo-example.gts';
import DogList from '../examples/state/dog-list.gts';
import dogListSrc from '../examples/state/dog-list.gts?highlight';

<template>
  {{pageTitle "State-driven modals"}}

  <h1>State-driven modals</h1>
  <p class="docs-lede">Keeping state in the owner and driving one modal's
    content from it, instead of one modal per item.</p>

  <p>The thesis: render one
    <code>@forService</code>
    modal and keep the "which one" state in the component that owns the list,
    not in the modal.
    <code>@ariaLabelledBy</code>
    names the dialog from a heading inside your own block content, so a
    state-driven modal is named without duplicating text into
    <code>@ariaLabel</code>.</p>

  <DemoExample
    @title="Click a dog"
    @component={{DogList}}
    @source={{dogListSrc}}
  />
</template>
