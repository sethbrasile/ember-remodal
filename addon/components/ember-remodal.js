import Ember from 'ember';
import layout from '../templates/components/ember-remodal';

const {
  inject,
  computed,
  computed: { reads },
  getOwner,
  on,
  RSVP: { Promise },
  run: { next, scheduleOnce },
  sendEvent,
  warn,
  Component
} = Ember;

export default Component.extend({
  layout,
  warn,
  remodal: inject.service(),
  attributeBindings: ['dataTestId:data-test-id'],
  classNames: ['remodal-component'],
  tagName: 'span',
  name: 'ember-remodal',
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
  disableNativeClose: reads('disableForeground'),
  erOpenButton: false,
  erCancelButton: false,
  erConfirmButton: false,

  didInsertElement() {
    let opts = this.get('options');

    if (opts) {
      this.setProperties(opts);
    }

    if (this.get('forService')) {
      this.get('remodal').set(this.get('name'), this);
    }

    scheduleOnce('afterRender', this, '_registerObservers');
    scheduleOnce('afterRender', this, '_checkForDeprecations');
    scheduleOnce('afterRender', this, '_checkForTestingEnv');
  },

  willDestroyElement() {
    scheduleOnce('destroy', this, '_destroyDomElements');
    scheduleOnce('destroy', this, '_deregisterObservers');
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

  openDidFire: on('opened', function() {
    this.sendAction('onOpen');
  }),

  closeDidFire: on('closed', function() {
    this.sendAction('onClose');
  }),

  open() {
    return this._promiseAction('open');
  },

  close() {
    if (this.get('modal')) {
      return this._promiseAction('close');
    } else {
      this.get('warn')(
        'ember-remodal: You called "close" on a modal that has not yet been opened. This is not a big deal, but I thought you should know. The returned promise will immediately resolve.', false,
        { id: 'ember-remodal.close-called-on-unitialized-modal' }
      );
      return new Promise((resolve) => resolve(this));
    }
  },

  _promiseAction(action) {
    let modal = this.get('modalId');
    let actionName = this._pastTense(action);

    this.send(action);

    return new Promise((resolve) => {
      Ember.$(document).one(actionName, modal, () => resolve(this));
    });
  },

  _pastTense(action) {
    if (action[action.length - 1] === 'e') {
      return `${action}d`;
    } else {
      return `${action}ed`;
    }
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

  _destroyDomElements() {
    const modal = this.get('modal');

    if (modal) {
      modal.destroy();
    }
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

  _checkForDeprecations() {
    // Deprecations go here
  },

  _checkForTestingEnv() {
    let config = this._getConfig();

    if (config) {
      let env = config.environment;
      let remodalConfig = config['ember-remodal'];
      let disableAnimation;

      if (remodalConfig) {
        disableAnimation = remodalConfig.disableAnimationWhileTesting;
      }

      if (disableAnimation && env === 'test') {
        this.set('disableAnimation', true);
      }
    }
  },

  _getConfig() {
    return getOwner(this).resolveRegistration('config:environment');
  },

  _openModal() {
    this.get('modal').open();
  },

  _closeModal() {
    this.get('modal').close();
  },

  _closeOnCondition(condition) {
    this.sendAction(`on${condition}`);

    if (this.get(`closeOn${condition}`)) {
      this.send('close');
    }
  },

  actions: {
    confirm() {
      this._closeOnCondition('Confirm');
    },

    cancel() {
      this._closeOnCondition('Cancel');
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
