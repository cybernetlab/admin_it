define(

['jquery', 'underscore', 'backbone',
 'admin_it/models/resource'],

function($, _, Backbone, Resource) {
  'use strict';

  var Resources = Backbone.Collection.extend({
    model: Resource
  });

  return Resources
});
