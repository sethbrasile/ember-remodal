import Ember from 'ember';
import ButtonMixin from '../mixins/er-button';
import layout from '../templates/components/er-open-button';

const {
  computed,
  Component
} = Ember;

export default Component.extend(ButtonMixin, {
  layout,
  name: 'er-open-button',

  destination: computed('modal.elementId', {
    get() {
      let modalId = this.get('modal.elementId');

      if (modalId) {
        return `open-button-${modalId}`;
      }
    }
  })
});
