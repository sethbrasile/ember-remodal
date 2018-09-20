import EmberRouter from '@ember/routing/router';
import config from './config/environment';

const Router = EmberRouter.extend({
  location: config.locationType,
  rootURL: config.rootURL
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
    this.route('promises');
  });
  this.route('options', function() {
    this.route('general', { path: '/' });
    this.route('remodal');
    this.route('content');
    this.route('button');
    this.route('style');
    this.route('functionality');
    this.route('actions');
    this.route('testing');
  });
  this.route('styling');
  this.route('components', function() {
    this.route('contextual', { path: '/' });
    this.route('legacy');
    this.route('example');
  });
  this.route('upgrading');
  this.route('state', function() {
    this.route('simple', { path: '/' });
    this.route('complex');
  });
});

export default Router;
