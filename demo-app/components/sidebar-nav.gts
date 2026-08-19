import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { LinkTo } from '@ember/routing';

interface NavItem {
  label: string;
  route: string;
}

interface NavGroup {
  heading: string;
  items: NavItem[];
}

const GROUPS: NavGroup[] = [
  {
    heading: 'Getting started',
    items: [
      { label: 'Home', route: 'index' },
      { label: 'Install', route: 'install' },
    ],
  },
  {
    heading: 'Usage',
    items: [
      { label: 'Inline', route: 'usage.inline' },
      { label: 'Block', route: 'usage.block' },
      { label: 'Yielded controls', route: 'usage.yielded' },
    ],
  },
  {
    heading: 'Service & state',
    items: [
      { label: 'Service', route: 'service.index' },
      { label: 'Promises', route: 'service.promises' },
      { label: 'State-driven', route: 'state' },
    ],
  },
  {
    heading: 'Options',
    items: [
      { label: 'Content', route: 'options.content' },
      { label: 'Behavior', route: 'options.behavior' },
      { label: 'Classes', route: 'options.classes' },
      { label: 'Actions', route: 'options.actions' },
    ],
  },
  {
    heading: 'Styling',
    items: [{ label: 'Styling & theming', route: 'styling' }],
  },
  {
    heading: 'Accessibility',
    items: [{ label: 'Accessibility', route: 'accessibility' }],
  },
  {
    heading: 'Testing',
    items: [{ label: 'Testing', route: 'testing' }],
  },
  {
    heading: 'Migration',
    items: [{ label: 'Migrating from 2.x', route: 'migration' }],
  },
];

export default class SidebarNav extends Component {
  @tracked open = false;

  toggle = (): void => {
    this.open = !this.open;
  };

  <template>
    <button
      type="button"
      class="docs-nav-toggle"
      aria-expanded="{{this.open}}"
      aria-controls="docs-nav"
      {{on "click" this.toggle}}
    >Menu</button>

    <nav
      id="docs-nav"
      class="docs-nav {{if this.open 'is-open'}}"
      aria-label="Documentation"
    >
      {{#each GROUPS as |group|}}
        <div class="docs-nav-group">
          <h2 class="docs-nav-heading">{{group.heading}}</h2>
          <ul>
            {{#each group.items as |item|}}
              <li><LinkTo @route={{item.route}}>{{item.label}}</LinkTo></li>
            {{/each}}
          </ul>
        </div>
      {{/each}}
    </nav>
  </template>
}
