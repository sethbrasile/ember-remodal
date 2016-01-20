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
    linkButton: 'Show Modal 2',
    text: "Triggered by the included <a> tag. This modal also has it's animations disabled.",
    disableAnimation: true
  },

  actions: {
    onOpenWasFired() {
      console.log('the onOpen action was fired');
    },

    onCloseWasFired() {
      console.log('the onClose action was fired');
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

      modal.open('appModal2').then(() => {
        console.log('opening a modal can return a promise!');
      });
    },

    showApplicationModal3() {
      const modal = this.get('remodal.appModal3');

      modal.setProperties({
        title: 'Named Modal triggered with the "remodal" service',
        text: 'This modal is triggered by adding a named "application modal" to the "application" template and calling this.get("remodal").open("name")',
        confirmButton: 'OK!'
      });

      modal.open().then(() => {
        Ember.run.later(() => {
          modal.close().then(() => {
            console.log('Closing a modal can happen programmatically. It can also return a promise!');
          });
        }, 1000);
      });
    }
  }
});
