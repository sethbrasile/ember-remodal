import Component from '@glimmer/component';
import { service } from '@ember/service';
import EmberRemodal from '#src/components/ember-remodal.gts';
import type { CloseReason } from '#src/components/ember-remodal.gts';
// demo-hide
import type DemoToastsService from '../../services/demo-toasts.ts';
// demo-show

export default class InlineActions extends Component {
  // demo-hide
  @service('demo-toasts') declare toasts: DemoToastsService;
  // demo-show

  handleOpen = (): void => {
    this.toasts.push('onOpen fired');
  };

  handleConfirm = (): void => {
    this.toasts.push('onConfirm fired');
  };

  handleCancel = (): void => {
    this.toasts.push('onCancel fired');
  };

  handleClose = (reason?: CloseReason): void => {
    this.toasts.push('onClose fired', { badge: reason ?? 'none' });
  };

  <template>
    <EmberRemodal
      @openButton="Open modal with actions"
      @openButtonClasses="demo-button"
      @title="Watch the toasts"
      @text="Confirm, cancel, or close this modal (Escape, backdrop, ✕) and watch the toast queue in the corner."
      @confirmButton="Confirm"
      @cancelButton="Cancel"
      @onOpen={{this.handleOpen}}
      @onConfirm={{this.handleConfirm}}
      @onCancel={{this.handleCancel}}
      @onClose={{this.handleClose}}
    />
  </template>
}
