import { pageTitle } from 'ember-page-title';
import OptionsTable from '../../components/options-table.gts';
import type { OptionRow } from '../../components/options-table.gts';
import DemoExample from '../../components/demo-example.gts';
import ActionHooks from '../../examples/options/action-hooks.gts';
import actionHooksSrc from '../../examples/options/action-hooks.gts?highlight';
import CloseReasons from '../../examples/options/close-reasons.gts';
import closeReasonsSrc from '../../examples/options/close-reasons.gts?highlight';

const ROWS: OptionRow[] = [
  {
    name: 'onBeforeOpen',
    type: '() => unknown',
    default: '—',
    description: 'Called before opening; return false to veto the open.',
  },
  {
    name: 'onOpen',
    type: '() => void',
    default: '—',
    description: 'Called after the opening animation completes.',
  },
  {
    name: 'onConfirm',
    type: '() => void',
    default: '—',
    description:
      'Called when the confirm button (or m.confirm / m.confirmAction) fires.',
  },
  {
    name: 'onCancel',
    type: '() => void',
    default: '—',
    description:
      'Called when the cancel button (or m.cancel / m.cancelAction) fires.',
  },
  {
    name: 'onClose',
    type: '(reason?: CloseReason) => void',
    default: '—',
    description:
      "Called after closing; receives 'confirmation', 'cancellation', or undefined.",
  },
];

<template>
  {{pageTitle "Action hooks"}}

  <h1>Action hooks</h1>
  <p class="docs-lede">The five callbacks, visualised as toasts, and every path
    that produces a close reason.</p>

  <OptionsTable @rows={{ROWS}} />

  <p>Toasts render behind an open modal's backdrop — the dialog is in the
    browser's top layer, which paints above everything regardless of z-index —
    so a toast pushed while a modal is open becomes visible once the modal
    closes.</p>

  <DemoExample
    @title="Every hook, and a veto"
    @description="onBeforeOpen returning false stops the modal from opening at all."
    @component={{ActionHooks}}
    @source={{actionHooksSrc}}
  />

  <DemoExample
    @title="Close reasons"
    @description="Confirm → confirmation. Cancel → cancellation. Escape, backdrop, ✕, and service.close() → undefined."
    @component={{CloseReasons}}
    @source={{closeReasonsSrc}}
  />
</template>
