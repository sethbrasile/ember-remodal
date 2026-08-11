import Service from '@ember/service';
import { warn } from '@ember/debug';
import { waitForPromise } from '@ember/test-waiters';
import type EmberRemodal from '../components/ember-remodal.gts';
import type { EmberRemodalOptions } from '../components/ember-remodal.gts';

function missingModalMessage(name: string): string {
  return `The requested modal, "${name}" can not be opened because it is not rendered in the current route. In order to use ember-remodal as a service, an instance of {{ember-remodal}} must currently be rendered, with "forService=true". Try putting it in your application template.`;
}

export default class RemodalService extends Service {
  private registry = new Map<string, EmberRemodal>();

  register(name: string, modal: EmberRemodal): void {
    const existing = this.registry.get(name);
    warn(
      `ember-remodal: a modal is already registered with the service under the name "${name}". The most recently rendered one wins, and destroying it will leave the other unreachable — give each service-driven modal a unique "name".`,
      existing === undefined || existing === modal,
      { id: 'ember-remodal.duplicate-service-name' },
    );
    this.registry.set(name, modal);
  }

  unregister(name: string, modal: EmberRemodal): void {
    if (this.registry.get(name) === modal) {
      this.registry.delete(name);
    }
  }

  open(
    name = 'ember-remodal',
    opts?: EmberRemodalOptions,
  ): Promise<EmberRemodal> {
    const modal = this.registry.get(name);
    if (!modal) {
      return Promise.reject(new Error(missingModalMessage(name)));
    }
    if (!opts) {
      return modal.open();
    }
    return waitForPromise(this.applyOptionsThenOpen(modal, opts));
  }

  close(name = 'ember-remodal'): Promise<EmberRemodal> {
    const modal = this.registry.get(name);
    if (!modal) {
      return Promise.reject(new Error(missingModalMessage(name)));
    }
    return modal.close();
  }

  private async applyOptionsThenOpen(
    modal: EmberRemodal,
    opts: EmberRemodalOptions,
  ): Promise<EmberRemodal> {
    // `serviceOverrides` is a tracked write, and open() is routinely called
    // from a component constructor or a route hook that is still inside the
    // render transaction which already read those options — writing there
    // trips Ember's backtracking-rerender assertion. Yielding a microtask puts
    // the write after that transaction has closed while still keeping it
    // BEFORE the open transition starts, so the modal never animates open
    // showing stale content.
    await Promise.resolve();
    if (modal.isDestroyed) {
      return modal;
    }
    // Matches the old addon's setProperties behavior: overrides merge into
    // any previous ones and persist across subsequent opens until replaced.
    modal.serviceOverrides = { ...modal.serviceOverrides, ...opts };
    return modal.open();
  }
}

declare module '@ember/service' {
  interface Registry {
    remodal: RemodalService;
  }
}
