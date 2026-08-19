import EmberRemodal from '#src/components/ember-remodal.gts';

<template>
  <EmberRemodal @title="Yielded button components" as |m|>
    <m.open>
      <button type="button" class="demo-button">Open</button>
    </m.open>
    <p>
      Each of these is an
      <code>ErButton</code>
      instance with
      <code>onClick</code>
      (and, for
      <code>open</code>,
      <code>destination</code>) pre-bound.
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
