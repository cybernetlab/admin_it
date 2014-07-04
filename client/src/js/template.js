define(

['jquery', 'underscore'],

function($, _) {
  'use strict';

  function Template() {
    this.initialize.apply(this, arguments);
  }

  Template.globals = {};
  Template.helpers = {};

  return function(engine) {
    if (_.isFunction(engine)) {
      // underscore or other function-like template
      Template.registerHelper = function(name, func) {
        Template.helpers[name] = func;
      };

      Template.prototype.initialize = function(template) {
        this.engine = engine
        this.template = template;
      };

      Template.prototype.render = function(data, partials) {
        if (!_.isEmpty(partials)) {
          data.partial = function(k, d) {
            var v = partials[k];
            if (!v) return '';
            if (v instanceof Template) return v.render(d, partials);
            return v;
          };
        }
        data = _.extend({}, this.helpers, Template.globals, data);
        return this.engine(this.template, data);
      };

      Template.defaults = {
        icon: new Template('<i class="<%-iconClass(icon)"></i>'),
        button: new Template('<div class="btn<%if(type) print(" "+type%>"><%partial("icon",{icon:icon})%><%=content%></div>')
      };

    } else if (_.isObject(engine)) {

      if (engine.name == 'mustache.js') {
        // Mustache template
        Template.registerHelper = function(name, func) {
          Template.helpers[name] = function() { return function(text, render) {
            return func(render(text));
          }};
        };

        Template.prototype.initialize = function(template) {
          this.engine = engine;
          this.template = template;
          this.engine.parse(template);
        };

        Template.prototype.render = function(data, partials) {
          _.each(partials, function(v, k) {
            if (v instanceof Template) partials[k] = v.template;
          });
          data = _.extend({}, Template.helpers, Template.globals, data);
          return this.engine.render(this.template, data, partials);
        };
      } else if (_.isFunction(engine.compile) &&
                 _.isFunction(engine.registerHelper)) {
        // Handlebars template
        Template.registerHelper = function(name, func) {
          engine.registerHelper(name, func);
        };

        Template.prototype.initialize = function(template) {
          this.engine = engine;
          this.template = this.engine.compile(template);
        };

        Template.prototype.render = function(data, partials) {
          _.each(partials, function(v, k) {
            if (v instanceof Template) v = v.template;
            this.engine.registerPartial(k, v)
          });
          data = _.extend({}, Template.globals, data);
          return this.template(data);
        };
      } else {
        throw new Error('Unsupported template engine');
      }

      Template.defaults = {
        icon: new Template('<i class="{{#iconClass}}{{icon}}{{/iconClass}}"></i>'),
        button: new Template('<div class="btn{{#type}} {{.}}{{/type}}">{{>icon}}{{content}}</div>')
      };
    } else {
      throw new Error('Wrong template engine');
    }

    return Template;
  }
});
