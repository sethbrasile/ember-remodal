import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { service } from '@ember/service';
import EmberRemodal from '#src/components/ember-remodal.gts';
import type { CloseReason } from '#src/components/ember-remodal.gts';
import type DemoToastsService from '../../services/demo-toasts.ts';

export default class ActionHooks extends Component {
  @service('demo-toasts') declare toasts: DemoToastsService;

  @tracked veto = false;

  toggleVeto = (event: Event): void => {
    this.veto = (event.target as HTMLInputElement).checked;
  };

  handleBeforeOpen = (): boolean => {
    if (this.veto) {
      this.toasts.push('onBeforeOpen returned false');
      return false;
    }
    this.toasts.push('onBeforeOpen fired');
    return true;
  };

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
    <label class="demo-veto">
      <input
        type="checkbox"
        checked={{this.veto}}
        {{on "change" this.toggleVeto}}
      />
      Veto opening
    </label>
    <EmberRemodal
      @openButton="Open with all five hooks"
      @openButtonClasses="demo-button"
      @title="Every hook fires a toast"
      @text="Confirm, cancel, or close, and watch the toast queue."
      @confirmButton="Confirm"
      @cancelButton="Cancel"
      @onBeforeOpen={{this.handleBeforeOpen}}
      @onOpen={{this.handleOpen}}
      @onConfirm={{this.handleConfirm}}
      @onCancel={{this.handleCancel}}
      @onClose={{this.handleClose}}
    />
  </template>
}
