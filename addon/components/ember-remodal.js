import Ember from 'ember';
import layout from '../templates/components/ember-remodal';

const {
  deprecate,
  inject,
  computed,
  computed: { oneWay },
  on,
  RSVP: { Promise },
  run: { scheduleOnce },
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
  isApplicationModal: false,
  disableForeground: false,
  disableAnimation: false,
  disableNativeClose: oneWay('disableForeground'),
  erOpenButton: false,
  erCancelButton: false,
  erConfirmButton: false,

  didInitAttrs() {
    const opts = this.get('options');

    if (opts) {
      this.setProperties(opts);
    }

    if (this.get('forService') || this.get('isApplicationModal')) {
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
    const modal = this.get('modalId');

    return new Promise((resolve) => {
      Ember.$(document).one('opened', modal, () => {
        resolve(this);
      });

      this.send('open');
    });
  },

  close() {
    const modal = this.get('modalId');

    return new Promise((resolve) => {
      Ember.$(document).one('closed', modal, () => {
        resolve(this);
      });

      this.send('close');
    });
  },

  _createInstanceAndOpen() {
    const modal = Ember.$(this.get('modalId')).remodal({
      hashTracking: this.get('hashTracking'),
      closeOnOutsideClick: this.get('closeOnOutsideClick'),
      closeOnEscape: this.get('closeOnEscape'),
      modifier: this.get('modifier')
    });

    this.set('modal', modal);
    this.send('open');
  },

  _registerObservers() {
    const modal = this.get('modalId');
    Ember.$(document).on('opened', modal, () => sendEvent(this, 'opened'));
    Ember.$(document).on('closed', modal, () => sendEvent(this, 'closed'));
  },

  _deregisterObservers() {
    const modal = this.get('modalId');
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
    deprecate(
      'ember-remodal\'s "linkButton" is deprecated and will be removed in ember-remodal 1.0.0. It was a stupid name. You should use "openLink" instead.',
      !this.get('linkButton'),
      { id: 'ember-remodal.linkButton', until: '1.0.0' }
    );

    deprecate(
      'ember-remodal\'s "isApplicationModal" is deprecated and will be removed in ember-remodal 1.0.0. Use "forService" instead.',
      !this.get('isApplicationModal'),
      { id: 'ember-remodal.isApplicationModal', until: '1.0.0' }
    );
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
      scheduleOnce('afterRender', this, '_closeModal');
    }
  }
});
