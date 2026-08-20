import { pageTitle } from 'ember-page-title';
import { LinkTo } from '@ember/routing';
import DemoExample from '../components/demo-example.gts';
import appSrc from '../app.gts?highlight';

<template>
  {{pageTitle "Install"}}

  <h1>Install</h1>
  <p class="docs-lede">Requirements, the install command, the stylesheet import,
    and how to register the addon in a strict-resolver app.</p>

  <section class="docs-section">
    <h2>Requirements</h2>
    <ul>
      <li><strong>Ember &gt;= 5.8.</strong>
        Works in any Embroider/Vite app, and in classic builds via
        <code>@embroider/compat</code>. Older Ember versions must stay on the
        2.x line.</li>
      <li><strong>Browser floor: Chrome/Edge 99, Firefox 98, Safari 15.4</strong>
        — the addon needs
        <code>dialog.showModal()</code>
        and
        <code>@layer</code>, and there is no polyfill path.</li>
      <li>jQuery and the
        <code>remodal</code>
        library are no longer used or installed.</li>
      <li><code>ember-wormhole</code>
        is no longer a dependency — the yielded
        <code>m.open</code>
        trigger is portaled with Ember's built-in
        <code>in-element</code>
        helper.</li>
      <li><code>@glimmer/component</code>
        is now a peer dependency (<code>&gt;= 1.1.2</code>). Every app with
        <code>ember-source</code>
        already has it.</li>
      <li>Published as a v2 addon, auto-discovered by ember-cli/Embroider.</li>
    </ul>
  </section>

  <section class="docs-section">
    <h2>Install</h2>
    <pre><code>pnpm add ember-remodal</code></pre>
  </section>

  <section class="docs-section">
    <h2>Stylesheet</h2>
    <p>The theme is imported by the component, so there is nothing to add to
      your build. If you want to control when it loads, import it yourself:
      <code>import 'ember-remodal/ember-remodal.css'</code>. It ships inside
      <code>@layer ember-remodal</code>, so unlayered app CSS overrides it
      without a specificity fight — see
      <LinkTo @route="styling">Styling & theming</LinkTo>.</p>
  </section>

  <section class="docs-section">
    <h2>Registration in a strict-resolver app</h2>
    <p>A strict-resolver app (<code>ember-strict-application-resolver</code>)
      has no runtime resolver, so every module the addon needs — including the
      <code>remodal</code>
      service — has to be listed explicitly. This demo's own
      <code>app.gts</code>
      is the worked example: look at the
      <code>./services/remodal</code>
      entry in its
      <code>modules</code>
      block.</p>
    <DemoExample @title="demo-app/app.gts" @source={{appSrc}} />
  </section>

  <section class="docs-section">
    <h2>Classic (ember-cli) apps</h2>
    <p>Nothing to register. As a v2 addon, ember-remodal is auto-discovered by
      ember-cli/Embroider — install it and import the component.</p>
  </section>
</template>
