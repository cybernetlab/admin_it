define(

['jquery', 'underscore', 'backbone'],

function($, _, Backbone) {
  'use strict';

  var loadString = function(app, source) {
    // for jQuery source return inner html
    if (source instanceof $) return source.html();
    if (_.isString(source)) {
      if (source =~ /[{}<>]/) {
        // for strings, that contains JSON or HTML symbols return string itself
        return source;
      } else {
        // for other strings assumes that string is URI
        if (source.indexOf('http') != 0 && source[0] != '/') {
          source = app.config.api_url + '/' + source;
        }
        return $.ajax({ url: source });
      }
    }
  };

  var saveString = function(app, str, target) {
    if (target instanceof Backbone.Model) {

    } else if (target instanceof Backbone.Collection) {
      target.reset()
    }
  }

  function Loader(app) {
    this.app = app
  };

  Loader.prototype.load = function(source, target, type) {
    var deferred = $.when(loadString(this.app, source))
    var self = this;
    deferred.done(function(str) { saveString(this.app, str, target); });
    deferred.fail(function() { self.app.error('loading component'); });
    return deferred;
  };

  return Loader;
});
