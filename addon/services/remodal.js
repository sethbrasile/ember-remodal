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

  open() {
    const modal = this.get('modal');

    if (modal) {
      modal.set('isOpen', true);
    } else {
      this.modalNotSetError();
    }
  },

  close() {
    const modal = this.get('modal');

    if (modal) {
      modal.set('isOpen', false);
    } else {
      this.modalNotSetError();
    }
  },

  modalNotSetError() {
    console.error('In order to use ember-remodal as a service, you must include an {{ember-remodal}} instance in your application template, with "isApplicationModal=true"');
  }
});
