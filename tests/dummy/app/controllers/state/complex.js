import { inject as service } from '@ember/service';
import Controller from '@ember/controller';

export default Controller.extend({
  remodal: service(),
  selectedDog: null,

  actions: {
    openDogModal(dog) {
      this.set('selectedDog', dog);
      this.get('remodal').open('dog-modal');
    }
  }
});
