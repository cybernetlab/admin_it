define(

['jquery', 'underscore'],

function($, _) {
  'use strict';

  function Template() {
    this.initialize.apply(this, arguments);
  }

  return function(engine) {
    if (_.isFunction(engine)) {
      // underscore or other function-like template
      Template.prototype.initialize = function(template) {
        this.engine = engine
        this.template = template;
      };

      Template.prototype.render = function(data) {
        return this.engine(this.template, data);
      };
    } else if (_.isObject(engine)) {
      if (engine.name == 'mustache.js') {
        // Mustache template
        Template.prototype.initialize = function(template) {
          this.engine = engine;
          this.template = template;
          this.engine.parse(str);
        };

        Template.prototype.render = function(data) {
          return this.engine.render(this.template, data);
        };
      } else if (_.isFunction(engine.compile) &&
                 _.isFunction(engine.registerHelper)) {
        // Handlebars template
        Template.prototype.initialize = function(template) {
          this.engine = engine;
          this.template = this.engine.compile(template);
        };

        Template.prototype.render = function(data) {
          return this.template(data);
        };
      } else {
        throw new Error('Unsupported template engine');
      }
    } else {
      throw new Error('Wrong template engine');
    }

    return Template;
  }
});
