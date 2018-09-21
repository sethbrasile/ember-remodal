/* eslint-disable ember/closure-actions */

import { computed } from '@ember/object';
import Component from '@ember/component';
import layout from '../templates/components/er-button';

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
