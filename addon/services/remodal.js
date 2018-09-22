import { assert } from '@ember/debug';
import { alias } from '@ember/object/computed';
import Service from '@ember/service';

export default Service.extend({
  modal: null,
  title: alias('ember-remodal.title'),
  text: alias('ember-remodal.text'),
  confirmButton: alias('ember-remodal.confirmButton'),
  cancelButton: alias('ember-remodal.cancelButton'),
  disableNativeClose: alias('ember-remodal.disableNativeClose'),
  disableForeground: alias('ember-remodal.disableForeground'),
  disableAnimation: alias('ember-remodal.disableAnimation'),
  buttonClasses: alias('ember-remodal.buttonClasses'),
  modifier: alias('ember-remodal.modifier'),
  closeOnEscape: alias('ember-remodal.closeOnEscape'),
  closeOnCancel: alias('ember-remodal.closeOnCancel'),
  closeOnConfirm: alias('ember-remodal.closeOnConfirm'),
  hashTracking: alias('ember-remodal.hashTracking'),
  closeOnOutsideClick: alias('ember-remodal.closeOnOutsideClick'),

  open(name = 'ember-remodal', opts = null) {
    let modal = this.get(name);

    if (modal) {
      if (opts) {
        modal.setProperties(opts);
      }

      return modal.open();
    } else {
      this._modalNotSetError(name);
    }
  },

  close(name = 'ember-remodal') {
    let modal = this.get(name);

    if (modal) {
      return modal.close();
    } else {
      this._modalNotSetError(name);
    }
  },

  _modalNotSetError(name) {
    assert(
      `The requested modal, "${name}" can not be opened because it is not rendered in the current route. In order to use ember-remodal as a service, an instance of {{ember-remodal}} must currently be rendered, with "forService=true". Try putting it in your application template.`
    );
  }
});
