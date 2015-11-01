import Ember from 'ember';

const {
  computed: { alias },
  Controller
} = Ember;

export default Controller.extend({
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

    showApplicationModal() {
      const modal = this.get('remodal');

      modal.setProperties({
        title: 'Lasagna',
        text: 'Lorem Ipsum Dolar Sit Amet.',
        confirmButton: 'OK!'
      });

      modal.open();
    }
  }
});
