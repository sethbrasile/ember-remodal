import { pageTitle } from 'ember-page-title';
import { LinkTo } from '@ember/routing';
import DemoExample from '../components/demo-example.gts';
import HeroModal from '../examples/getting-started/hero-modal.gts';
import heroModalSrc from '../examples/getting-started/hero-modal.gts?highlight';

<template>
  {{pageTitle "ember-remodal"}}

  <header class="demo-hero">
    <h1>ember-remodal</h1>
    <p class="demo-tagline">
      An intensely usable modal addon for Ember.js — the same remodal look and
      feel, rebuilt on the native
      <code>&lt;dialog&gt;</code>
      element. No jQuery.
    </p>
  </header>

  <DemoExample
    @title="Try it"
    @component={{HeroModal}}
    @source={{heroModalSrc}}
  />

  <section class="docs-section">
    <h2>Install</h2>
    <pre><code>pnpm add ember-remodal</code></pre>
    <p><LinkTo @route="install">Full install guide →</LinkTo></p>
  </section>

  <section class="docs-section">
    <h2>What's new in 3.0</h2>
    <ul>
      <li>Native
        <code>&lt;dialog&gt;</code>
        (top layer, focus containment, Escape) —
        <LinkTo @route="accessibility">Accessibility</LinkTo></li>
      <li>No jQuery —
        <LinkTo @route="install">Install</LinkTo></li>
      <li><code>m.isOpen</code>
        lazy content and
        <code>m.openAction</code>/<code>m.closeAction</code>/<code
        >m.confirmAction</code>/<code>m.cancelAction</code>
        —
        <LinkTo @route="usage.yielded">Yielded controls</LinkTo></li>
      <li><code>@onBeforeOpen</code>
        veto —
        <LinkTo @route="options.actions">Action hooks</LinkTo></li>
      <li>Naming options (<code>@ariaLabel</code>,
        <code>@ariaLabelledBy</code>,
        <code>@closeButtonLabel</code>) —
        <LinkTo @route="options.content">Content options</LinkTo></li>
      <li><code>CloseReason</code>
        on
        <code>onClose</code>
        —
        <LinkTo @route="options.actions">Action hooks</LinkTo></li>
      <li>Stacked modals —
        <LinkTo @route="service.promises">Promises</LinkTo></li>
      <li><code>ember-remodal/test-support</code>
        —
        <LinkTo @route="testing">Testing</LinkTo></li>
      <li>Reduced-motion + forced-colors CSS —
        <LinkTo @route="styling">Styling & theming</LinkTo></li>
      <li>Full TypeScript/Glint types —
        <LinkTo @route="migration">Migrating from 2.x</LinkTo></li>
    </ul>
    <p>
      <a href="https://github.com/sethbrasile/ember-remodal">GitHub</a>
      ·
      <a href="https://www.npmjs.com/package/ember-remodal">npm</a>
      ·
      <LinkTo @route="migration">Migrating from 2.x</LinkTo>
    </p>
  </section>
</template>
