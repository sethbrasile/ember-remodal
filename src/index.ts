import EmberRemodal from './components/ember-remodal.gts';
import ErButton from './components/ember-remodal/er-button.gts';
import RemodalService from './services/remodal.ts';

export { EmberRemodal, ErButton, RemodalService };
export default EmberRemodal;

export type {
  CloseReason,
  EmberRemodalArgs,
  EmberRemodalOptions,
  EmberRemodalSignature,
  EmberRemodalYield,
  ModalState,
} from './components/ember-remodal.gts';
export type { ErButtonSignature } from './components/ember-remodal/er-button.gts';
