import EmberRemodal from '#src/components/ember-remodal.gts';

<template>
  <EmberRemodal
    @openButton="Open outlined modal"
    @openButtonClasses="demo-button"
    @modifier="demo-outline"
    @title="Targeting parts"
    @text="Square corners, an accent border, and outlined buttons — all from demo-outline.css."
    @confirmButton="Confirm"
    @cancelButton="Cancel"
  />
</template>
