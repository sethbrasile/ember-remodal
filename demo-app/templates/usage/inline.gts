import { pageTitle } from 'ember-page-title';
import { LinkTo } from '@ember/routing';
import DemoExample from '../../components/demo-example.gts';
import InlineSimple from '../../examples/usage/inline-simple.gts';
import inlineSimpleSrc from '../../examples/usage/inline-simple.gts?highlight';
import InlineStyled from '../../examples/usage/inline-styled.gts';
import inlineStyledSrc from '../../examples/usage/inline-styled.gts?highlight';
import InlineActions from '../../examples/usage/inline-actions.gts';
import inlineActionsSrc from '../../examples/usage/inline-actions.gts?highlight';

<template>
  {{pageTitle "Inline usage"}}

  <h1>Inline usage</h1>
  <p class="docs-lede">Rendering a whole modal — trigger included — from a
    single self-closing component invocation.</p>

  <p>The inline form renders everything from arguments: the trigger (<code
    >@openButton</code>), the title and text, and the confirm/cancel buttons.
    The trigger is portaled outside the
    <code>&lt;dialog&gt;</code>, so it stays where you invoked the component
    even though the dialog itself renders in the browser's top layer. Callbacks
    are plain functions in 3.0, not string action names — see
    <LinkTo @route="migration">Migrating from 2.x</LinkTo>.</p>

  <DemoExample
    @title="Simple inline modal"
    @component={{InlineSimple}}
    @source={{inlineSimpleSrc}}
  />

  <DemoExample
    @title="With classes and a modifier"
    @description="The modifier arg restyles the whole modal; the per-button class args target one button each."
    @component={{InlineStyled}}
    @source={{inlineStyledSrc}}
  />

  <DemoExample
    @title="With function actions"
    @description="Each of the four callbacks pushes a toast — onClose's badge is the close reason."
    @component={{InlineActions}}
    @source={{inlineActionsSrc}}
  />
</template>
