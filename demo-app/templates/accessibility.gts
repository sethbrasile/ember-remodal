import { pageTitle } from 'ember-page-title';
import { LinkTo } from '@ember/routing';
import DemoExample from '../components/demo-example.gts';
import NamedDialog from '../examples/accessibility/named-dialog.gts';
import namedDialogSrc from '../examples/accessibility/named-dialog.gts?highlight';
import EscapeRules from '../examples/accessibility/escape-rules.gts';
import escapeRulesSrc from '../examples/accessibility/escape-rules.gts?highlight';

<template>
  {{pageTitle "Accessibility"}}

  <h1>Accessibility</h1>
  <p class="docs-lede">Naming the dialog, the Escape rules, and the
    focusable-control requirement for yielded blocks.</p>

  <section class="docs-section">
    <h2>Native &lt;dialog&gt;</h2>
    <p>The modal is a native
      <code>&lt;dialog&gt;</code>
      opened with
      <code>showModal()</code>: it renders in the browser's top layer, contains
      focus while open, and handles Escape natively (intercepted so the closing
      animation still plays). Content outside the open dialog is inert to
      assistive technology courtesy of the platform — no
      <code>aria-hidden</code>
      bookkeeping needed.</p>
  </section>

  <section class="docs-section">
    <h2>Naming</h2>
    <p><code>showModal()</code>
      supplies
      <code>role="dialog"</code>
      and implicit
      <code>aria-modal</code>, but no name.
      <code>@title</code>
      provides one when it's visible;
      <code>@ariaLabel</code>
      is the escape hatch for a modal with no visible title; and
      <code>@ariaLabelledBy</code>
      names the dialog from your own on-screen markup instead of duplicating its
      text. Exactly one naming attribute is ever emitted, in that precedence
      order.</p>
    <DemoExample
      @title="Three ways to name a dialog"
      @component={{NamedDialog}}
      @source={{namedDialogSrc}}
    />
  </section>

  <section class="docs-section">
    <h2>Escape rules</h2>
    <p>Setting
      <code>closeOnEscape</code>
      to false is honored only while the modal has some other way out, decided
      by
      <strong>enumerating the exits the addon renders</strong>
      — not by scanning the DOM for something focusable. With none of those,
      Escape closes the modal anyway, because focus containment makes an
      unclosable modal a real keyboard trap (WCAG 2.1.2). This is not dev-only
      behavior: a development warning explains it, but production behaves the
      same way. Escape can also force-close a modal even with
      <code>closeOnEscape</code>
      set to false, in browsers implementing the HTML close-watcher algorithm,
      when the window has no history-action activation — a platform behavior,
      not addon behavior.</p>
    <DemoExample
      @title="A declared custom keyboard exit"
      @component={{EscapeRules}}
      @source={{escapeRulesSrc}}
    />
  </section>

  <section class="docs-section">
    <h2>The focusable-control requirement</h2>
    <p>The yielded
      <code>m.open</code>
      /
      <code>m.confirm</code>
      /
      <code>m.cancel</code>
      components render a click-delegating
      <code>&lt;span&gt;</code>, so their blocks must contain your own focusable
      control —
      <code>&lt;m.open&gt;Open&lt;/m.open&gt;</code>
      works with a mouse but is unreachable by keyboard (WCAG 2.1.1). See
      <LinkTo @route="usage.yielded">Yielded controls</LinkTo>.</p>
  </section>

  <section class="docs-section">
    <h2>Naming attributes on the rendered markup</h2>
    <p>A rendered modal carries a generated
      <code>id</code>
      on its
      <code>&lt;h2&gt;</code>, an
      <code>aria-labelledby</code>
      (or
      <code>aria-label</code>) on the
      <code>&lt;dialog&gt;</code>, and an
      <code>aria-label</code>
      plus
      <code>title</code>
      on the close button.</p>
  </section>

  <section class="docs-section">
    <h2>Motion and contrast</h2>
    <p>Reduced motion and forced-colors support are covered on
      <LinkTo @route="styling">Styling & theming</LinkTo>.</p>
  </section>
</template>
