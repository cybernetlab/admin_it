requirejs.config({
  baseUrl: 'src/js',
  paths: {
    admin_it: './',
    jquery: '../../components/jquery/dist/jquery',
    underscore: '../../components/underscore/underscore',
    backbone: '../../components/backbone/backbone',
    mustache: '../../components/mustache/mustache',
    nestedtypes: '../../lib/nestedtypes'
  }
});

require(

['jquery', 'admin_it/app', 'mustache'],

function($, App, Mustache) {
  'use strict';

  App.initialize({ template: Mustache, icons: 'fa' });
});
