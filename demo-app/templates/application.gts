import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { service } from '@ember/service';
import { pageTitle } from 'ember-page-title';
import EmberRemodal from '#src/components/ember-remodal.gts';
import type RemodalService from '#src/services/remodal.ts';

class ServiceDemo extends Component {
  @service declare remodal: RemodalService;

  @tracked log: string[] = [];

  appendLog = (message: string): void => {
    this.log = [...this.log, message];
  };

  openViaService = (): void => {
    void this.remodal
      .open('demo-service-modal', {
        title: 'Opened via the service',
        text: 'this.remodal.open(name, options) resolves when the opening animation finishes.',
      })
      .then(() => this.appendLog('open() resolved'));
  };

  openThenAutoClose = (): void => {
    void this.remodal
      .open('demo-service-modal', {
        title: 'Promise chaining',
        text: 'This modal closes itself one second after open() resolves.',
      })
      .then(
        (modal) =>
          new Promise<typeof modal>((resolve) =>
            setTimeout(() => resolve(modal), 1000),
          ),
      )
      .then((modal) => modal.close())
      .then(() => this.appendLog('open() → close() chain resolved'));
  };

  <template>
    <div class="demo-buttons">
      <button
        type="button"
        class="demo-button"
        {{on "click" this.openViaService}}
      >Open via service</button>
      <button
        type="button"
        class="demo-button subtle"
        {{on "click" this.openThenAutoClose}}
      >Open, then auto-close</button>
    </div>

    {{#if this.log.length}}
      <ol class="demo-log">
        {{#each this.log as |entry|}}
          <li>{{entry}}</li>
        {{/each}}
      </ol>
    {{/if}}

    <EmberRemodal @forService={{true}} @name="demo-service-modal" />
  </template>
}

<template>
  {{pageTitle "ember-remodal"}}

  <main class="demo">
    <header class="demo-hero">
      <h1>ember-remodal</h1>
      <p class="demo-tagline">
        An intensely usable modal addon for Ember.js — the same remodal look and
        feel, rebuilt on the native
        <code>&lt;dialog&gt;</code>
        element. No jQuery.
      </p>
    </header>

    <section class="demo-section">
      <h2>Inline modal</h2>
      <p>
        Pass
        <code>@openButton</code>,
        <code>@title</code>,
        <code>@text</code>, and confirm/cancel buttons — the component renders
        everything, including the trigger.
      </p>
      <EmberRemodal
        @openButton="Open inline modal"
        @openButtonClasses="demo-button"
        @title="Hello from ember-remodal"
        @text="This whole modal — trigger included — comes from a single self-closing component invocation."
        @confirmButton="Sounds good"
        @cancelButton="No thanks"
      />
    </section>

    <section class="demo-section">
      <h2>Block usage</h2>
      <p>
        The component yields
        <code>m.open</code>,
        <code>m.confirm</code>, and
        <code>m.cancel</code>
        button components, so you bring your own markup. The
        <code>m.open</code>
        trigger is portaled outside the dialog automatically.
      </p>
      <EmberRemodal @title="Custom content" as |m|>
        <m.open>
          <button type="button" class="demo-button">Open block modal</button>
        </m.open>
        <p>
          Anything you like goes here: forms, images, other components. These
          two buttons are the yielded
          <code>m.confirm</code>
          and
          <code>m.cancel</code>:
        </p>
        <div class="demo-modal-actions">
          <m.cancel>
            <button type="button" class="remodal-cancel">Cancel</button>
          </m.cancel>
          <m.confirm>
            <button type="button" class="remodal-confirm">Confirm</button>
          </m.confirm>
        </div>
      </EmberRemodal>
    </section>

    <section class="demo-section">
      <h2>Lazy content</h2>
      <p>
        <code>m.isOpen</code>
        is true while the modal is opening or open — perfect for deferring
        expensive content until it is actually needed.
      </p>
      <EmberRemodal @title="Lazy content" as |m|>
        <m.open>
          <button type="button" class="demo-button">Open lazy modal</button>
        </m.open>
        {{#if m.isOpen}}
          <p class="demo-lazy">
            This paragraph did not exist in the DOM until the modal opened. It
            is torn down again when the modal closes.
          </p>
        {{/if}}
      </EmberRemodal>
    </section>

    <section class="demo-section">
      <h2>Service usage</h2>
      <p>
        Render one
        <code>@forService</code>
        modal (for example in your application template), then open it from
        anywhere with the
        <code>remodal</code>
        service.
        <code>open()</code>
        and
        <code>close()</code>
        return promises that resolve when the animation finishes.
      </p>
      <ServiceDemo />
    </section>

    <section class="demo-section">
      <h2>Frameless: disableForeground</h2>
      <p>
        <code>@disableForeground</code>
        removes the white card so your content floats on the backdrop — lightbox
        style.
      </p>
      {{! A frameless modal has no visible title, so @ariaLabel is what gives its
          <dialog> an accessible name. Without it the addon warns
          (ember-remodal.modal-without-accessible-name) and screen readers
          announce nothing but "dialog". }}
      <EmberRemodal
        @openButton="Open frameless modal"
        @openButtonClasses="demo-button"
        @ariaLabel="Frameless modal"
        @disableForeground={{true}}
      >
        <div class="demo-frameless">
          <p>No card, no chrome — just your content on the overlay.</p>
          <p class="demo-frameless-hint">Click outside or press Escape to close.</p>
        </div>
      </EmberRemodal>
    </section>

    <section class="demo-section">
      <h2>Theming with @modifier</h2>
      <p>
        The classic remodal classes are all preserved.
        <code>@modifier</code>
        adds a class to the wrapper and card so you can restyle a single modal —
        here,
        <code>.remodal.demo-midnight</code>
        in plain CSS.
      </p>
      <EmberRemodal
        @openButton="Open themed modal"
        @openButtonClasses="demo-button"
        @modifier="demo-midnight"
        @title="Midnight theme"
        @text="Same component, restyled entirely from the app's stylesheet."
        @confirmButton="Nice"
      />
    </section>

    <footer class="demo-footer">
      <p>
        MIT licensed. Styles ported from
        <a href="https://github.com/vodkabears/Remodal">Remodal</a>
        by Ilya Makarov.
      </p>
    </footer>
  </main>
</template>
