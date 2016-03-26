export default Ember.Whatever.extend({
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
