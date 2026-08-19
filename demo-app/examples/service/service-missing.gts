import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { service } from '@ember/service';
import type RemodalService from '#src/services/remodal.ts';
import DemoLog from '../../components/demo-log.gts';
import { stamp } from '../../utils/stamp.ts';

// This example renders no <dialog> on purpose: it demonstrates the rejection
// path for a name nothing is registered under.
export const noDialog = true;

export default class ServiceMissing extends Component {
  @service declare remodal: RemodalService;

  @tracked entries: string[] = [];

  openMissing = (): void => {
    void this.remodal
      .open('demo-does-not-exist')
      .catch((error: Error) => this.log(stamp(error.message)));
  };

  clearLog = (): void => {
    this.entries = [];
  };

  private log(message: string): void {
    this.entries = [...this.entries, message];
  }

  <template>
    <button
      type="button"
      class="demo-button"
      {{on "click" this.openMissing}}
    >Open a modal that isn't rendered</button>
    <DemoLog @entries={{this.entries}} @onClear={{this.clearLog}} />
  </template>
}
