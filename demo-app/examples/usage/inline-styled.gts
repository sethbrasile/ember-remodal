import EmberRemodal from '#src/components/ember-remodal.gts';

<template>
  <EmberRemodal
    @openButton="Open styled modal"
    @openButtonClasses="demo-button"
    @modifier="demo-midnight"
    @title="A themed modal"
    @text="This modal uses @modifier plus custom classes on its confirm and cancel buttons."
    @confirmButton="Great"
    @cancelButton="Nope"
    @confirmButtonClasses="demo-pill"
    @cancelButtonClasses="demo-pill"
  />
</template>
