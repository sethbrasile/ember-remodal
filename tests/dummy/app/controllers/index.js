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
    title: 'Block Form',
    dataTestId: 'simple-inline',
    disableAnimation: true
  },

  options2: {
    confirmButton: 'Confirm',
    cancelButton: 'Cancel',
    title: 'Inline Form',
    openLink: 'Show Modal 2',
    text: 'Triggered by the included <a> tag.'
  },

  actions: {
    onOpenWasFired() {
      console.log('the onOpen action was fired');
    },

    onCloseWasFired() {
      console.log('the onClose action was fired');
    },

    showApplicationModal1() {
      let modal = this.get('remodal');

      modal.setProperties({
        title: 'Modal triggered with the "remodal" service',
        text: 'This modal is triggered by adding an un-named "application modal" to the "application" template and calling this.get("remodal").open()',
        confirmButton: 'OK!'
      });

      modal.open();
    },

    showApplicationModal2() {
      this.get('remodal').open('appModal2').then((modal) => {
        console.log('opening a modal can return a promise!');
        console.log(`${modal.get('name')} was opened!`);
      });
    },

    showApplicationModal3() {
      this.get('remodal').open('appModal3', {
        title: 'Named Modal triggered with the "remodal" service',
        text: 'This modal is triggered by adding a named "application modal" to the "application" template and calling this.get("remodal").open("name")',
        confirmButton: 'OK!'
      })

      .then((modal) => {
        console.log(`${modal.get('name')} was opened!`);
        return modal.close();
      })

      .then((modal) => {
        console.log(`${modal.get('name')} was closed!`);
      });
    }
  }
});
