import Ember from 'ember';
import EmberRemodal from '../components/ember-remodal';

const {
  assert,
  computed,
  String: { camelize },
  run: { scheduleOnce },
  Mixin
} = Ember;

export default Mixin.create({
  tagName: 'span',
  modal: null,

  name: computed('buttonType', {
    get() {
      return `er-${this.get('buttonType')}-button`;
    }
  }),

  didRender() {
    scheduleOnce('afterRender', this, '_registerWithModal');
  },

  click() {
    this.get('modal').send(this.get('buttonType'));
  },

  _registerWithModal() {
    this.set('modal', this._getModal());
    this.set(`modal.${camelize(this.get('name'))}`, true);
    assert(`An "${this.get('name')}" MUST be declared inside an "ember-remodal" component block.`, !!this.get('modal'));
  },

  _getModal() {
    return this.nearestOfType(EmberRemodal);
  }
});
