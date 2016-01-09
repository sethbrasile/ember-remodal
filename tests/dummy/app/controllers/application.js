import Ember from 'ember';

const {
  inject,
  Controller
} = Ember;

export default Controller.extend({
  remodal: inject.service(),

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
        title: 'Modal triggered with the "remodal" service',
        text: 'This modal is triggered by adding an un-named "application modal" to the "application" template and calling this.get("remodal").open()',
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
        title: 'Named Modal triggered with the "remodal" service',
        text: 'This modal is triggered by adding a named "application modal" to the "application" template and calling this.get("remodal").open("name")',
        confirmButton: 'OK!'
      });

      modal.open();
    }
  }
});
