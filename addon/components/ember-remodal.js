import Ember from 'ember';
import layout from '../templates/components/ember-remodal';

const {
  observer,
  inject,
  computed,
  computed: { oneWay },
  RSVP: { Promise },
  Component
} = Ember;

export default Component.extend({
  layout,

  remodal: inject.service(),

  tagName: 'span',
  name: 'modal',
  modifier: '',
  modal: null,
  options: null,
  closeOnEscape: true,
  closeOnCancel: true,
  closeOnConfirm: true,
  hashTracking: false,
  closeOnOutsideClick: true,
  forService: false,
  isApplicationModal: false,
  disableForeground: false,
  disableAnimation: false,
  disableNativeClose: oneWay('disableForeground'),

  erOpenButton: false,
  erCancelButton: false,
  erConfirmButton: false,

  didInitAttrs() {
    const opts = this.get('options');
    const modal = `[data-remodal-id=${this.get('elementId')}]`;
    const isApplicationModal = this.get('isApplicationModal');

    if (opts) {
      this.setProperties(opts);
    }

    $(document).on('closed', modal, () => {
      this.sendAction('onClose');
    });

    $(document).on('opened', modal, () => {
      this.sendAction('onOpen');
    });

    if (this.get('forService') || isApplicationModal) {

      if (isApplicationModal) {
        Ember.deprecate('ember-remodal\'s "isApplicationModal" is deprecated and will be removed in ember-remodal 1.0.0. Use "forService" instead.');
      }

      this.get('remodal').set(this.get('name'), this);
    }

    if (this.get('linkButton')) {
      Ember.deprecate('ember-remodal\'s "linkButton" is deprecated and will be removed in ember-remodal 1.0.0. It was a stupid name. You should use "openLink" instead.');
    }
  },

  animationState: computed('disableAnimation', {
    get() {
      if (this.get('disableAnimation')) {
        return 'disable-animation';
      } else {
        return '';
      }
    }
  }),

  open() {
    const modal = `[data-remodal-id=${this.get('elementId')}]`;

    return new Promise((resolve) => {
      $(document).on('opened', modal, () => {
        resolve();
      });

      this.send('open');
    });
  },

  close() {
    const modal = `[data-remodal-id=${this.get('elementId')}]`;

    return new Promise((resolve) => {
      $(document).on('closed', modal, () => {
        resolve();
      });

      this.send('close');
    });
  },

  actions: {
    confirm() {
      this.sendAction('onConfirm');

      if (this.get('closeOnConfirm')) {
        this.send('close');
      }
    },

    cancel() {
      this.sendAction('onCancel');

      if (this.get('closeOnCancel')) {
        this.send('close');
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

      this.set('modal', modal.remodal(opts));
      this.get('modal').open();
    },

    close() {
      this.get('modal').close();
    }
  }
});
