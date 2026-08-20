import { pageTitle } from 'ember-page-title';
import OptionsTable from '../../components/options-table.gts';
import type { OptionRow } from '../../components/options-table.gts';
import DemoExample from '../../components/demo-example.gts';
import ContentOptions from '../../examples/options/content-options.gts';
import contentOptionsSrc from '../../examples/options/content-options.gts?highlight';

const ROWS: OptionRow[] = [
  {
    name: 'title',
    type: 'string',
    default: '—',
    description: 'Renders an <h2>, and names the dialog via aria-labelledby.',
  },
  {
    name: 'text',
    type: 'string',
    default: '—',
    description: 'Renders a <p>.',
  },
  {
    name: 'confirmButton',
    type: 'string',
    default: '—',
    description: 'Label; renders a confirm button (remodal-confirm).',
  },
  {
    name: 'cancelButton',
    type: 'string',
    default: '—',
    description: 'Label; renders a cancel button (remodal-cancel).',
  },
  {
    name: 'openButton',
    type: 'string',
    default: '—',
    description: 'Label; renders a <button> trigger.',
  },
  {
    name: 'openLink',
    type: 'string',
    default: '—',
    description: 'Label; renders an <a> trigger.',
  },
  {
    name: 'linkButton',
    type: 'string',
    default: '—',
    description:
      'Legacy alias for an <a> trigger; takes precedence over openLink and openButton.',
  },
  {
    name: 'closeButtonLabel',
    type: 'string',
    default: "'Close Modal'",
    description:
      'aria-label and title for the built-in close button, so it can be translated.',
  },
  {
    name: 'ariaLabel',
    type: 'string',
    default: '—',
    description:
      'Accessible name for a modal with no visible title — the escape hatch.',
  },
  {
    name: 'ariaLabelledBy',
    type: 'string',
    default: '—',
    description:
      'Id (or space-separated ids) of your own markup that names the dialog; outranks ariaLabel and title.',
  },
  {
    name: 'name',
    type: 'string',
    default: "'ember-remodal'",
    description:
      'Registry key for service usage; also added as a class on the modal card.',
  },
  {
    name: 'forService',
    type: 'boolean',
    default: 'false',
    description: 'Registers this modal with the remodal service under name.',
  },
  {
    name: 'dataTestId',
    type: 'string',
    default: '—',
    description: 'Sets data-test-id on the outer component element.',
  },
  {
    name: 'options',
    type: 'EmberRemodalOptions',
    default: '—',
    description:
      'A hash of any of these options; wins over the equivalent individual argument.',
  },
];

<template>
  {{pageTitle "Content options"}}

  <h1>Content options</h1>
  <p class="docs-lede">Every option that puts words or naming on the modal:
    title, text, buttons, and the accessible-name arguments.</p>

  <OptionsTable @rows={{ROWS}} />

  <p>Naming precedence follows the accname algorithm:
    <code>ariaLabelledBy</code>
    beats
    <code>ariaLabel</code>
    beats
    <code>title</code>. Every option in this table can also be passed inside an
    <code>@options</code>
    hash instead of as an individual argument — the hash wins if both are given.</p>

  <DemoExample
    @title="Naming and buttons"
    @component={{ContentOptions}}
    @source={{contentOptionsSrc}}
  />
</template>
