/* eslint-disable ember/no-on-calls-in-components */
/* eslint-disable ember/closure-actions */

import { inject as service } from '@ember/service';
import $ from 'jquery';
import { computed } from '@ember/object';
import { reads } from '@ember/object/computed';
import { getOwner } from '@ember/application';
import { on } from '@ember/object/evented';
import { Promise } from 'rsvp';
import { scheduleOnce, next } from '@ember/runloop';
import { sendEvent } from '@ember/object/events';
import Component from '@ember/component';
import layout from '../templates/components/ember-remodal';
import Ember from 'ember';
import { warnOnce, INTERNAL_CALL } from '../utils/deprecations';

export default Component.extend({
  layout,
  remodal: service(),
  attributeBindings: ['dataTestId:data-test-id'],
  classNames: ['remodal-component'],
  tagName: 'span',
  name: 'ember-remodal',
  modifier: '',
  _remodalInstance: null,
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
    scheduleOnce('afterRender', this, '_setProperties');
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

  modal: computed('_remodalInstance', {
    get() {
      warnOnce(
        this._getConfig(),
        'ember-remodal.modal-property',
        'The "modal" property (the wrapped jQuery remodal instance, including getState()) is removed in 3.0. Use the yielded isOpen / the component\'s state, or data-test-id selectors, instead.',
        'the-modal-property-and-getstate-is-removed'
      );
      return this.get('_remodalInstance');
    },
    set(key, value) {
      this.set('_remodalInstance', value);
      return value;
    }
  }),

  openDidFire: on('opened', function() {
    this.sendAction('onOpen');
  }),

  closeDidFire: on('closed', function() {
    this.sendAction('onClose');
  }),

  open(internal) {
    this._warnIfExternalCall(internal);
    return this._promiseAction('open');
  },

  close(internal) {
    this._warnIfExternalCall(internal);
    if (this.get('_remodalInstance')) {
      return this._promiseAction('close');
    } else {
      Ember.Logger.warn(
        'ember-remodal: You called "close" on a modal that has not yet been opened. This is not a big deal, but I thought you should know. The returned promise will immediately resolve.',
        false,
        { id: 'ember-remodal.close-called-on-unitialized-modal' }
      );
      return new Promise(resolve => resolve(this));
    }
  },

  _promiseAction(action) {
    let modal = this.get('modalId');
    let actionName = this._pastTense(action);

    this.send(action);

    return new Promise(resolve => {
      $(document).one(actionName, modal, () => resolve(this));
    });
  },

  _pastTense(action) {
    if (action[action.length - 1] === 'e') {
      return `${action}d`;
    } else {
      return `${action}ed`;
    }
  },

  _warnIfExternalCall(internal) {
    if (internal !== INTERNAL_CALL) {
      warnOnce(
        this._getConfig(),
        'ember-remodal.component-via-service',
        'Reaching the modal component through the service (e.g. this.remodal.get(name).open()) is removed in 3.0. Call service.open(name, options) / service.close(name) instead.',
        'reaching-the-modal-component-through-the-service-is-removed'
      );
    }
  },

  _setProperties() {
    let opts = this.get('options');

    if (opts) {
      this.setProperties(opts);
    }

    if (this.get('forService')) {
      this.get('remodal').set(this.get('name'), this);
    }
  },

  _registerObservers() {
    let modal = this.get('modalId');
    $(document).on('opened', modal, () => sendEvent(this, 'opened'));
    $(document).on('closed', modal, () => sendEvent(this, 'closed'));
  },

  _deregisterObservers() {
    let modal = this.get('modalId');
    $(document).off('opened', modal);
    $(document).off('closed', modal);
  },

  _destroyDomElements() {
    const modal = this.get('_remodalInstance');

    if (modal) {
      modal.destroy();
    }
  },

  _createInstanceAndOpen() {
    let config = this._getConfig();
    let appendTo = config && config.APP.rootElement ? config.APP.rootElement : '.ember-application';

    let modal = $(this.get('modalId')).remodal({
      appendTo,
      hashTracking: this.get('hashTracking'),
      closeOnOutsideClick: this.get('closeOnOutsideClick'),
      closeOnEscape: this.get('closeOnEscape'),
      modifier: this.get('modifier')
    });

    this.set('_remodalInstance', modal);
    this.send('open');
  },

  _checkForDeprecations() {
    let config = this._getConfig();

    // Debug: log config
    // console.log('_checkForDeprecations called, config:', config);

    warnOnce(
      config,
      'ember-remodal.v3-available',
      'ember-remodal 3.0 is available. Upgrade in two steps: 1) fix every deprecation this release logs, 2) run the readiness audit prompt from the migration guide, then upgrade.',
      'the-two-step-upgrade-path'
    );

    ['onOpen', 'onClose', 'onConfirm', 'onCancel'].forEach(actionName => {
      if (typeof this.get(actionName) === 'string') {
        warnOnce(
          config,
          'ember-remodal.string-actions',
          `"${actionName}" was passed as a string action name (first seen on "${this.get('name')}"). 3.0 only accepts functions — pass a closure action or a method instead.`,
          'string-actions--function-arguments'
        );
      }
    });

    if (this.get('hashTracking')) {
      warnOnce(
        config,
        'ember-remodal.hash-tracking',
        'hashTracking is removed in 3.0 — the router owns the URL in an Ember app. Drive service.open()/close() from a route or query param if you need URL-driven modals.',
        'hashtracking-removed'
      );
    }

    if (this.get('class')) {
      warnOnce(
        config,
        'ember-remodal.class-attribute',
        'class= in curly invocation stops merging onto the element in 3.0 (Glimmer treats it as an ignored argument). Use angle-bracket invocation (<EmberRemodal class="...">), or @modalClasses for the modal card.',
        'ember-remodal-class-no-longer-merges-class'
      );
    }
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
        warnOnce(
          config,
          'ember-remodal.disable-animation-while-testing',
          'disableAnimationWhileTesting only works with the classic resolver in 3.0. Prefer setupRemodal(hooks, { disableAnimation: true }) from ember-remodal/test-support.',
          'disableanimationwhiletesting--classic-resolver-only'
        );
      }
    }
  },

  _getConfig() {
    return getOwner(this).resolveRegistration('config:environment');
  },

  _openModal() {
    this.get('_remodalInstance').open();
  },

  _closeModal() {
    this.get('_remodalInstance').close();
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
      if (this.get('_remodalInstance')) {
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
