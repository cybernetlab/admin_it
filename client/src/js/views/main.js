define(

['jquery', 'underscore', 'backbone',
 'admin_it/views/base', 'admin_it/views/menu'],

function($, _, Backbone, Base, Menu) {
  'use strict';

  var appLoaded = function() {
    this.render();
    this.menu = new Menu({
      app: this.app,
      template: this.app.templates['main_menu'],
      collection: this.app.metadata.resources,
      el: this.$('.admin-it-main-menu')
    });
    this.menu.render();
    this.menu.select();
  };

  var Main = Base.extend({
    initialize: function(opts) {
      Base.prototype.initialize.apply(this, arguments);
      this.listenTo(this.app, 'loaded', appLoaded);
    },

    render: function() {
      this.$el.html(this.template.render());
      return this;
    }
  });

  return Main
});
