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
  }
};
