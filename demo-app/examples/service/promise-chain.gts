import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { service } from '@ember/service';
import EmberRemodal from '#src/components/ember-remodal.gts';
import type EmberRemodalComponent from '#src/components/ember-remodal.gts';
import type RemodalService from '#src/services/remodal.ts';
import DemoLog from '../../components/demo-log.gts';
import { stamp } from '../../utils/stamp.ts';

const MODAL_NAME = 'demo-promise-chain';
const AUTO_CLOSE_DELAY_MS = 1000;

export default class PromiseChain extends Component {
  @service declare remodal: RemodalService;

  @tracked entries: string[] = [];

  openThenAutoClose = (): void => {
    void this.remodal
      .open(MODAL_NAME, {
        title: 'Promise chaining',
        text: 'This modal closes itself one second after open() resolves.',
      })
      .then(
        (modal) =>
          new Promise<EmberRemodalComponent>((resolve) =>
            setTimeout(() => resolve(modal), AUTO_CLOSE_DELAY_MS),
          ),
      )
      .then((modal) => modal.close())
      .then(() => this.log('open() → close() chain resolved'));
  };

  clearLog = (): void => {
    this.entries = [];
  };

  private log(message: string): void {
    this.entries = [...this.entries, stamp(message)];
  }

  <template>
    <button
      type="button"
      class="demo-button"
      {{on "click" this.openThenAutoClose}}
    >Open, then auto-close</button>
    <DemoLog @entries={{this.entries}} @onClear={{this.clearLog}} />
    <EmberRemodal @forService={{true}} @name={{MODAL_NAME}} />
  </template>
}
