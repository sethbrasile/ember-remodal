import EmberRemodal from '#src/components/ember-remodal.gts';

<template>
  <EmberRemodal
    @openButton="Titled modal"
    @openButtonClasses="demo-button"
    @title="Named by title"
    @text="The <h2> gets a generated id, and the dialog points aria-labelledby at it."
    @confirmButton="OK"
  />
  <EmberRemodal
    @openButton="ariaLabel modal"
    @openButtonClasses="demo-button subtle"
    @ariaLabel="Named by ariaLabel"
    @disableForeground={{true}}
  >
    <div class="demo-frameless">
      <p>No visible title here — ariaLabel names this dialog instead.</p>
    </div>
  </EmberRemodal>
  <EmberRemodal
    @openButton="ariaLabelledBy modal"
    @openButtonClasses="demo-button subtle"
    @ariaLabelledBy="demo-named-dialog-heading"
  >
    <h2 id="demo-named-dialog-heading">Named by ariaLabelledBy</h2>
    <p>This heading is on-screen content, and the dialog points at it instead of
      duplicating its text into ariaLabel.</p>
  </EmberRemodal>
</template>
