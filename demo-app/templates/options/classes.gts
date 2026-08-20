import { pageTitle } from 'ember-page-title';
import { LinkTo } from '@ember/routing';
import OptionsTable from '../../components/options-table.gts';
import type { OptionRow } from '../../components/options-table.gts';
import DemoExample from '../../components/demo-example.gts';
import ClassHooks from '../../examples/options/class-hooks.gts';
import classHooksSrc from '../../examples/options/class-hooks.gts?highlight';

const ROWS: OptionRow[] = [
  {
    name: 'modifier',
    type: 'string',
    default: "''",
    description:
      'Extra class on both the <dialog> and the card — the theming hook.',
  },
  {
    name: 'modalClasses',
    type: 'string',
    default: '—',
    description: 'Extra classes for the modal card.',
  },
  {
    name: 'buttonClasses',
    type: 'string',
    default: '—',
    description: 'Extra classes for all rendered buttons.',
  },
  {
    name: 'outerButtonClasses',
    type: 'string',
    default: '—',
    description: 'Extra classes for trigger (outside) buttons and links.',
  },
  {
    name: 'innerButtonClasses',
    type: 'string',
    default: '—',
    description: 'Extra classes for confirm/cancel (inside) buttons.',
  },
  {
    name: 'openButtonClasses',
    type: 'string',
    default: '—',
    description: 'Extra classes for the openButton trigger.',
  },
  {
    name: 'openLinkClasses',
    type: 'string',
    default: '—',
    description: 'Extra classes for the openLink trigger.',
  },
  {
    name: 'cancelButtonClasses',
    type: 'string',
    default: '—',
    description: 'Extra classes for the cancel button.',
  },
  {
    name: 'confirmButtonClasses',
    type: 'string',
    default: '—',
    description: 'Extra classes for the confirm button.',
  },
  {
    name: 'legacyClassNames',
    type: 'boolean',
    default: 'false',
    description:
      'Re-emits the retired 2.x bare single-word class tokens alongside the namespaced ones.',
  },
];

<template>
  {{pageTitle "Class options"}}

  <h1>Class options</h1>
  <p class="docs-lede">Every class hook the component exposes, and where each
    one lands in the rendered markup.</p>

  <OptionsTable @rows={{ROWS}} />

  <p><code>modifier</code>
    is the odd one out: it lands on both the
    <code>&lt;dialog&gt;</code>
    wrapper and the card, so it is the one hook that can theme the backdrop (via
    <code>::backdrop</code>) as well as the card.
    <code>modalClasses</code>
    lands on the card alone. Every button-class option lands on the button it
    names, plus
    <code>buttonClasses</code>, which lands on all of them. See
    <LinkTo @route="styling">Styling & theming</LinkTo>
    for the full worked theme.</p>

  <p><code>legacyClassNames</code>
    is a migration bridge: it re-emits every 2.x bare single-word class token (<code
    >window</code>,
    <code>title</code>,
    <code>button</code>, …) alongside the namespaced ones, for apps whose CSS
    still keys on the old names.</p>

  <DemoExample
    @title="Theming and legacy classes"
    @component={{ClassHooks}}
    @source={{classHooksSrc}}
  />
</template>
