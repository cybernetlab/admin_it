define(

['jquery', 'underscore', 'underscore.string', 'backbone'],

function($, _, _str, Backbone) {
  'use strict';

  // import underscore.string
  _.mixin(_str.exports());

  var loadString = function(app, source, target) {
    // for jQuery source return inner html
    if (source instanceof $) return source.html();
    if (_.isString(source)) {
      if (/[{}<>]/.test(source)) {
        // for strings, that contains JSON or HTML symbols return string itself
        return source;
      } else {
        // for other strings assumes that string is URI
        if (source.indexOf('http') != 0 && source[0] != '/') {
          if (target == app.config.template) {
            var x = $('#' + _.map(source.split('/'), _.camelize).join('_'));
            if (x.length > 0) return x.first().html();
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

  var saveString = function(app, str, target) {
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

  function Loader(app) {
    this.app = app
  };

  Loader.prototype.load = function(source, target, type) {
    var deferred = $.Deferred();
    var self = this;
    $.when(loadString(this.app, source, target))
      .done(function(str) {
        deferred.resolve(saveString(self.app, str, target));
      })
      .fail(function() {
        deferred.reject('loading component');
      });
    return deferred;
  };

  return Loader;
});
