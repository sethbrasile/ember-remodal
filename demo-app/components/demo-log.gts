import type { TOC } from '@ember/component/template-only';
import { on } from '@ember/modifier';

interface DemoLogSignature {
  Args: {
    entries: readonly string[];
    onClear: () => void;
  };
}

const DemoLog: TOC<DemoLogSignature> = <template>
  <div class="demo-log-panel">
    <div class="demo-log-toolbar">
      <span>Event log</span>
      <button
        type="button"
        class="demo-log-clear"
        disabled={{if @entries.length false true}}
        {{on "click" @onClear}}
      >Clear</button>
    </div>
    {{#if @entries.length}}
      <ol class="demo-log">
        {{#each @entries as |entry|}}
          <li>{{entry}}</li>
        {{/each}}
      </ol>
    {{else}}
      <p class="demo-log-empty">Nothing yet — try the buttons above.</p>
    {{/if}}
  </div>
</template>;

export default DemoLog;
