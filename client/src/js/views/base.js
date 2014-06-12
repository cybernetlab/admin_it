define(

['jquery', 'underscore', 'backbone'],

function($, _, Backbone) {
  'use strict';

  var Base = Backbone.View.extend({
    initialize: function(opts) {
      this.template = opts.template;
      this.app = opts.app;
    }
  });

  return Base
});
