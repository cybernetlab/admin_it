define(

['jquery', 'underscore', 'backbone',
 'admin_it/loader'],

function($, _, Backbone, Loader) {
  'use strict';

  return {
    initialize: function(options) {
      this.config = _.extend({
        api_url: '/api'
      }, options);
      this.loader = new Loader(this);
      this.loader.load(1, 2);
    },

    error: function(msg) {
      console.log('Error occured: ' + msg);
    }
  }
});
