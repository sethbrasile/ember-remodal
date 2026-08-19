import EmberRemodal from '#src/components/ember-remodal.gts';

<template>
  <EmberRemodal
    @openButton="Open inline modal"
    @openButtonClasses="demo-button"
    @title="Hello from ember-remodal"
    @text="This whole modal — trigger included — comes from a single self-closing component invocation."
    @confirmButton="Sounds good"
    @cancelButton="No thanks"
  />
</template>
