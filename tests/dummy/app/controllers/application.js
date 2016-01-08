import Ember from 'ember';

export default Ember.Controller.extend({
  showModal2: false,

  options1: {
    confirmButton: 'Confirm',
    openButton: 'Show Modal 1',
    cancelButton: 'Cancel',
    title: 'Block Form'
  },

  options2: {
    confirmButton: 'Confirm',
    cancelButton: 'Cancel',
    title: 'Inline Form',
    text: 'And triggered by a setting the passed-in "isOpen" to true'
  },

  actions: {
    showModal2() {
      this.set('showModal2', true);
    },

    showApplicationModal1() {
      const modal = this.get('remodal');

      modal.setProperties({
        title: 'Lasagna',
        text: 'Lorem Ipsum Dolar Sit Amet.',
        confirmButton: 'OK!'
      });

      modal.open();
    },

    showApplicationModal2() {
      const modal = this.get('remodal');
      modal.open('appModal2');
    },

    showApplicationModal3() {
      const modal = this.get('remodal.appModal3');

      modal.setProperties({
        title: 'Pizza',
        text: 'Lorem Ipsum Dolar Sit Amet.',
        confirmButton: 'OK!'
      });

      modal.open();
    },
  }
});
