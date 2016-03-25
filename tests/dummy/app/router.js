import Ember from 'ember';
import config from './config/environment';

const Router = Ember.Router.extend({
  location: config.locationType
});

Router.map(function() {
  this.route('inline');
  this.route('block');
  this.route('service');
  this.route('options');
  this.route('styling');
  this.route('components');
});

export default Router;
