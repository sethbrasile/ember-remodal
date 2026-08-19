import EmberRemodal from '#src/components/ember-remodal.gts';

<template>
  <EmberRemodal
    @openButton="Open themed modal"
    @openButtonClasses="demo-button"
    @modifier="demo-midnight"
    @title="Midnight theme"
    @text="Same component, restyled entirely from the app's stylesheet."
    @confirmButton="Nice"
  />
</template>
