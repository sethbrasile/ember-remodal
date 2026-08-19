import Component from '@glimmer/component';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { service } from '@ember/service';
import type DemoToastsService from '../services/demo-toasts.ts';

export default class DemoToasts extends Component {
  @service('demo-toasts') declare toasts: DemoToastsService;

  <template>
    <div class="demo-toasts" role="status" aria-live="polite">
      {{#each this.toasts.toasts as |toast|}}
        <div class="demo-toast">
          <span class="demo-toast-message">{{toast.message}}</span>
          {{#if toast.badge}}
            <span class="demo-toast-badge">{{toast.badge}}</span>
          {{/if}}
          <button
            type="button"
            class="demo-toast-dismiss"
            aria-label="Dismiss"
            {{on "click" (fn this.toasts.dismiss toast.id)}}
          >×</button>
        </div>
      {{/each}}
    </div>
  </template>
}
