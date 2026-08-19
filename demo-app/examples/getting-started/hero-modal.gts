import EmberRemodal from '#src/components/ember-remodal.gts';

<template>
  <EmberRemodal @title="Hello from 3.0" as |m|>
    <m.open>
      <button type="button" class="demo-button">Open the demo modal</button>
    </m.open>
    <img
      class="demo-hero-image"
      src="https://picsum.photos/seed/ember-remodal/640/400"
      width="640"
      height="400"
      alt="A placeholder photograph"
    />
    <p>Built on the native
      <code>&lt;dialog&gt;</code>
      element — no jQuery, full TypeScript types, and every 2.x feature still
      here.</p>
    <div class="demo-modal-actions">
      <m.cancel>
        <button type="button" class="remodal-cancel">Cancel</button>
      </m.cancel>
      <m.confirm>
        <button type="button" class="remodal-confirm">Confirm</button>
      </m.confirm>
    </div>
  </EmberRemodal>
</template>
