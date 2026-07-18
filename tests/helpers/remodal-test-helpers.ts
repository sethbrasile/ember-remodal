import { find, settled } from '@ember/test-helpers';
import type { TestContext } from '@ember/test-helpers';
import type RemodalService from '#src/services/remodal.ts';

export function dialog(): HTMLDialogElement {
  return find('[data-test-id="modalWrapper"]') as HTMLDialogElement;
}

export function lookupService(context: TestContext): RemodalService {
  return context.owner.lookup('service:remodal');
}

export function pressEscape(): Promise<void> {
  // The native `cancel` event is what the browser fires on Esc inside an open
  // <dialog>; synthetic keyboard events do not trigger it, so dispatch it
  // directly.
  dialog().dispatchEvent(new Event('cancel', { cancelable: true }));
  return settled();
}
