/* jshint node: true */
'use strict';
var path = require('path');
var resolve = require('resolve');
var Funnel = require('broccoli-funnel');
var MergeTrees = require('broccoli-merge-trees');

module.exports = {
  name: require('./package').name,

  treeForVendor(tree) {
    var remodalPath = path.dirname(resolve.sync('remodal'));
    var remodalTree = new Funnel(remodalPath, {
      files: ['remodal.min.js', 'remodal.css', 'remodal-default-theme.css'],
      destDir: '/remodal/dist'
    });

    return new MergeTrees([tree, remodalTree]);
  },

  included: function(app) {
    this._super.included(app);

    // In ember-cli < 2.7, this.import is not available, so fall back to use app.import
    var importShim = typeof this.import !== 'undefined' ? this : app;

    if (!process.env.EMBER_CLI_FASTBOOT) {
      importShim.import('vendor/remodal/dist/remodal.min.js');
    }

    importShim.import('vendor/remodal/dist/remodal.css');
    importShim.import('vendor/remodal/dist/remodal-default-theme.css');
    importShim.import('vendor/style.css');

    importShim.import('vendor/ember-remodal/register-version.js');
  }
};
