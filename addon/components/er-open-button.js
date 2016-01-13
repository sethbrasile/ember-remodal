import Ember from 'ember';
import EmberRemodal from './ember-remodal';
import layout from '../templates/components/er-open-button';

const {
  assert,
  computed,
  Component
} = Ember;

export default Component.extend({
  layout,

  tagName: 'span',
  modal: null,

  didRender() {
    const modal = this.nearestOfType(EmberRemodal);
    assert('An "er-open-button" MUST be declared inside an "ember-remodal" component block.', !!modal);
    modal.set('customButton', true);
    this.set('modal', modal);
  },

  destination: computed('modal.elementId', {
    get() {
      const modalId = this.get('modal.elementId');

      if (modalId) {
        return `open-button-${modalId}`;
      }
    }
  })
});
