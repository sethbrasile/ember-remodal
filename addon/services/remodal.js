import Ember from 'ember';

const {
  computed: { alias },
  Service
} = Ember;

export default Service.extend({
  modal: null,
  title: alias('modal.title'),
  text: alias('modal.text'),
  confirmButton: alias('modal.confirmButton'),
  cancelButton: alias('modal.cancelButton'),
  disableNativeClose: alias('modal.disableNativeClose'),
  disableForeground: alias('modal.disableForeground'),
  disableAnimation: alias('modal.disableAnimation'),
  buttonClasses: alias('modal.buttonClasses'),
  modifier: alias('modal.modifier'),
  closeOnEscape: alias('modal.closeOnEscape'),
  closeOnCancel: alias('modal.closeOnCancel'),
  closeOnConfirm: alias('modal.closeOnConfirm'),
  hashTracking: alias('modal.hashTracking'),
  closeOnOutsideClick: alias('modal.closeOnOutsideClick'),

  open(suppliedName, opts) {
    const name = suppliedName || 'modal';
    const modal = this.get(name);

    if (modal) {
      if (opts) {
        modal.setProperties(opts);
      }

      return modal.open();
    } else {
      this._modalNotSetError(name);
    }
  },

  close(suppliedName) {
    const name = suppliedName || 'modal';
    const modal = this.get(name);

    if (modal) {
      return modal.close();
    } else {
      this._modalNotSetError(name);
    }
  },

  _modalNotSetError(name) {
    console.error(`The requested modal, "${name}" can not be opened because it is not rendered in the current route. In order to use ember-remodal as a service, an instance of {{ember-remodal}} must currently be rendered, with "forService=true". Try putting it in your application template.`);
  }
});
