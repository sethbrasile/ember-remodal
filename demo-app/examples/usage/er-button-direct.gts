import Component from '@glimmer/component';
import { service } from '@ember/service';
import { ErButton } from '#src/index.ts';
// demo-hide
import type DemoToastsService from '../../services/demo-toasts.ts';
// demo-show

// This example renders no <dialog> on purpose: it uses ErButton standalone,
// outside any modal.
export const noDialog = true;

export default class ErButtonDirect extends Component {
  // demo-hide
  @service('demo-toasts') declare toasts: DemoToastsService;
  // demo-show

  handleClick = (): void => {
    this.toasts.push('ErButton clicked directly');
  };

  <template>
    <ErButton @onClick={{this.handleClick}}>
      <button type="button" class="demo-button">Say hello</button>
    </ErButton>
  </template>
}
