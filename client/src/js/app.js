define(

['jquery', 'underscore', 'backbone',
 'admin_it/template', 'admin_it/icons',
 'admin_it/models/metadata', 'admin_it/views/main'],

// > Usefull services for debugging: http://ip.jsontest.com

function($, _, Backbone, Template, Icons, Metadata, MainView) {
  'use strict';

  // loads and verifies user config
  var checkConfig = function(options) {
    var config = _.extend({
      api_url: '/api',
      template_url: '',
      template: _.template,
      metadata: 'metadata',
      icons: 'glyphicon'
    }, options);

    if (!_.isString(config.api_url)) throw new Error('Wrong api_url option');
    config.api_url = config.api_url.replace(/\/+$/, '');

    if (!_.isString(config.template_url)) throw new Error('Wrong template_url option');
    config.template_url = config.template_url.replace(/\/+$/, '');

    if (_.isEmpty(config.container)) config.container = $('body').first();
    if (_.isString(config.container)) config.container = $(config.container).first();
    return config;
  }

  // loads resource
  var loadResource = function(app, source, target) {
    // for jQuery source return inner html
    if (source instanceof $) return source.html();
    if (_.isString(source)) {
      if (/[{}<>]/.test(source)) {
        // for strings, that contains JSON or HTML symbols return string itself
        return source;
      } else {
        // for other strings assumes that string is jQuery selector or URI
        if (source.indexOf('http') != 0 && source[0] != '/') {
          var selector = '[data-name="' + source + '"][data-type="';
          selector += (target == app.config.template) ? 'template"]' : 'data"]';
          var jquery = $(selector);
          if (jquery.length > 0) return jquery.first().html();
          // source is relative URI - make URI absolute
          if (target == app.config.template) {
            source = app.config.template_url + '/' + source;
          } else {
            source = app.config.api_url + '/' + source;
          }
        }
        if (target instanceof Backbone.Model) {
          // if target is model set its urlRoot to source
          if (_.isEmpty(target.urlRoot) && _.isEmpty(target.collection)) {
            target.urlRoot = source;
          }
          return target.fetch();
        } else if (target instanceof Backbone.Collection) {
          // if target is collection set its url to source
          if (_.isEmpty(target.url)) target.url = source;
          return target.fetch();
        }
        return $.ajax({ url: source });
      }
    }
  };

  // creates resource after it loaded
  var createResource = function(app, str, target) {
    if (target instanceof Backbone.Model ||
        target instanceof Backbone.Collection) {
      if (_.isObject(str)) return target;
      if (!_.isString(str)) return null;
      str = str.replace(/[\t\n\r]/g, '');
      str = $.parseJSON(str);
      if (!_.isObject(str)) return null;
      (target instanceof Backbone.Model) ? target.set(str) : target.reset(str);
      return target;
    } else if (target == app.config.template) {
      return new target(str);
    }
  };

  // loads resources from html
  var loadLocals = function(deferred) {
    var app = this;
    $('[data-type][data-name]').each(function() {
      var $this = $(this);
      var data = $this.data();
      if (data.type == 'template') {
        app.templates[data.name] = new app.config.template($this.html());
      } else if (data.type == 'data' || data.type == 'collection' || data.type == 'model') {
        var Model = app.metadata.get(data.name);
        if (!Model) return;
        app.data[data.name] = new Model($.parseJSON($this.html));
      }
    });
    _.each(app.config.template.defaults, function(template, name) {
      if (!_.has(app.templates, name)) app.templates[name] = template;
    });
    deferred.resolve();
  };

  // creates main view
  var loadMainView = function(template) {
    this.mainView = new MainView({
      app: this,
      el: this.config.container,
      template: template
    });
  };

  var App = {
    /**
     * @brief starts admin application
     * @details this is the main function for start admin application
     *
     * @param  options application options
     * @return jQuery deferred object that resolves when application is
     *         completele loaded.
     */
    initialize: function(options) {
      this.config = checkConfig(options);
      this.icons = new Icons(this.config.icons);
      this.config.template = Template(this.config.template);
      this.config.template.registerHelper('iconClass', _.bind(this.icons.htmlClass, this.icons));
      this.metadata = new Metadata();
      this.data = {};
      this.templates = {};

      var app = this;
      var loadingLocals = $.Deferred();

      // load main view
      var loadingMain = this.load('main_view', this.config.template)
                            .done(_.bind(loadMainView, this));
      // load metadata
      this.load(this.config.metadata, this.metadata)
          .done(_.bind(loadLocals, this, loadingLocals));

      this.loading = $.when(loadingLocals, loadingMain)
                      .done(function() { app.trigger('loaded') });
    },

    /**
     * @brief triggers application error
     *
     * @param  msg error message
     * @return null
     */
    error: function(msg) {
      console.log('Error occured: ' + msg);
      app.trigger('error', msg);
    },

    /**
     * @brief loads application resource
     * @details resource is a template or a data
     *
     * @param source source to load resource from. Can be a jQuery object or
     *               a string that can be a jQuery selector or an url
     * @param target resource type. Can be a template class or Backbone
     *               model or collection
     *
     * @return jQuery deferred
     */
    load: function(source, target) {
      var deferred = $.Deferred();
      var app = this;
      $.when(loadResource(this, source, target))
        .done(function(str) {
          deferred.resolve(createResource(app, str, target));
        })
        .fail(function() {
          deferred.reject('while loading component');
          app.error('while loading component');
        });
      return deferred;
    }
  }

  _.extend(App, Backbone.Events);

  return App;
});
