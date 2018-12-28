'use strict';

const EmberAddon = require('ember-cli/lib/broccoli/ember-addon');

module.exports = function(defaults) {
  let app = new EmberAddon(defaults, {
    stylusOptions: {
      outputFile: 'dummy.css'
    },

    'ember-prism': {
      theme: 'okaidia',
      components: ['javascript', 'handlebars', 'markup-templating']
    },

    'ember-bootstrap': {
      'bootstrapVersion': 3,
      'importBootstrapFont': false,
      'importBootstrapCSS': true
    }
  });

  return app.toTree();
};
