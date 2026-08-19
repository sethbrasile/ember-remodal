import Component from '@glimmer/component';
import { service } from '@ember/service';
import EmberRemodal from '#src/components/ember-remodal.gts';
import type { CloseReason } from '#src/components/ember-remodal.gts';
import type DemoToastsService from '../../services/demo-toasts.ts';

export default class CloseReasons extends Component {
  @service('demo-toasts') declare toasts: DemoToastsService;

  handleClose = (reason?: CloseReason): void => {
    this.toasts.push('onClose fired', { badge: reason ?? 'none' });
  };

  <template>
    <EmberRemodal
      @openButton="Open and try every close path"
      @openButtonClasses="demo-button"
      @title="Close reasons"
      @text="Confirm, cancel, Escape, the backdrop, and the ✕ button each yield a different reason."
      @confirmButton="Confirm"
      @cancelButton="Cancel"
      @onClose={{this.handleClose}}
    />
  </template>
}
