import { assert } from '@ember/debug';
import { computed } from '@ember/object';
import { getOwner } from '@ember/application';
import Service from '@ember/service';
import { warnOnce, INTERNAL_CALL } from '../utils/deprecations';

function deprecatedOptionAlias(optionName) {
  let dependentKey = `ember-remodal.${optionName}`;

  return computed(dependentKey, {
    get() {
      this._warnOptionAlias(optionName);
      return this.get(dependentKey);
    },
    set(key, value) {
      this._warnOptionAlias(optionName);
      this.set(dependentKey, value);
      return value;
    }
  });
}

export default Service.extend({
  modal: null,
  title: deprecatedOptionAlias('title'),
  text: deprecatedOptionAlias('text'),
  confirmButton: deprecatedOptionAlias('confirmButton'),
  cancelButton: deprecatedOptionAlias('cancelButton'),
  disableNativeClose: deprecatedOptionAlias('disableNativeClose'),
  disableForeground: deprecatedOptionAlias('disableForeground'),
  disableAnimation: deprecatedOptionAlias('disableAnimation'),
  buttonClasses: deprecatedOptionAlias('buttonClasses'),
  modifier: deprecatedOptionAlias('modifier'),
  closeOnEscape: deprecatedOptionAlias('closeOnEscape'),
  closeOnCancel: deprecatedOptionAlias('closeOnCancel'),
  closeOnConfirm: deprecatedOptionAlias('closeOnConfirm'),
  hashTracking: deprecatedOptionAlias('hashTracking'),
  closeOnOutsideClick: deprecatedOptionAlias('closeOnOutsideClick'),

  open(name = 'ember-remodal', opts = null) {
    let modal = this.get(name);

    if (modal) {
      if (opts) {
        modal.setProperties(opts);
      }

      return modal.open(INTERNAL_CALL);
    } else {
      this._modalNotSetError(name);
    }
  },

  close(name = 'ember-remodal') {
    let modal = this.get(name);

    if (modal) {
      return modal.close(INTERNAL_CALL);
    } else {
      this._modalNotSetError(name);
    }
  },

  _warnOptionAlias(optionName) {
    warnOnce(
      this._getConfig(),
      'ember-remodal.service-option-aliases',
      `The service's option alias properties are removed in 3.0 (first seen: "${optionName}"). Pass options through service.open(name, options) instead.`,
      'the-services-property-aliases-are-removed'
    );
  },

  _getConfig() {
    return getOwner(this).resolveRegistration('config:environment');
  },

  _modalNotSetError(name) {
    warnOnce(
      this._getConfig(),
      'ember-remodal.open-on-unrendered-name',
      `open()/close() was called for "${name}", which is not currently rendered. 3.0 returns a rejected promise in every build (2.x throws in development and silently no-ops in production).`,
      'serviceopen--close-on-an-unrendered-name-always-reject'
    );
    assert(
      `The requested modal, "${name}" can not be opened because it is not rendered in the current route. In order to use ember-remodal as a service, an instance of {{ember-remodal}} must currently be rendered, with "forService=true". Try putting it in your application template.`
    );
  }
});