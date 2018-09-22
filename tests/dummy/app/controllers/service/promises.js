import { inject as service } from '@ember/service';
import Controller from '@ember/controller';

export default Controller.extend({
  remodal: service(),

  actions: {
    openThenImmediatelyClose() {
      this.get('remodal')
        .open('some-modal')
        .then(modal => modal.close());
    },

    openFirstAndCloseThenOpenSecond() {
      this.get('remodal')
        .open('first-modal')
        .then(first => {
          return first.close();
        })

        .then(() => this.get('remodal').open('second-modal'))
        .then(second => second.close());
    },

    openFirstThenOpenSecondOnTopOfFirst() {
      this.get('remodal')
        .open('first-modal')

        .then(() => this.get('remodal').open('second-modal'))
        .then(second => second.close());
    }
  }
});
