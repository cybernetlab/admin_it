define(

['jquery', 'underscore', 'backbone',
 'admin_it/views/base'],

function($, _, Backbone, Base) {
  'use strict';

  var Menu = Base.extend({
    events: {
      'click .admin-it-main-menu-item': 'select'
    },

    initialize: function(opts) {
      Base.prototype.initialize.apply(this, arguments);
      this.selected = null;
      this.listenTo(this.collection, 'reset add change', this.render);
    },

    render: function() {
      if (!this.el) return this;
      this.$el.html(this.template.render(
        { items: this.collection.toJSON() },
        { icon: this.app.templates.icon }
      ));
      return this;
    },

    select: function(index) {
      if (!index) index = 0;
      var model = null;
      if (index instanceof $.Event) {
        index.preventDefault();
        index = $(index.currentTarget).data('id');
      }
      if (_.isNumber(index)) {
        if (index < 0 || index >= this.collection.length) index = 0;
        model = this.collection.at(index);
      } else if (_.isString(index)) {
        model = this.collection.get(index);
      }
      if (!model) return;
      console.log(this);
      this.$('.active').removeClass('active');
      this.$('[data-id="' + model.id + '"]').addClass('active');
      this.trigger('selected', model);
    }
  });

  return Menu
});
