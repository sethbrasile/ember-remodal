import Ember from 'ember';
import layout from '../templates/components/er-cancel-button';
import ButtonMixin from '../mixins/er-button';

const { Component } = Ember;

export default Component.extend(ButtonMixin, {
  layout,
  name: 'er-cancel-button',

  click() {
    this.get('modal').send('cancel');
  }
});
