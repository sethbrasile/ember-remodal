import Ember from 'ember';
import EmberRemodal from './ember-remodal';
import layout from '../templates/components/er-open-button';

const {
  assert,
  computed,
  run: { scheduleOnce },
  Component
} = Ember;

export default Component.extend({
  layout,

  tagName: 'span',
  modal: null,

  didInitAttrs() {
    scheduleOnce('afterRender', this, '_registerWithModal');
  },

  _registerWithModal() {
    const modal = this.nearestOfType(EmberRemodal);
    assert('An "er-open-button" MUST be declared inside an "ember-remodal" component block.', !!modal);
    modal.registerButton(this);
    this.set('modal', modal);
  },

  destination: computed('modal', {
    get() {
      const modalId = this.get('modal.elementId');

      if (modalId) {
        return `button-outlet-for-${modalId}`;
      }
    }
  })
});
