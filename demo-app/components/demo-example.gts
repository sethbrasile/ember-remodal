import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { htmlSafe } from '@ember/template';
import { on } from '@ember/modifier';
import type { SafeString } from '@ember/template';
import type { ComponentLike } from '@glint/template';

export interface DemoExampleSignature {
  Args: {
    title: string;
    description?: string;
    component?: ComponentLike;
    source: HighlightedSource;
  };
}

function trustedHtml(html: string): SafeString {
  return htmlSafe(html);
}

const COPY_LABEL_RESET_MS = 1500;

export default class DemoExample extends Component<DemoExampleSignature> {
  @tracked copyLabel = 'Copy';

  copySource = (): void => {
    if (!navigator.clipboard) {
      this.flashCopyLabel('Copy failed');
      return;
    }
    navigator.clipboard
      .writeText(this.args.source.text)
      .then(() => this.flashCopyLabel('Copied'))
      .catch(() => this.flashCopyLabel('Copy failed'));
  };

  private flashCopyLabel(label: string): void {
    this.copyLabel = label;
    setTimeout(() => {
      this.copyLabel = 'Copy';
    }, COPY_LABEL_RESET_MS);
  }

  <template>
    <section class="demo-example">
      <header class="demo-example-header">
        <h3 class="demo-example-title">{{@title}}</h3>
        {{#if @description}}
          <p class="demo-example-description">{{@description}}</p>
        {{/if}}
      </header>

      <div class="demo-example-body {{unless @component 'is-source-only'}}">
        {{#if @component}}
          <div class="demo-example-live">
            <@component />
          </div>
        {{/if}}

        <div class="demo-example-source">
          <div class="demo-example-toolbar">
            <span class="demo-example-lang">{{@source.lang}}</span>
            <button
              type="button"
              class="demo-copy"
              {{on "click" this.copySource}}
            >{{this.copyLabel}}</button>
          </div>
          {{trustedHtml @source.html}}
        </div>
      </div>
    </section>
  </template>
}
