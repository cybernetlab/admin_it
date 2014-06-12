define(

['jquery', 'underscore', 'nestedtypes',
 'admin_it/collections/resources'],

function($, _, Backbone, Resources) {
  'use strict';

  var Metadata = Backbone.Model.extend({
    defaults: {
      resources: Resources
    }
  });

  return Metadata
});
