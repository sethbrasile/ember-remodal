import EmberRemodal from '#src/components/ember-remodal.gts';

<template>
  <EmberRemodal
    @openButton="Open themed modal"
    @openButtonClasses="demo-button"
    @modifier="demo-midnight"
    @modalClasses="demo-pill"
    @title="Class hooks"
    @text="modifier lands on both the dialog and the card; modalClasses lands on the card alone."
    @confirmButton="Confirm"
    @cancelButton="Cancel"
    @confirmButtonClasses="demo-pill"
    @cancelButtonClasses="demo-pill"
  />
  <EmberRemodal
    @openButton="Open with legacy classes"
    @openButtonClasses="demo-button subtle"
    @title="Legacy class names"
    @text="This modal also carries the retired 2.x bare single-word class tokens (window, title, text, button, …) alongside the namespaced ones."
    @confirmButton="OK"
    @legacyClassNames={{true}}
  />
</template>
