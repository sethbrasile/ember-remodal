import Component from '@glimmer/component';
import { on } from '@ember/modifier';
import { service } from '@ember/service';
import EmberRemodal from '#src/components/ember-remodal.gts';
import type RemodalService from '#src/services/remodal.ts';

const MODAL_NAME = 'demo-service-options';

export default class ServiceOptions extends Component {
  @service declare remodal: RemodalService;

  openAsQuestion = (): void => {
    void this.remodal.open(MODAL_NAME, {
      title: 'Delete this record?',
      text: 'This cannot be undone.',
      confirmButton: 'Delete',
    });
  };

  openAsNotice = (): void => {
    void this.remodal.open(MODAL_NAME, {
      title: 'Saved',
      text: 'Your changes were saved successfully.',
      confirmButton: 'Nice',
    });
  };

  <template>
    <div class="demo-buttons">
      <button
        type="button"
        class="demo-button"
        {{on "click" this.openAsQuestion}}
      >Open as a question</button>
      <button
        type="button"
        class="demo-button subtle"
        {{on "click" this.openAsNotice}}
      >Open as a notice</button>
    </div>
    <EmberRemodal @forService={{true}} @name={{MODAL_NAME}} />
  </template>
}
