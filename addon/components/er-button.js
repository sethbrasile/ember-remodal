/* eslint-disable ember/closure-actions */

import { computed } from '@ember/object';
import { getOwner } from '@ember/application';
import Component from '@ember/component';
import layout from '../templates/components/er-button';
import { warnOnce } from '../utils/deprecations';

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
  }),

  didInsertElement() {
    this._super(...arguments);

    if (this.get('_yielded') !== true) {
      warnOnce(
        getOwner(this).resolveRegistration('config:environment'),
        'ember-remodal.er-button-direct',
        'Invoking ember-remodal/er-button directly is broken by 3.0: the import path moved, modalId= became @destination (an Element, not an id), and action= became @onClick. Prefer the yielded m.open / m.confirm / m.cancel, which bind both for you.',
        'er-button-the-import-path-moved-and-both-arguments-were-renamed'
      );
    }
  }
});
