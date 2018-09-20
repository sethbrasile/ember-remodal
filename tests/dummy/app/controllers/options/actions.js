import { inject as service } from '@ember/service';
import Controller from '@ember/controller';

export default Controller.extend({
  notify: service('notify'),

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
