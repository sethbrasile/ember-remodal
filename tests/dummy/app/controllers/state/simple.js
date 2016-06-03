import Ember from 'ember';

export default Ember.Controller.extend({
  remodal: Ember.inject.service(),
  stateFromController: null,

  actions: {
    openState1() {
      this.set('stateFromController', 'state 1');
      this.get('remodal').open('state-modal');
    },

    openState2() {
      this.set('stateFromController', 'state 2');
      this.get('remodal').open('state-modal');
    }
  }
});
