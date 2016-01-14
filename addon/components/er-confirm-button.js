import Ember from 'ember';
import layout from '../templates/components/er-confirm-button';
import ButtonMixin from '../mixins/er-button';

const { Component } = Ember;

export default Component.extend(ButtonMixin, {
  layout,
  name: 'er-confirm-button',

  click() {
    this.get('modal').send('confirm');
  }
});
