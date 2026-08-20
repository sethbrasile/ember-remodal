import { on } from '@ember/modifier';
import EmberRemodal from '#src/components/ember-remodal.gts';

<template>
  <EmberRemodal @title="Bare actions" as |m|>
    <m.open>
      <button type="button" class="demo-button">Open</button>
    </m.open>
    <p>
      These buttons are wired directly to the yielded bare actions with the
      <code>on</code>
      modifier — no button components involved.
    </p>
    <div class="demo-modal-actions">
      <button
        type="button"
        class="demo-button subtle"
        {{on "click" m.closeAction}}
      >Just close</button>
      <button
        type="button"
        class="remodal-cancel"
        {{on "click" m.cancelAction}}
      >Cancel</button>
      <button
        type="button"
        class="remodal-confirm"
        {{on "click" m.confirmAction}}
      >Confirm</button>
    </div>
  </EmberRemodal>
</template>
