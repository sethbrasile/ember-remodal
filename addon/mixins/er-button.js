import Ember from 'ember';
import EmberRemodal from '../components/ember-remodal';

const {
  assert,
  String: { camelize },
  run: { scheduleOnce },
  Mixin
} = Ember;

export default Mixin.create({
  tagName: 'span',
  modal: null,

  didRender() {
    scheduleOnce('afterRender', this, '_registerWithModal');
  },

  _registerWithModal() {
    const modal = this.nearestOfType(EmberRemodal);
    assert(`An "${this.get('name')}" MUST be declared inside an "ember-remodal" component block.`, !!modal);
    modal.set(camelize(this.get('name')), true);
    this.set('modal', modal);
  }
});
