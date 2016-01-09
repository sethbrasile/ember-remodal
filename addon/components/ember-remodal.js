import Ember from 'ember';
import layout from '../templates/components/ember-remodal';

const {
  observer,
  inject,
  computed: { oneWay },
  Component
} = Ember;

export default Component.extend({
  remodal: inject.service(),

  layout,
  tagName: 'span',
  name: 'modal',
  modifier: '',
  modal: null,
  options: null,
  isOpen: false,
  shouldClose: false,
  closeOnEscape: true,
  closeOnCancel: true,
  closeOnConfirm: true,
  hashTracking: false,
  closeOnOutsideClick: true,
  forService: false,
  disableForeground: false,
  disableNativeClose: oneWay('disableForeground'),

  didInitAttrs() {
    const opts = this.get('options');
    const modal = `[data-remodal-id=${this.get('elementId')}]`;

    if (opts) {
      this.setProperties(opts);
    }

    $(document).on('closing', modal, () => {
      this.sendAction('onClose');
      this.set('shouldClose', false);
      this.set('isOpen', false);
    });

    $(document).on('opening', modal, () => {
      this.sendAction('onOpen');
    });

    if (this.get('forService')) {
      this.get('remodal').set(this.get('name'), this);
    }
  },

  modalisOpen: observer('isOpen', function() {
    if (this.get('isOpen')) {
      this.send('open');
    } else {
      this.send('close');
    }
  }),

  modalShouldClose: observer('shouldClose', function() {
    if (this.get('shouldClose')) {
      this.send('close');
    }
  }),

  open() {
    this.send('open');
  },

  close() {
    this.send('close');
  },

  actions: {
    openModal() {
      this.set('isOpen', true);
    },

    confirm() {
      this.sendAction('onConfirm');

      if (this.get('closeOnConfirm')) {
        this.set('shouldClose', true);
      }
    },

    cancel() {
      this.sendAction('onCancel');

      if (this.get('closeOnCancel')) {
        this.set('shouldClose', true);
      }
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

    close() {
      this.get('modal').close();
    }
  }
});
