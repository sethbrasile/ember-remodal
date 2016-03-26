import Ember from 'ember';
import config from './config/environment';

const Router = Ember.Router.extend({
  location: config.locationType
});

Router.map(function() {
  this.route('inline', function() {
    this.route('simple', { path: '/' });
    this.route('with-styles');
    this.route('with-actions');
  });
  this.route('block');
  this.route('service');
  this.route('options');
  this.route('styling');
  this.route('components');
});

export default Router;
