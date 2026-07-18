import Component from '@glimmer/component';
import { on } from '@ember/modifier';

export interface ErButtonSignature {
  Args: {
    destination?: Element | null;
    onClick: (event?: Event) => unknown;
  };
  Blocks: {
    default: [];
  };
  Element: HTMLSpanElement;
}

export default class ErButton extends Component<ErButtonSignature> {
  handleClick = (event: Event): void => {
    // Old ember-remodal buttons were commonly wrapped in `<a href="#">`;
    // prevent default so those links never navigate.
    event.preventDefault();
    this.args.onClick();
  };

  <template>
    {{! The span is a click-delegating wrapper: consumers put their own real
        interactive element (usually a <button>) in the block, so giving the
        wrapper a role or tabindex would double up on semantics/focus. }}
    {{! template-lint-disable no-invalid-interactive }}
    {{#if @destination}}
      {{#in-element @destination insertBefore=null}}
        <span
          class="er-button"
          {{on "click" this.handleClick}}
          ...attributes
        >{{yield}}</span>
      {{/in-element}}
    {{else}}
      <span
        class="er-button"
        {{on "click" this.handleClick}}
        ...attributes
      >{{yield}}</span>
    {{/if}}
  </template>
}
