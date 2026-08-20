import EmberRemodal from '#src/components/ember-remodal.gts';

<template>
  <EmberRemodal
    @openLink="Open link-style modal"
    @title="Content options"
    @text="title, text, confirmButton, cancelButton, and an openLink trigger."
    @confirmButton="Got it"
    @cancelButton="Never mind"
  />
  <EmberRemodal
    @openButton="Open unnamed modal"
    @openButtonClasses="demo-button subtle"
    @closeButtonLabel="Dismiss"
    @ariaLabel="A modal with no visible title"
  >
    <p>No
      <code>@title</code>
      here —
      <code>@ariaLabel</code>
      names the dialog instead, and the built-in close button's label is
      overridden to "Dismiss".</p>
  </EmberRemodal>
</template>
