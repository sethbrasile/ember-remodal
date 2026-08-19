import EmberRemodal from '#src/components/ember-remodal.gts';

<template>
  <EmberRemodal @title="Lazy content" as |m|>
    <m.open>
      <button type="button" class="demo-button">Open lazy modal</button>
    </m.open>
    {{#if m.isOpen}}
      <p class="demo-lazy">
        This paragraph did not exist in the DOM until the modal opened. It is
        torn down again when the modal closes.
      </p>
    {{/if}}
  </EmberRemodal>
</template>
