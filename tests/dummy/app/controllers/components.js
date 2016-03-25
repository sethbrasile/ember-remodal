import Ember from 'ember';

export default Ember.Controller.extend({
  legacy: false,

  actions: {
    legacy() {
      this.set('legacy', true);
    },

    current() {
      this.set('legacy', false);
    }
  }
});
