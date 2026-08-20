import { pageTitle } from 'ember-page-title';
import DemoExample from '../../components/demo-example.gts';
import YieldedButtons from '../../examples/usage/yielded-buttons.gts';
import yieldedButtonsSrc from '../../examples/usage/yielded-buttons.gts?highlight';
import YieldedActions from '../../examples/usage/yielded-actions.gts';
import yieldedActionsSrc from '../../examples/usage/yielded-actions.gts?highlight';
import ErButtonDirect from '../../examples/usage/er-button-direct.gts';
import erButtonDirectSrc from '../../examples/usage/er-button-direct.gts?highlight';

<template>
  {{pageTitle "Yielded controls"}}

  <h1>Yielded controls</h1>
  <p class="docs-lede">The eight things a block-form modal yields, and when to
    reach for the button components versus the bare actions.</p>

  <p>The block yields
    <code>open</code>,
    <code>confirm</code>,
    <code>cancel</code>
    (button components),
    <code>isOpen</code>
    (a boolean), and
    <code>openAction</code>,
    <code>closeAction</code>,
    <code>confirmAction</code>,
    <code>cancelAction</code>
    (plain zero-argument functions for the
    <code>on</code>
    modifier). Reach for the button components when your control is exactly a
    button; reach for the bare actions when you are wiring an existing element,
    a form submit, or a keyboard shortcut.</p>

  <p>The yielded button components render a click-delegating
    <code>&lt;span&gt;</code>, so their blocks must contain your own focusable
    control —
    <code>&lt;m.open&gt;Open&lt;/m.open&gt;</code>
    works with a mouse but is unreachable by keyboard.</p>

  <DemoExample
    @title="The yielded button components"
    @component={{YieldedButtons}}
    @source={{yieldedButtonsSrc}}
  />

  <DemoExample
    @title="Bare actions on your own buttons"
    @component={{YieldedActions}}
    @source={{yieldedActionsSrc}}
  />

  <DemoExample
    @title="ErButton, imported directly"
    @description="ErButtonSignature.Args is { destination?: Element | null; onClick: (event?: Event) => unknown }; it yields a default block, and its element is a <span>."
    @component={{ErButtonDirect}}
    @source={{erButtonDirectSrc}}
  />
</template>
