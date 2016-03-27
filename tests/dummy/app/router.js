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
  this.route('service', function() {
    this.route('simple', { path: '/' });
    this.route('names');
    this.route('properties');
  });
  this.route('options', function() {
    this.route('general', { path: '/' });
    this.route('remodal');
    this.route('content');
    this.route('button');
    this.route('style');
    this.route('functionality');
    this.route('actions');
  });
  this.route('styling');
  this.route('components', function() {
    this.route('contextual', { path: '/' });
    this.route('legacy');
  });
});

export default Router;
