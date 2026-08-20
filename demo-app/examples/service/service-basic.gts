import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { service } from '@ember/service';
import EmberRemodal from '#src/components/ember-remodal.gts';
import type RemodalService from '#src/services/remodal.ts';
import DemoLog from '../../components/demo-log.gts';
import { stamp } from '../../utils/stamp.ts';

const MODAL_NAME = 'demo-service-basic';

export default class ServiceBasic extends Component {
  @service declare remodal: RemodalService;

  @tracked entries: string[] = [];

  openModal = (): void => {
    void this.remodal
      .open(MODAL_NAME, {
        title: 'Opened via the service',
        text: 'this.remodal.open(name, options) resolves once the opening animation finishes.',
      })
      .then(() => this.log('open() resolved'));
  };

  clearLog = (): void => {
    this.entries = [];
  };

  private log(message: string): void {
    this.entries = [...this.entries, stamp(message)];
  }

  <template>
    <button type="button" class="demo-button" {{on "click" this.openModal}}>Open
      via service</button>
    <DemoLog @entries={{this.entries}} @onClear={{this.clearLog}} />
    <EmberRemodal @forService={{true}} @name={{MODAL_NAME}} />
  </template>
}
