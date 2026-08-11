export default {
  plugins: ['prettier-plugin-ember-template-tag'],
  overrides: [
    {
      /**
       * Docs and HTML are checked for their own formatting, not for the
       * formatting of the samples inside them. Prettier's embedded formatter
       * does not inherit the `singleQuote` override below (that override
       * matches on the *file* name), so it rewrites every documented
       * `import … from 'ember-remodal'` to double quotes, and it hard-wraps the
       * `<template>` samples into shapes no consumer would type. A code sample
       * is prose: it says what to write, and it should read the way the code in
       * this repo reads.
       */
      files: '*.{md,html}',
      options: {
        embeddedLanguageFormatting: 'off',
      },
    },
    {
      files: '*.{js,gjs,ts,gts,mjs,mts,cjs,cts}',
      options: {
        singleQuote: true,
        templateSingleQuote: false,
      },
    },
  ],
};
