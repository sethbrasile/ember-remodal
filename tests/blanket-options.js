/* globals blanket, module */

const options = {
  modulePrefix: 'ember-remodal',
  filter: '//.*ember-remodal/.*/',
  antifilter: '//.*(tests|template).*/',
  loaderExclusions: [],
  enableCoverage: true,
  cliOptions: {
    reporters: ['json', 'lcov'],
    autostart: true,
    lcovOptions: {
      outputFile: 'lcov.dat'
    }
  }
};
if (typeof exports === 'undefined') {
  blanket.options(options);
} else {
  module.exports = options;
}
