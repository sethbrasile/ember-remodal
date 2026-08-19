import { on } from '@ember/modifier';
import EmberRemodal from '#src/components/ember-remodal.gts';

<template>
  <EmberRemodal
    @openButton="Open with Escape suppressed"
    @openButtonClasses="demo-button"
    @title="Escape is suppressed here"
    @closeOnEscape={{false}}
    @hasCustomKeyboardExit={{true}}
    as |m|
  >
    <p>Escape does nothing on this modal — the button below is the declared
      keyboard exit.</p>
    <button type="button" class="remodal-cancel" {{on "click" m.closeAction}}>I
      agree, close this</button>
  </EmberRemodal>
</template>
