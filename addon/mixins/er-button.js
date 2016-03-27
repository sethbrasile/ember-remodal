import Ember from 'ember';
import EmberRemodal from '../components/ember-remodal';

const {
  assert,
  deprecate,
  String: { camelize },
  run: { scheduleOnce },
  Mixin
} = Ember;

export default Mixin.create({
  tagName: 'span',
  modal: null,
  deprecateComponent: true,

  didRender() {
    scheduleOnce('afterRender', this, '_registerWithModal');
  },

  _registerWithModal() {
    this.set('modal', this._getModal());
    this.set(`modal.${camelize(this.get('name'))}`, true);
    assert(`An "${this.get('name')}" MUST be declared inside an "ember-remodal" component block.`, !!this.get('modal'));

    deprecate(
      `ember-remodal's ${this.get('name')} is deprecated and is removed in 1.0.0. When you are able to upgrade Ember to 2.3 or greater, please use contextual components instead. See http://sethbrasile.github.io/ember-remodal/#/components`,
      !this.get('deprecateComponent'),
      { id: `ember-remodal.${this.get('name')}`, until: '1.0.0' }
    );
  },

  _getModal() {
    return this.nearestOfType(EmberRemodal);
  }
});
