import type { TOC } from '@ember/component/template-only';

export interface OptionRow {
  name: string;
  type: string;
  default: string;
  description: string;
}

interface OptionsTableSignature {
  Args: {
    rows: readonly OptionRow[];
  };
}

const OptionsTable: TOC<OptionsTableSignature> = <template>
  <div class="demo-options-wrap">
    <table class="demo-options">
      <thead>
        <tr>
          <th>Name</th>
          <th>Type</th>
          <th>Default</th>
          <th>Description</th>
        </tr>
      </thead>
      <tbody>
        {{#each @rows as |row|}}
          <tr>
            <td><code>{{row.name}}</code></td>
            <td><code>{{row.type}}</code></td>
            <td><code>{{row.default}}</code></td>
            <td>{{row.description}}</td>
          </tr>
        {{/each}}
      </tbody>
    </table>
  </div>
</template>;

export default OptionsTable;
