import { pageTitle } from 'ember-page-title';
import DemoExample from '../../components/demo-example.gts';
import InlineSimple from '../../examples/usage/inline-simple.gts';
import inlineSimpleSrc from '../../examples/usage/inline-simple.gts?highlight';

<template>
  {{pageTitle "Inline usage"}}

  <h1>Inline usage</h1>
  <p class="docs-lede">Rendering a whole modal — trigger included — from a
    single self-closing component invocation.</p>

  <DemoExample
    @title="Simple inline modal"
    @component={{InlineSimple}}
    @source={{inlineSimpleSrc}}
  />
</template>
