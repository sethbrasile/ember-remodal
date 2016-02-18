import Ember from 'ember';
import layout from '../templates/components/ember-remodal';

const {
  inject,
  computed,
  computed: { oneWay },
  on,
  RSVP: { Promise },
  run: { next, scheduleOnce },
  sendEvent,
  Component
} = Ember;

export default Component.extend({
  layout,
  remodal: inject.service(),
  attributeBindings: ['dataTestId:data-test-id'],
  classNames: ['remodal-component'],
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
  disableForeground: false,
  disableAnimation: false,
  disableNativeClose: oneWay('disableForeground'),
  erOpenButton: false,
  erCancelButton: false,
  erConfirmButton: false,

  didInitAttrs() {
    let opts = this.get('options');

    if (opts) {
      this.setProperties(opts);
    }

    if (this.get('forService')) {
      this.get('remodal').set(this.get('name'), this);
    }

    scheduleOnce('afterRender', this, '_registerObservers');
    scheduleOnce('afterRender', this, '_checkForDeprecations');
  },

  willDestroy() {
    scheduleOnce('afterRender', this, '_deregisterObservers');
  },

  modalId: computed('elementId', {
    get() {
      return `[data-remodal-id=${this.get('elementId')}]`;
    }
  }),

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
    let modal = this.get('modalId');

    return new Promise((resolve) => {
      Ember.$(document).one('opened', modal, () => {
        resolve(this);
      });

      this.send('open');
    });
  },

  close() {
    let modal = this.get('modalId');

    return new Promise((resolve) => {
      Ember.$(document).one('closed', modal, () => {
        resolve(this);
      });

      this.send('close');
    });
  },

  _createInstanceAndOpen() {
    let modal = Ember.$(this.get('modalId')).remodal({
      hashTracking: this.get('hashTracking'),
      closeOnOutsideClick: this.get('closeOnOutsideClick'),
      closeOnEscape: this.get('closeOnEscape'),
      modifier: this.get('modifier')
    });

    this.set('modal', modal);
    this.send('open');
  },

  _registerObservers() {
    let modal = this.get('modalId');
    Ember.$(document).on('opened', modal, () => sendEvent(this, 'opened'));
    Ember.$(document).on('closed', modal, () => sendEvent(this, 'closed'));
  },

  _deregisterObservers() {
    let modal = this.get('modalId');
    Ember.$(document).off('opened', modal);
    Ember.$(document).off('closed', modal);
  },

  openDidFire: on('opened', function() {
    this.sendAction('onOpen');
  }),

  closeDidFire: on('closed', function() {
    this.sendAction('onClose');
  }),

  _checkForDeprecations() {
    // Deprecations go here
  },

  _openModal() {
    this.get('modal').open();
  },

  _closeModal() {
    this.get('modal').close();
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
      if (this.get('modal')) {
        scheduleOnce('afterRender', this, '_openModal');
      } else {
        scheduleOnce('afterRender', this, '_createInstanceAndOpen');
      }
    },

    close() {
      next(this, '_closeModal');
    }
  }
});
