import Service from '@ember/service';
import { tracked } from '@glimmer/tracking';

const AUTO_DISMISS_MS = 4000;

export interface DemoToast {
  id: number;
  message: string;
  badge?: string;
}

export interface DemoToastPushOptions {
  badge?: string;
}

/**
 * Demo-only toast queue: visualises the addon's action hooks and CloseReason
 * on the options/actions, service, and service/promises pages. Not part of
 * the published addon.
 */
export default class DemoToastsService extends Service {
  @tracked toasts: readonly DemoToast[] = [];

  private nextId = 0;

  push(message: string, options: DemoToastPushOptions = {}): void {
    const id = this.nextId++;
    const toast: DemoToast = { id, message, badge: options.badge };
    this.toasts = [...this.toasts, toast];
    setTimeout(() => this.dismiss(id), AUTO_DISMISS_MS);
  }

  dismiss(id: number): void {
    this.toasts = this.toasts.filter((toast) => toast.id !== id);
  }

  clear(): void {
    this.toasts = [];
  }
}

declare module '@ember/service' {
  interface Registry {
    'demo-toasts': DemoToastsService;
  }
}
