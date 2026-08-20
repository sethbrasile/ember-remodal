/* eslint-disable no-console */
export const MIGRATION_GUIDE =
  'https://github.com/sethbrasile/ember-remodal/blob/master/MIGRATION.md';

export const INTERNAL_CALL = '__ember-remodal-internal-call__';

let warned = Object.create(null);

// Deliberately console.warn, not Ember.deprecate: these must survive a
// production build, and must behave identically on every consumer Ember
// version this addon supports.
export function warnOnce(config, id, message, anchor) {
  let remodalConfig = config && config['ember-remodal'];

  if (remodalConfig && remodalConfig.silenceDeprecations) {
    return;
  }

  if (warned[id]) {
    return;
  }

  warned[id] = true;

  let link = anchor ? `${MIGRATION_GUIDE}#${anchor}` : MIGRATION_GUIDE;

  console.warn(`[ember-remodal] DEPRECATION (${id}): ${message} See ${link}`);
}

export function _resetWarnings() {
  warned = Object.create(null);
}