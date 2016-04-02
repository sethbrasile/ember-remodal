import Ember from 'ember';

export default Ember.Controller.extend({
  notify: Ember.inject.service('notify'),

  actions: {
    notifyOpened() {
      this.get('notify').info('Opened');
    },

    notifyConfirmed() {
      this.get('notify').success('Confirmed');
    },

    notifyCanceled() {
      this.get('notify').error('Canceled');
    },

    notifyClosed() {
      this.get('notify').warning('Closed');
    }
  }
});
