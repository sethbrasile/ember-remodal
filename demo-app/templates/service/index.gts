import { pageTitle } from 'ember-page-title';
import DemoExample from '../../components/demo-example.gts';
import ServiceBasic from '../../examples/service/service-basic.gts';
import serviceBasicSrc from '../../examples/service/service-basic.gts?highlight';
import ServiceOptions from '../../examples/service/service-options.gts';
import serviceOptionsSrc from '../../examples/service/service-options.gts?highlight';
import ServiceMissing from '../../examples/service/service-missing.gts';
import serviceMissingSrc from '../../examples/service/service-missing.gts?highlight';

<template>
  {{pageTitle "The remodal service"}}

  <h1>The remodal service</h1>
  <p class="docs-lede">Rendering a named, service-driven modal and opening it
    from anywhere with options merged at open time.</p>

  <p>Render one modal with
    <code>@forService</code>
    set to true — typically in your application template, so it is always
    available — and give it a unique
    <code>@name</code>. From anywhere in the app,
    <code>remodal.open(name, options?)</code>
    and
    <code>remodal.close(name)</code>
    drive it. Both return a
    <code>Promise&lt;EmberRemodal&gt;</code>
    that resolves once the animation finishes. Options resolve in precedence
    order: service overrides passed to
    <code>open()</code>
    win over an
    <code>@options</code>
    hash, which wins over direct arguments — the same order the component's
    internal
    <code>opt()</code>
    reads from.</p>

  <DemoExample
    @title="Open a named modal"
    @component={{ServiceBasic}}
    @source={{serviceBasicSrc}}
  />

  <DemoExample
    @title="Options at open time"
    @description="Two buttons open the same modal with different option objects — the options passed to open() decide what renders."
    @component={{ServiceOptions}}
    @source={{serviceOptionsSrc}}
  />

  <DemoExample
    @title="Opening an unrendered name"
    @description="open() and close() always reject when no modal is currently rendered under the given name."
    @component={{ServiceMissing}}
    @source={{serviceMissingSrc}}
  />
</template>
