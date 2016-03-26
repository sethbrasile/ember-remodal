export default Ember.Whatever.extend({
  remodal: Ember.inject.service(),

  actions: {
    openModal() {
      this.get('remodal').open('ember-remodal');
    }
  }
});
