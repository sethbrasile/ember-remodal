/* jshint node: true */
'use strict';

module.exports = {
  name: 'ember-remodal',

  included: function(app) {
    this._super.included(app);

    app.import(app.bowerDirectory + '/remodal/dist/remodal.js');
    app.import(app.bowerDirectory + '/remodal/dist/remodal.css');
    app.import(app.bowerDirectory + '/remodal/dist/remodal-default-theme.css');
    app.import('vendor/style.css');
  },

  hasContextualComponents: function() {
    var VersionChecker = require('ember-cli-version-checker');

    var checker = new VersionChecker(this);
    var dep = checker.for('ember', 'bower');

    var isBetaOrCanary = ['beta', 'canary'].filter(function(version) {
      return dep.version.indexOf(version) >= 0;
    });

    return !!(dep.satisfies('>= 2.3.0 < 3.0.0') || isBetaOrCanary.length > 0);
  },

  treeForAddonTemplates: function(tree) {
    var path = require('path');
    var baseTemplatesPath = path.join(this.root, 'addon/templates');

    if (this.hasContextualComponents()) {
      return this.treeGenerator(path.join(baseTemplatesPath, 'greater-than-2.3'));
    } else {
      return this.treeGenerator(path.join(baseTemplatesPath, 'less-than-2.3'));
    }
  }
};
