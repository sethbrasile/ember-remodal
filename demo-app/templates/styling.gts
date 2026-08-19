import { pageTitle } from 'ember-page-title';
import DemoExample from '../components/demo-example.gts';
import ThemeMidnight from '../examples/styling/theme-midnight.gts';
import themeMidnightSrc from '../examples/styling/theme-midnight.gts?highlight';
import midnightCssSrc from '../styles/demo-midnight.css?highlight';
import BackdropAndParts from '../examples/styling/backdrop-and-parts.gts';
import backdropAndPartsSrc from '../examples/styling/backdrop-and-parts.gts?highlight';
import outlineCssSrc from '../styles/demo-outline.css?highlight';
import ReducedMotion from '../examples/styling/reduced-motion.gts';
import reducedMotionSrc from '../examples/styling/reduced-motion.gts?highlight';
import themeCssSrc from '#src/styles/ember-remodal.css?highlight';

<template>
  {{pageTitle "Styling & theming"}}

  <h1>Styling & theming</h1>
  <p class="docs-lede">How the theme ships, the custom-property palette, a
    worked custom theme, and reduced motion / forced colors.</p>

  <section class="docs-section">
    <h2>How the theme ships</h2>
    <p>The whole theme lives inside
      <code>@layer ember-remodal</code>. Unlayered author CSS beats layered CSS
      regardless of specificity or source order, so anything in your own
      stylesheet wins over the addon's defaults without a specificity fight —
      the stylesheet ships as a side-effect import whose bundle position the
      addon cannot control, so this is what makes the override promise hold
      anyway.</p>
  </section>

  <section class="docs-section">
    <h2>Custom properties</h2>
    <p>The palette block near the top of the stylesheet lists every token.
      Override them on
      <code>.remodal</code>, or scope them to one modal with a
      <code>@modifier</code>
      class.</p>
    <DemoExample
      @title="src/styles/ember-remodal.css"
      @source={{themeCssSrc}}
    />
  </section>

  <section class="docs-section">
    <h2>A custom theme</h2>
    <DemoExample
      @title="Theming with @modifier"
      @component={{ThemeMidnight}}
      @source={{themeMidnightSrc}}
    />
    <DemoExample @title="demo-midnight.css" @source={{midnightCssSrc}} />
  </section>

  <section class="docs-section">
    <h2>Targeting parts</h2>
    <p>Every part is addressable:
      <code>dialog.remodal-wrapper</code>
      (and its
      <code>::backdrop</code>),
      <code>.remodal</code>
      (the card),
      <code>.remodal-close</code>,
      <code>.remodal-confirm</code>,
      <code>.remodal-cancel</code>,
      <code>.remodal-title</code>, and
      <code>.remodal-text</code>.</p>
    <DemoExample
      @title="A square, outlined theme"
      @component={{BackdropAndParts}}
      @source={{backdropAndPartsSrc}}
    />
    <DemoExample @title="demo-outline.css" @source={{outlineCssSrc}} />
  </section>

  <section class="docs-section">
    <h2>Reduced motion</h2>
    <p>All built-in animations and transitions are suppressed automatically
      under
      <code>prefers-reduced-motion: reduce</code>.
      <code>@disableAnimation</code>
      is the per-modal switch. This checkbox re-states the same rules under a
      class, so the behavior is visible without changing an OS setting.</p>
    <DemoExample
      @title="Simulated reduced motion"
      @component={{ReducedMotion}}
      @source={{reducedMotionSrc}}
    />
  </section>

  <section class="docs-section">
    <h2>Forced colors</h2>
    <p>Under
      <code>forced-colors: active</code>
      (Windows High Contrast), every background above is overridden by the
      system palette, so the addon gives the card and every button a border,
      gives cancel a dashed border style to keep it distinguishable from
      confirm, and draws focus with a system
      <code>Highlight</code>
      outline. Preview it in Chrome DevTools → Rendering → "Emulate CSS media
      feature forced-colors".</p>
  </section>
</template>
