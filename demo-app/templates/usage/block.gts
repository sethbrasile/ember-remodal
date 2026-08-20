import { pageTitle } from 'ember-page-title';
import DemoExample from '../../components/demo-example.gts';
import BlockBasic from '../../examples/usage/block-basic.gts';
import blockBasicSrc from '../../examples/usage/block-basic.gts?highlight';
import BlockLazy from '../../examples/usage/block-lazy.gts';
import blockLazySrc from '../../examples/usage/block-lazy.gts?highlight';

<template>
  {{pageTitle "Block usage"}}

  <h1>Block usage</h1>
  <p class="docs-lede">Bringing your own markup with the block form, and
    deferring expensive content until the modal opens.</p>

  <p>The block form yields a hash (conventionally
    <code>m</code>) of eight things:
    <code>open</code>,
    <code>confirm</code>, and
    <code>cancel</code>
    — button components with their click handlers pre-bound — plus
    <code>isOpen</code>, and the bare
    <code>openAction</code>,
    <code>closeAction</code>,
    <code>confirmAction</code>, and
    <code>cancelAction</code>
    functions for wiring your own elements.
    <code>m.open</code>
    is portaled outside the
    <code>&lt;dialog&gt;</code>, exactly like the inline trigger.</p>

  <DemoExample
    @title="Custom content"
    @component={{BlockBasic}}
    @source={{blockBasicSrc}}
  />

  <DemoExample
    @title="Lazy content"
    @description="m.isOpen is true while the modal is opening, open, or closing — a good place to defer expensive content."
    @component={{BlockLazy}}
    @source={{blockLazySrc}}
  />
</template>
