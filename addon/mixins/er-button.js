import Ember from 'ember';

const {
  computed,
  Mixin
} = Ember;

export default Mixin.create({
  tagName: 'span',
  
  click() {
    this.sendAction();
  }
});
