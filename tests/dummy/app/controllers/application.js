import Ember from 'ember';

export default Ember.Controller.extend({
  showModal2: false,
  close: false,

  options1: {
    confirmLabel: 'Confirm',
    openLabel: 'Show Modal 1',
    cancelLabel: 'Cancel',
    title: 'Block Form'
  },

  options2: {
    confirmLabel: 'Confirm',
    cancelLabel: 'Cancel',
    title: 'Inline Form',
    text: 'And triggered by a setting a passed-in property to true'
  },

  actions: {
    showModal2() {
      this.set('showModal2', true);
    },
    resetModal2() {
      this.set('showModal2', false);
    }
  }
});
