'use strict';

const EmberAddon = require('ember-cli/lib/broccoli/ember-addon');

module.exports = function(defaults) {
  let app = new EmberAddon(defaults, {
    'ember-cli-babel': {
      includePolyfill: true,
    },
    stylusOptions: {
      outputFile: 'dummy.css'
    },

    'ember-prism': {
      theme: 'okaidia',
      components: ['javascript', 'handlebars', 'markup-templating']
    }
  });

  app.import('bower_components/bootstrap/dist/css/bootstrap.css');
  app.import('bower_components/bootstrap/dist/js/bootstrap.js');

  return app.toTree();
};
