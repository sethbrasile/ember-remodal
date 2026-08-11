import EmberApp from 'ember-strict-application-resolver';
import EmberRouter from '@ember/routing/router';
import * as QUnit from 'qunit';
import { setApplication } from '@ember/test-helpers';
import { setup } from 'qunit-dom';
import { start as qunitStart, setupEmberOnerrorValidation } from 'ember-qunit';
import { setTesting } from '@embroider/macros';
import RemodalService from '#src/services/remodal.ts';

class Router extends EmberRouter {
  location = 'none';
  rootURL = '/';
}

class TestApp extends EmberApp {
  modules = {
    './router': Router,
    './services/remodal': RemodalService,
  };
}

Router.map(function () {});

export function start() {
  setTesting(true);
  setApplication(
    TestApp.create({
      autoboot: false,
      rootElement: '#ember-testing',
    }),
  );
  setup(QUnit.assert);
  setupEmberOnerrorValidation();

  // A modal's open/close transition is wrapped in a test waiter, and several of
  // this addon's failure modes are "the promise never settles". Without a
  // timeout that is a hung browser and a CI job killed at the job level, with no
  // indication of which test did it; with one it is a single failing test.
  QUnit.config.testTimeout = 30_000;

  qunitStart({
    // Fails the test that finished with a transition (or any other async) still
    // in flight, instead of letting it settle during the next test — which is
    // how the scroll lock ends up engaged in a test that never opened a modal.
    setupTestIsolationValidation: true,
  });
}
