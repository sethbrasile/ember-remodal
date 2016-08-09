/* jshint node: true */
'use strict';

module.exports = {
  name: 'ember-remodal',

  included: function(app) {
    this._super.included(app);

    // In nested addons, app.bowerDirectory might not be available
    var bowerDirectory = app.bowerDirectory || 'bower_components';
    // In ember-cli < 2.7, this.import is not available, so fall back to use app.import
    var importShim = typeof this.import !== 'undefined' ? this : app;

    if (!process.env.EMBER_CLI_FASTBOOT) {
      importShim.import(bowerDirectory + '/remodal/dist/remodal.js');
    }

    importShim.import(bowerDirectory + '/remodal/dist/remodal.css');
    importShim.import(bowerDirectory + '/remodal/dist/remodal-default-theme.css');
    importShim.import('vendor/style.css');
  }
};
