define(

['jquery', 'underscore', 'backbone',
 'admin_it/loader', 'admin_it/template',
 'admin_it/collections/resources', 'admin_it/views/main'],

function($, _, Backbone, Loader, Template, Resources, MainView) {
  'use strict';

  // loads and verifies user config
  var checkConfig = function(options) {
    var config = _.extend({
      api_url: '/api',
      template_url: '',
      template: _.template,
      resources: 'resources'
    }, options);

    if (!_.isString(config.api_url)) throw new Error('Wrong api_url option');
    config.api_url = config.api_url.replace(/\/+$/, '');

    if (!_.isString(config.template_url)) throw new Error('Wrong template_url option');
    config.template_url = config.template_url.replace(/\/+$/, '');

    if (_.isEmpty(config.container)) config.container = $('body').first();
    if (_.isString(config.container)) config.container = $(config.container).first();
    return config;
  }

  var App = {
    initialize: function(options) {
      this.config = checkConfig(options);
      this.config.template = Template(this.config.template);
      this.loader = new Loader(this);
      this.resources = new Resources();

      this.loader
        .load('main_view', this.config.template)
        .done(_.bind(function(template) {
          this.mainView = new MainView({
            app: this,
            collection: this.resources,
            el: this.config.container,
            template: template
          });
        }, this));
//      this.loader.load('http://ip.jsontest.com', new Backbone.Model());
      this.loader.load(this.config.resources, this.resources);
    },

    error: function(msg) {
      console.log('Error occured: ' + msg);
    }
  }

  _.extend(App, Backbone.Events);

  return App;
});
