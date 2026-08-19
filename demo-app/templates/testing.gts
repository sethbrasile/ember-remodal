import { pageTitle } from 'ember-page-title';
import DemoExample from '../components/demo-example.gts';
import exampleTestSrc from '../examples/testing/example-test.ts?highlight';

<template>
  {{pageTitle "Testing"}}

  <h1>Testing</h1>
  <p class="docs-lede">The test-support helpers, what they do, and how animation
    and selectors changed from 2.x.</p>

  <section class="docs-section">
    <h2>ember-remodal/test-support</h2>
    <ul>
      <li><code>setupRemodal(hooks, options?)</code>
        — installs the reset/leak-detection hooks for the shared scroll lock,
        and applies
        <code>options.disableAnimation</code>
        for the module.</li>
      <li><code>resetRemodalScrollLock()</code>
        — force-releases the scroll lock. Only needed if you manage QUnit hooks
        yourself.</li>
      <li><code>setRemodalAnimationDisabled(flag)</code>
        — turns animations off (or back on) process-wide; prefer the
        <code>setupRemodal</code>
        option, which also unwinds it.</li>
      <li><code>remodalDialog(scope?)</code>
        — the one modal
        <code>&lt;dialog&gt;</code>
        in scope; throws when the scope holds none, more than one, or a string
        scope matches no element.</li>
      <li><code>remodalDialogs(scope?)</code>
        — every modal
        <code>&lt;dialog&gt;</code>
        in scope, in document order — the helper for stacked modals.</li>
    </ul>
    <p>Animations are wrapped in
      <code>@ember/test-waiters</code>, so
      <code>await click(…)</code>
      and
      <code>await settled()</code>
      already wait for them — most suites can drop manual waits entirely. The
      2.x
      <code>disableAnimationWhileTesting</code>
      config flag still works, but only in apps using the classic
      <code>ember-resolver</code>; a strict-resolver app registers no
      <code>config:environment</code>
      module, so
      <code>setupRemodal</code>
      is the supported path in both kinds of app.</p>
  </section>

  <section class="docs-section">
    <h2>Selector updates from 2.x</h2>
    <p>The bare single-word class tokens (<code>.window</code>,
      <code>.close</code>,
      <code>.button</code>, …) are retired in favor of the
      <code>ember-remodal-</code>
      prefixed forms.
      <code>[data-remodal-id=…]</code>
      is gone — use
      <code>[data-test-id="modalWindow"]</code>
      or your own
      <code>@dataTestId</code>. The dialog itself is
      <code>[data-test-id="modalWrapper"]</code>, which is new in 3.0.</p>
  </section>

  <DemoExample
    @title="demo-app/examples/testing/example-test.ts"
    @source={{exampleTestSrc}}
  />
</template>
