import Ember from 'ember';

export default Ember.Route.extend({
  model() {
    return Ember.A([
      Ember.Object.create({
        owner: { name: 'Seth' },
        name: 'Moose',
        breed: 'English Mastiff',
        sex: 'male',
        size: 'retardedly big'
      }),
      Ember.Object.create({
        owner: { name: `Seth's Aunt` },
        name: 'Buttons',
        breed: 'Pomeranian',
        sex: 'female',
        size: 'stupid'
      }),
      Ember.Object.create({
        owner: { name: 'Matt' },
        name: 'Bandit',
        breed: 'of indeterminate breed',
        sex: 'male',
        size: 'reasonably'
      })
    ]);
  }
});
