import Ember from 'ember';

export default Ember.Controller.extend({
  remodal: Ember.inject.service(),

  actions: {
    openThenImmediatelyClose() {
      this.get('remodal').open('some-modal').then((modal) => modal.close());
    },

    openFirstAndCloseThenOpenSecond() {
      this.get('remodal').open('first-modal').then((first) => {
        return first.close();
      })

      .then(() => this.get('remodal').open('second-modal'))
      .then((second) => second.close());
    },

    openFirstThenOpenSecondOnTopOfFirst() {
      this.get('remodal').open('first-modal')

      .then(() => this.get('remodal').open('second-modal'))
      .then((second) => second.close());
    }
  }
});
