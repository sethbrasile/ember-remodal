import Ember from 'ember';
import layout from './template';

const { Component, observer } = Ember;

export default Component.extend({
  layout,
  tagName: '',
  modifier: '',
  modal: null,
  options: null,
  showModal: false,
  closeOnEscape: true,
  hashTracking: false,
  closeOnOutsideClick: true,

  didInitAttrs() {
    const opts = this.get('options');

    if (opts) {
      this.setProperties(opts);
    }
  },

  modalChange: observer('showModal', function() {
    if (this.get('showModal')) {
      this.send('open');
    } else {
      this.send('close');
    }
  }),

  actions: {
    setCloseToTrue() {
      this.sendAction('setCloseToTrue');
    },

    open() {
      const modal = $(`[data-remodal-id=${this.get('elementId')}]`);
      const opts = {
        hashTracking: this.get('hashTracking'),
        closeOnOutsideClick: this.get('closeOnOutsideClick'),
        closeOnEscape: this.get('closeOnEscape'),
        modifier: this.get('modifier')
      };

      this.sendAction('onOpen');
      this.set('modal', modal.remodal(opts));
      this.get('modal').open();
    },

    confirm() {
      this.sendAction('onConfirm');
      this.set('showModal', false);
      this.send('close');
    },

    cancel() {
      this.sendAction('onCancel');
      this.set('showModal', false);
      this.send('close');
    },

    close() {
      this.sendAction('onClose');
      this.get('modal').close();
    }
  }
});
