import Service from '@ember/service';
import { assert } from '@ember/debug';
import type EmberRemodal from '../components/ember-remodal.gts';
import type { EmberRemodalOptions } from '../components/ember-remodal.gts';

function missingModalMessage(name: string): string {
  return `The requested modal, "${name}" can not be opened because it is not rendered in the current route. In order to use ember-remodal as a service, an instance of {{ember-remodal}} must currently be rendered, with "forService=true". Try putting it in your application template.`;
}

export default class RemodalService extends Service {
  private registry = new Map<string, EmberRemodal>();

  register(name: string, modal: EmberRemodal): void {
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
    const modal = this.lookup(name);
    if (!modal) {
      // The assert above is stripped from production builds; reject with the
      // same diagnostic there instead of failing with a bare TypeError.
      return Promise.reject(new Error(missingModalMessage(name)));
    }
    if (opts) {
      // Matches the old addon's setProperties behavior: overrides merge into
      // any previous ones and persist across subsequent opens until replaced.
      modal.serviceOverrides = { ...modal.serviceOverrides, ...opts };
    }
    return modal.open();
  }

  close(name = 'ember-remodal'): Promise<EmberRemodal> {
    const modal = this.lookup(name);
    if (!modal) {
      return Promise.reject(new Error(missingModalMessage(name)));
    }
    return modal.close();
  }

  private lookup(name: string): EmberRemodal | undefined {
    const modal = this.registry.get(name);
    assert(missingModalMessage(name), modal);
    return modal;
  }
}

declare module '@ember/service' {
  interface Registry {
    remodal: RemodalService;
  }
}
