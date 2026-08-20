import Service from '@ember/service';
import type EmberRemodal from '../components/ember-remodal.js';
import type { EmberRemodalOptions } from '../components/ember-remodal.js';
export default class RemodalService extends Service {
    private registry;
    register(name: string, modal: EmberRemodal): void;
    unregister(name: string, modal: EmberRemodal): void;
    open(name?: string, opts?: EmberRemodalOptions): Promise<EmberRemodal>;
    close(name?: string): Promise<EmberRemodal>;
    private applyOptionsThenOpen;
}
declare module '@ember/service' {
    interface Registry {
        remodal: RemodalService;
    }
}
//# sourceMappingURL=remodal.d.ts.map