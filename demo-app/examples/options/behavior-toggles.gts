import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import EmberRemodal from '#src/components/ember-remodal.gts';

export default class BehaviorToggles extends Component {
  @tracked closeOnEscape = true;
  @tracked closeOnOutsideClick = true;
  @tracked closeOnConfirm = true;
  @tracked closeOnCancel = true;

  toggleCloseOnEscape = (event: Event): void => {
    this.closeOnEscape = (event.target as HTMLInputElement).checked;
  };

  toggleCloseOnOutsideClick = (event: Event): void => {
    this.closeOnOutsideClick = (event.target as HTMLInputElement).checked;
  };

  toggleCloseOnConfirm = (event: Event): void => {
    this.closeOnConfirm = (event.target as HTMLInputElement).checked;
  };

  toggleCloseOnCancel = (event: Event): void => {
    this.closeOnCancel = (event.target as HTMLInputElement).checked;
  };

  <template>
    <fieldset class="demo-toggles">
      <legend>Behavior toggles</legend>
      <label>
        <input
          type="checkbox"
          checked={{this.closeOnEscape}}
          {{on "change" this.toggleCloseOnEscape}}
        />
        closeOnEscape
      </label>
      <label>
        <input
          type="checkbox"
          checked={{this.closeOnOutsideClick}}
          {{on "change" this.toggleCloseOnOutsideClick}}
        />
        closeOnOutsideClick
      </label>
      <label>
        <input
          type="checkbox"
          checked={{this.closeOnConfirm}}
          {{on "change" this.toggleCloseOnConfirm}}
        />
        closeOnConfirm
      </label>
      <label>
        <input
          type="checkbox"
          checked={{this.closeOnCancel}}
          {{on "change" this.toggleCloseOnCancel}}
        />
        closeOnCancel
      </label>
    </fieldset>

    <EmberRemodal
      @openButton="Open toggleable modal"
      @openButtonClasses="demo-button"
      @title="Toggle my behavior"
      @text="Escape, backdrop click, confirm, and cancel all respect the checkboxes above."
      @confirmButton="Confirm"
      @cancelButton="Cancel"
      @closeOnEscape={{this.closeOnEscape}}
      @closeOnOutsideClick={{this.closeOnOutsideClick}}
      @closeOnConfirm={{this.closeOnConfirm}}
      @closeOnCancel={{this.closeOnCancel}}
      @hasCustomKeyboardExit={{true}}
      as |m|
    >
      <button
        type="button"
        class="remodal-cancel"
        {{on "click" m.closeAction}}
      >Force close</button>
    </EmberRemodal>

    {{! A frameless modal has no visible title, so @ariaLabel is what gives
        its <dialog> an accessible name. Without it the addon warns
        (ember-remodal.modal-without-accessible-name) and screen readers
        announce nothing but "dialog". }}
    <EmberRemodal
      @openButton="Open frameless modal"
      @openButtonClasses="demo-button"
      @ariaLabel="Frameless modal"
      @disableForeground={{true}}
    >
      <div class="demo-frameless">
        <p>No card, no chrome — just your content on the overlay.</p>
        <p class="demo-frameless-hint">Click outside or press Escape to close.</p>
      </div>
    </EmberRemodal>

    <EmberRemodal
      @openButton="Open instant modal"
      @openButtonClasses="demo-button"
      @title="No animation"
      @text="disableAnimation skips the open/close transitions entirely."
      @confirmButton="Neat"
      @disableAnimation={{true}}
    />
  </template>
}
