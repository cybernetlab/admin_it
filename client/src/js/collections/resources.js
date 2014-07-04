define(

['jquery', 'underscore', 'nestedtypes',
 'admin_it/models/resource'],

function($, _, Backbone, Resource) {
  'use strict';

  var Resources = Backbone.Collection.extend({
    model: Resource
  });

  return Resources;
});
