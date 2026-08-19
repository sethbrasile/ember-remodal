import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { service } from '@ember/service';
import EmberRemodal from '#src/components/ember-remodal.gts';
import type RemodalService from '#src/services/remodal.ts';
import DemoLog from '../../components/demo-log.gts';
import { stamp } from '../../utils/stamp.ts';

const MODAL_A = 'demo-stack-a';
const MODAL_B = 'demo-stack-b';

export default class PromiseStacked extends Component {
  @service declare remodal: RemodalService;

  @tracked entries: string[] = [];

  openA = (): void => {
    void this.remodal.open(MODAL_A).then(() => this.log('Modal A opened'));
  };

  openB = (): void => {
    void this.remodal.open(MODAL_B).then(() => this.log('Modal B opened'));
  };

  clearLog = (): void => {
    this.entries = [];
  };

  private log(message: string): void {
    this.entries = [...this.entries, stamp(message)];
  }

  <template>
    <button type="button" class="demo-button" {{on "click" this.openA}}>Open
      modal A</button>
    <DemoLog @entries={{this.entries}} @onClear={{this.clearLog}} />

    <EmberRemodal @forService={{true}} @name={{MODAL_A}} @title="Modal A">
      <p>This modal is open. Its own button opens Modal B on top — both share
        one reference-counted scroll lock.</p>
      <button type="button" class="demo-button" {{on "click" this.openB}}>Open
        modal B on top</button>
    </EmberRemodal>

    <EmberRemodal
      @forService={{true}}
      @name={{MODAL_B}}
      @title="Modal B"
      @text="Stacked on top of A via the browser's top layer — no z-index needed."
      @confirmButton="Nice"
    />
  </template>
}
