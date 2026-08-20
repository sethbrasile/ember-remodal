import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { service } from '@ember/service';
import EmberRemodal from '#src/components/ember-remodal.gts';
import type RemodalService from '#src/services/remodal.ts';

interface Dog {
  name: string;
  breed: string;
  imageSeed: string;
}

const DOGS: Dog[] = [
  { name: 'Biscuit', breed: 'Corgi', imageSeed: 'biscuit-corgi' },
  { name: 'Juniper', breed: 'Whippet', imageSeed: 'juniper-whippet' },
  { name: 'Pepper', breed: 'Schnauzer', imageSeed: 'pepper-schnauzer' },
  { name: 'Otis', breed: 'Beagle', imageSeed: 'otis-beagle' },
];

const MODAL_NAME = 'demo-dog-detail';

export default class DogList extends Component {
  @service declare remodal: RemodalService;

  @tracked selectedDog: Dog | null = null;

  selectDog = (dog: Dog): void => {
    this.selectedDog = dog;
    void this.remodal.open(MODAL_NAME);
  };

  <template>
    <ul class="demo-dogs">
      {{#each DOGS as |dog|}}
        <li>
          <button
            type="button"
            class="demo-dog-card"
            {{on "click" (fn this.selectDog dog)}}
          >
            <img
              src="https://picsum.photos/seed/{{dog.imageSeed}}/320/200"
              width="320"
              height="200"
              alt={{dog.name}}
            />
            <span class="demo-dog-name">{{dog.name}}</span>
          </button>
        </li>
      {{/each}}
    </ul>

    <EmberRemodal
      @forService={{true}}
      @name={{MODAL_NAME}}
      @ariaLabelledBy="demo-dog-heading"
      as |m|
    >
      {{#if this.selectedDog}}
        <h2 id="demo-dog-heading">{{this.selectedDog.name}}</h2>
        <img
          src="https://picsum.photos/seed/{{this.selectedDog.imageSeed}}/320/200"
          width="320"
          height="200"
          alt={{this.selectedDog.name}}
        />
        <p>{{this.selectedDog.breed}}</p>
        <button
          type="button"
          class="remodal-cancel"
          {{on "click" m.closeAction}}
        >Close</button>
      {{/if}}
    </EmberRemodal>
  </template>
}
