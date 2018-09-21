import { inject as service } from '@ember/service';
import Controller from '@ember/controller';

export default Controller.extend({
  remodal: service(),
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
