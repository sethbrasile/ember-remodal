import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import EmberRemodal from '#src/components/ember-remodal.gts';

export default class ReducedMotion extends Component {
  @tracked simulate = false;

  toggle = (event: Event): void => {
    this.simulate = (event.target as HTMLInputElement).checked;
  };

  <template>
    <label>
      <input
        type="checkbox"
        checked={{this.simulate}}
        {{on "change" this.toggle}}
      />
      Simulate prefers-reduced-motion
    </label>
    <div class={{if this.simulate "demo-reduced-motion"}}>
      <EmberRemodal
        @openButton="Open modal"
        @openButtonClasses="demo-button"
        @title="Reduced motion"
        @text="With the checkbox above checked, open and close happen instantly."
        @confirmButton="OK"
      />
    </div>
  </template>
}
