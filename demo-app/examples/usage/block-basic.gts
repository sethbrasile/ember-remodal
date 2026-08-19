import EmberRemodal from '#src/components/ember-remodal.gts';

<template>
  <EmberRemodal @title="Custom content" as |m|>
    <m.open>
      <button type="button" class="demo-button">Open block modal</button>
    </m.open>
    <p>
      Anything you like goes here: forms, images, other components. These two
      buttons are the yielded
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
</template>
