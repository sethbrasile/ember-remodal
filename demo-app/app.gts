import EmberApp from 'ember-strict-application-resolver';
import EmberRouter from '@ember/routing/router';
import PageTitleService from 'ember-page-title/services/page-title';
import RemodalService from '#src/services/remodal.ts';

class Router extends EmberRouter {
  location = 'history';
  rootURL = import.meta.env.BASE_URL;
}

export class App extends EmberApp {
  /**
   * Any services or anything from the addon that needs to be in the app-tree registry
   * will need to be manually specified here.
   *
   * Techniques to avoid needing this:
   * - private services
   * - require the consuming app import and configure themselves
   *   (which is what we're emulating here)
   */
  modules = {
    './router': Router,
    './services/page-title': PageTitleService,
    './services/remodal': RemodalService,
    /**
     * NOTE: this glob will import everything matching the glob,
     *     and includes non-services in the services directory.
     */
    ...import.meta.glob('./services/**/*', { eager: true }),
    /**
     * These imports are not magic, but we do require that all entries in the
     * modules object match a ./[type]/[name] pattern.
     *
     * See: https://rfcs.emberjs.com/id/1132-default-strict-resolver
     */
    ...import.meta.glob('./templates/**/*', { eager: true }),
  };
}

Router.map(function () {
  this.route('install');
  this.route('usage', function () {
    this.route('inline');
    this.route('block');
    this.route('yielded');
  });
  this.route('service', function () {
    this.route('promises');
  });
  this.route('state');
  this.route('options', function () {
    this.route('content');
    this.route('behavior');
    this.route('classes');
    this.route('actions');
  });
  this.route('styling');
  this.route('accessibility');
  this.route('testing');
  this.route('migration');
});
