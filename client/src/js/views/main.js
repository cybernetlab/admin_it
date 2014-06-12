define(

['jquery', 'underscore', 'backbone'],

function($, _, Backbone) {
  'use strict';

  var Main = Backbone.View.extend({
    initialize: function(opts) {
      // console.log(opts, this);
      this.template = opts.template;
      this.app = opts.app;
      this.listenTo(this.collection, 'reset add change', this.render);
    },

    render: function() {
      this.$el.html(this.template.render({ items: this.collection.toJSON() }));
      return this;
    }
  });

  return Main
});
