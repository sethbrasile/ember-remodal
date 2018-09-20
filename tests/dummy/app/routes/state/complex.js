import EmberObject from '@ember/object';
import { A } from '@ember/array';
import Route from '@ember/routing/route';

export default Route.extend({
  model() {
    return A([
      EmberObject.create({
        owner: { name: 'Seth' },
        name: 'Moose',
        breed: 'English Mastiff',
        sex: 'male',
        size: 'retardedly big'
      }),
      EmberObject.create({
        owner: { name: `Seth's Aunt` },
        name: 'Buttons',
        breed: 'Pomeranian',
        sex: 'female',
        size: 'stupid'
      }),
      EmberObject.create({
        owner: { name: 'Matt' },
        name: 'Bandit',
        breed: 'of indeterminate breed',
        sex: 'male',
        size: 'reasonably'
      })
    ]);
  }
});
