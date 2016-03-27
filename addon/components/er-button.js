import Ember from 'ember';
import layout from '../templates/components/er-button';

const {
  computed,
  Component
} = Ember;

export default Component.extend({
  layout,
  tagName: 'span',

  click() {
    this.sendAction();
  },

  destination: computed('modalId', {
    get() {
      let modalId = this.get('modalId');

      if (modalId) {
        return `open-button-${modalId}`;
      }
    }
  })
});
