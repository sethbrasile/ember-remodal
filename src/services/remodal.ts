import Service from '@ember/service';
import { warn } from '@ember/debug';
import { waitForPromise } from '@ember/test-waiters';
import type EmberRemodal from '../components/ember-remodal.gts';
import type { EmberRemodalOptions } from '../components/ember-remodal.gts';

function missingModalMessage(name: string): string {
  return `The requested modal, "${name}" can not be opened because it is not rendered in the current route. In order to use ember-remodal as a service, an instance of {{ember-remodal}} must currently be rendered, with "forService=true". Try putting it in your application template.`;
}

export default class RemodalService extends Service {
  // A stack per name, not a single entry: duplicate names are a mistake worth
  // warning about, but the last-writer-wins Map they used to share meant
  // destroying the winner left every earlier modal permanently unreachable —
  // routinely the case when a route renders its own copy of a modal the
  // application template already renders. The newest registration still wins
  // lookups; unregistering it uncovers the one it shadowed.
  private registry = new Map<string, EmberRemodal[]>();

  register(name: string, modal: EmberRemodal): void {
    const stack = this.registry.get(name);
    warn(
      `ember-remodal: a modal is already registered with the service under the name "${name}". The most recently rendered one wins lookups until it is destroyed — give each service-driven modal a unique "name".`,
      stack === undefined || stack.length === 0 || stack.at(-1) === modal,
      { id: 'ember-remodal.duplicate-service-name' },
    );
    if (stack === undefined) {
      this.registry.set(name, [modal]);
    } else if (stack.at(-1) !== modal) {
      // Re-registering an instance already on top is a no-op; anything else
      // goes on top and shadows what was there.
      stack.push(modal);
    }
  }

  unregister(name: string, modal: EmberRemodal): void {
    const stack = this.registry.get(name);
    if (!stack) {
      return;
    }
    // Search rather than pop: a shadowed modal can be torn down before the one
    // shadowing it (independent `{{#if}}`s, a route exiting under the
    // application template), and that must not evict the live entry.
    const index = stack.lastIndexOf(modal);
    if (index === -1) {
      return;
    }
    stack.splice(index, 1);
    if (stack.length === 0) {
      this.registry.delete(name);
    }
  }

  open(
    name = 'ember-remodal',
    opts?: EmberRemodalOptions,
  ): Promise<EmberRemodal> {
    const modal = this.registry.get(name)?.at(-1);
    if (!modal) {
      return Promise.reject(new Error(missingModalMessage(name)));
    }
    if (!opts) {
      return modal.open();
    }
    return waitForPromise(this.applyOptionsThenOpen(modal, opts));
  }

  close(name = 'ember-remodal'): Promise<EmberRemodal> {
    const modal = this.registry.get(name)?.at(-1);
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
