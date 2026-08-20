/* eslint-disable no-console */
import Ember from 'ember';

export const MIGRATION_GUIDE =
  'https://github.com/sethbrasile/ember-remodal/blob/master/MIGRATION.md';

export const INTERNAL_CALL = '__ember-remodal-internal-call__';

// Shared across duplicate AMD copies of this module (addon vs test resolver).
function store() {
  if (!Ember.__emberRemodalDeprecations) {
    Ember.__emberRemodalDeprecations = {
      warned: Object.create(null),
      recorded: []
    };
  }
  return Ember.__emberRemodalDeprecations;
}

// Deliberately console.warn, not Ember.deprecate: these must survive a
// production build, and must behave identically on every consumer Ember
// version this addon supports.
export function warnOnce(config, id, message, anchor) {
  let remodalConfig = config && config['ember-remodal'];

  if (remodalConfig && remodalConfig.silenceDeprecations) {
    return;
  }

  let state = store();

  if (state.warned[id]) {
    return;
  }

  state.warned[id] = true;

  let link = anchor ? `${MIGRATION_GUIDE}#${anchor}` : MIGRATION_GUIDE;

  let formatted = `[ember-remodal] DEPRECATION (${id}): ${message} See ${link}`;
  state.recorded.push(formatted);
  console.warn(formatted);
}

export function _recordedWarnings() {
  return store().recorded.slice();
}

export function _resetWarnings() {
  let state = store();
  state.warned = Object.create(null);
  state.recorded = [];
}