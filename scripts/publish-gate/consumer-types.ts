/**
 * The TYPE half of the publish gate: the file a consumer would write if they
 * imported everything this addon publishes.
 *
 * Compiled by `scripts/verify-published-package.mjs` inside a throwaway fixture
 * project, against `ember-remodal` installed from a real `npm pack` tarball,
 * with `skipLibCheck: false` so the bodies of the shipped `.d.ts` files are
 * actually checked. This repo's own `tsconfig.json` maps `ember-remodal*` back
 * to `src/` on purpose (a fresh clone must be able to lint without building),
 * which is exactly why nothing here may reuse it.
 *
 * Every import below carries a BINDING (named, default or namespace). A
 * side-effect-only `import 'x'` is not usable as a gate: TypeScript does not
 * report an unresolvable module for one, so such an import passes even when the
 * entry point does not exist. The runner enforces the binding rule.
 */

import EmberRemodalDefault, {
  EmberRemodal,
  ErButton,
  RemodalService,
} from 'ember-remodal';
import type {
  CloseReason,
  EmberRemodalArgs,
  EmberRemodalOptions,
  EmberRemodalSignature,
  EmberRemodalYield,
  ModalState,
} from 'ember-remodal';
import * as indexEntry from 'ember-remodal/index';

import {
  remodalDialog,
  remodalDialogs,
  resetRemodalScrollLock,
  setRemodalAnimationDisabled,
  setupRemodal,
} from 'ember-remodal/test-support';
import type {
  RemodalTestAssert,
  RemodalTestHooks,
  SetupRemodalOptions,
} from 'ember-remodal/test-support';
import * as testSupportEntry from 'ember-remodal/test-support/index';

import EmberRemodalComponent from 'ember-remodal/components/ember-remodal';
import ErButtonComponent from 'ember-remodal/components/ember-remodal/er-button';
import type { ErButtonSignature } from 'ember-remodal/components/ember-remodal/er-button';
import RemodalServiceEntry from 'ember-remodal/services/remodal';
import type Registry from 'ember-remodal/template-registry';

// The README tells consumers to import this specifier. A namespace import
// rather than `import 'ember-remodal/styles/ember-remodal.css'` on purpose: the
// side-effect form cannot fail, this form does unless `exports` gives the
// `./*.css` entry a `types` condition that resolves.
import * as stylesheet from 'ember-remodal/styles/ember-remodal.css';

import manifest from 'ember-remodal/package.json' with { type: 'json' };

// `addon-main.js` is the build-time hook ember-cli requires from Node. It is
// deliberately untyped — no app's TypeScript ever sees it — and this pins that:
// if it ever grows a declaration, the unused directive fails the gate and the
// decision gets revisited instead of drifting.
// @ts-expect-error -- untyped by design
import addonMain from 'ember-remodal/addon-main.js';

// Same for the classic app-tree re-exports: they are resolver fodder, not a
// typed public surface, so `./*`'s `types` condition finds nothing for them.
// @ts-expect-error -- untyped by design
import appTreeComponent from 'ember-remodal/_app_/components/ember-remodal';
// @ts-expect-error -- untyped by design
import appTreeButton from 'ember-remodal/_app_/components/ember-remodal/er-button';
// @ts-expect-error -- untyped by design
import appTreeService from 'ember-remodal/_app_/services/remodal';

// --- the shapes, not just the specifiers -------------------------------------

// The service's return contract is the component class itself.
declare const service: RemodalService;
const opened: Promise<EmberRemodal> = service.open('checkout');
const closed: Promise<EmberRemodal> = service.close('checkout');

declare const modal: EmberRemodal;
const state: ModalState = modal.state;
const reason: CloseReason | undefined = undefined;

declare const args: EmberRemodalArgs;
const options: EmberRemodalOptions | undefined = args.options;
declare const signature: EmberRemodalSignature;
declare const yielded: EmberRemodalYield;
const isOpen: boolean = yielded.isOpen;

declare const hooks: RemodalTestHooks;
declare const assertion: RemodalTestAssert;
const setupOptions: SetupRemodalOptions = { disableAnimation: true };
setupRemodal(hooks, setupOptions);

declare const registry: Registry;
declare const buttonSignature: ErButtonSignature;

const packageName: string = manifest.name;

export const surface = {
  EmberRemodalDefault,
  EmberRemodal,
  ErButton,
  RemodalService,
  indexEntry,
  remodalDialog,
  remodalDialogs,
  resetRemodalScrollLock,
  setRemodalAnimationDisabled,
  setupRemodal,
  testSupportEntry,
  EmberRemodalComponent,
  ErButtonComponent,
  RemodalServiceEntry,
  stylesheet,
  addonMain,
  appTreeComponent,
  appTreeButton,
  appTreeService,
  opened,
  closed,
  state,
  reason,
  options,
  signature,
  isOpen,
  assertion,
  registry,
  buttonSignature,
  packageName,
};
