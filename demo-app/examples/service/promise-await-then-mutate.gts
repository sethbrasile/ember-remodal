import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { service } from '@ember/service';
import EmberRemodal from '#src/components/ember-remodal.gts';
import type RemodalService from '#src/services/remodal.ts';

const MODAL_NAME = 'demo-await-mutate';

export default class PromiseAwaitThenMutate extends Component {
  @service declare remodal: RemodalService;

  @tracked message = 'Opening…';

  openAndMutate = (): void => {
    this.message = 'Opening…';
    void this.awaitThenMutate();
  };

  private async awaitThenMutate(): Promise<void> {
    await this.remodal.open(MODAL_NAME);
    this.message =
      'The modal awaited its own open() before this text was set — watch it change while the modal is on screen.';
  }

  <template>
    <button
      type="button"
      class="demo-button"
      {{on "click" this.openAndMutate}}
    >Open and await, then mutate</button>
    <EmberRemodal
      @forService={{true}}
      @name={{MODAL_NAME}}
      @title="Awaited, then mutated"
    >
      <p>{{this.message}}</p>
    </EmberRemodal>
  </template>
}
