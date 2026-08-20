import { pageTitle } from 'ember-page-title';
import OptionsTable from '../../components/options-table.gts';
import type { OptionRow } from '../../components/options-table.gts';
import DemoExample from '../../components/demo-example.gts';
import BehaviorToggles from '../../examples/options/behavior-toggles.gts';
import behaviorTogglesSrc from '../../examples/options/behavior-toggles.gts?highlight';

const ROWS: OptionRow[] = [
  {
    name: 'closeOnEscape',
    type: 'boolean',
    default: 'true',
    description:
      'Close when Escape is pressed. false is honored only while the modal renders some other control that closes it.',
  },
  {
    name: 'hasCustomKeyboardExit',
    type: 'boolean',
    default: 'false',
    description:
      'Declares that block content provides a keyboard-operable way out, so closeOnEscape={{false}} is honored.',
  },
  {
    name: 'closeOnCancel',
    type: 'boolean',
    default: 'true',
    description: 'Close when cancel fires.',
  },
  {
    name: 'closeOnConfirm',
    type: 'boolean',
    default: 'true',
    description: 'Close when confirm fires.',
  },
  {
    name: 'closeOnOutsideClick',
    type: 'boolean',
    default: 'true',
    description:
      'Close when the backdrop is clicked. Requires the press and the release to both land there.',
  },
  {
    name: 'disableNativeClose',
    type: 'boolean',
    default: 'value of disableForeground',
    description: 'Hides the built-in × close button.',
  },
  {
    name: 'disableForeground',
    type: 'boolean',
    default: 'false',
    description:
      'Removes the card styling so content floats on the backdrop, lightbox style.',
  },
  {
    name: 'disableAnimation',
    type: 'boolean',
    default: 'false',
    description: 'Skips the open/close animations.',
  },
];

<template>
  {{pageTitle "Behavior options"}}

  <h1>Behavior options</h1>
  <p class="docs-lede">The toggles that change how a modal opens, closes, and
    animates.</p>

  <OptionsTable @rows={{ROWS}} />

  <p><code>disableNativeClose</code>
    defaults to whatever
    <code>disableForeground</code>
    is set to — a frameless modal hides its own close button by default too.
    Setting
    <code>closeOnEscape</code>
    to false is conditional: it is honored only while the modal has some other
    keyboard-operable way out (the native close button, a closing confirm/cancel
    button, or a declared
    <code>@hasCustomKeyboardExit</code>). With none of those, Escape closes the
    modal anyway — an inescapable trap is worse than an ignored argument.</p>

  <DemoExample
    @title="Toggle behavior live"
    @component={{BehaviorToggles}}
    @source={{behaviorTogglesSrc}}
  />
</template>
