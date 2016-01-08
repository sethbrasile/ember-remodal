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
  buttonClasses: alias('modal.buttonClasses'),
  modifier: alias('modal.modifier'),
  closeOnEscape: alias('modal.closeOnEscape'),
  closeOnCancel: alias('modal.closeOnCancel'),
  closeOnConfirm: alias('modal.closeOnConfirm'),
  hashTracking: alias('modal.hashTracking'),
  closeOnOutsideClick: alias('modal.closeOnOutsideClick'),

  open(name='modal', opts) {
    const modal = this.get(name);

    if (modal) {
      if (opts) {
        modal.setProperties(opts);
      }

      modal.set('isOpen', true);
    } else {
      this.modalNotSetError(name);
    }
  },

  close(name='modal') {
    const modal = this.get(name);

    if (modal) {
      modal.set('isOpen', false);
    } else {
      this.modalNotSetError(name);
    }
  },

  modalNotSetError(name) {
    console.error(`"${name}" can not be opened. In order to use ember-remodal as a service, you must include an {{ember-remodal}} instance in your application template, with "isApplicationModal=true"`);
  }
});
