import Ember from 'ember';

export default Ember.Controller.extend({
  remodal: Ember.inject.service(),
  selectedDog: null,

  actions: {
    openDogModal(dog) {
      this.set('selectedDog', dog);
      this.get('remodal').open('dog-modal');
    }
  }
});
